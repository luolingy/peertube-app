import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import '../core/app_exception.dart';
import '../models/json_utils.dart';
import 'local_store.dart';

/// Low level HTTP access to a PeerTube instance.
///
/// Handles the OAuth2 password/refresh-token flow, transparently refreshes an
/// expired access token and maps PeerTube's RFC7807 problem documents to
/// [ApiException].
class ApiClient {
  ApiClient({required this.store}) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 120),
        headers: <String, dynamic>{
          'Accept': 'application/json',
          'User-Agent': AppConfig.userAgent,
        },
        validateStatus: (int? status) => status != null && status < 400,
        responseType: ResponseType.json,
      ),
    );
    _applyBaseUrl();
  }

  final LocalStore store;
  late final Dio _dio;

  Dio get dio => _dio;

  /// Invoked when the session cannot be restored (refresh token rejected).
  VoidCallback? onSessionExpired;

  String get baseUrl => store.baseUrl;

  /// Turns a relative PeerTube path (`/lazy-static/...`) into an absolute URL.
  String absoluteUrl(String pathOrUrl) {
    if (pathOrUrl.isEmpty) return pathOrUrl;
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    return '$baseUrl$pathOrUrl';
  }

  /// Absolute URL of a resource on the instance, e.g. `/videos/watch/:uuid`.
  String webUrl(String path) => absoluteUrl(path);

  void _applyBaseUrl() {
    _dio.options.baseUrl = '$baseUrl${AppConfig.apiPrefix}';
  }

  /// Re-points the client at another instance.
  Future<void> setBaseUrl(String url) async {
    store.baseUrl = url;
    _applyBaseUrl();
  }

  // -------------------------------------------------------------------------
  // Verb helpers
  // -------------------------------------------------------------------------

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) {
    return _request(
      'GET',
      path,
      query: query,
      cancelToken: cancelToken,
      authenticated: authenticated,
    );
  }

  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    String? contentType,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) {
    return _request(
      'POST',
      path,
      data: data,
      query: query,
      contentType: contentType,
      cancelToken: cancelToken,
      authenticated: authenticated,
    );
  }

  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    String? contentType,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) {
    return _request(
      'PUT',
      path,
      data: data,
      query: query,
      contentType: contentType,
      cancelToken: cancelToken,
      authenticated: authenticated,
    );
  }

  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    bool authenticated = true,
  }) {
    return _request(
      'DELETE',
      path,
      data: data,
      query: query,
      cancelToken: cancelToken,
      authenticated: authenticated,
    );
  }

  /// Multipart upload with progress reporting.
  Future<dynamic> upload(
    String path, {
    required FormData formData,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    return _request(
      'POST',
      path,
      data: formData,
      contentType: 'multipart/form-data',
      cancelToken: cancelToken,
      onSendProgress: onProgress,
    );
  }

  /// Builds a [MultipartFile] from a picked file, working on both the IO and
  /// the web platform.
  Future<MultipartFile> multipartFile({
    String? path,
    List<int>? bytes,
    required String filename,
    String? contentType,
  }) async {
    if (bytes != null) {
      return MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: contentType == null ? null : DioMediaType.parse(contentType),
      );
    }
    if (path != null && path.isNotEmpty) {
      return MultipartFile.fromFile(
        path,
        filename: filename,
        contentType: contentType == null ? null : DioMediaType.parse(contentType),
      );
    }
    throw ApiException(message: '无法读取所选文件');
  }

  // -------------------------------------------------------------------------
  // Request pipeline
  // -------------------------------------------------------------------------

  Future<void>? _refreshing;

  Future<dynamic> _request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    String? contentType,
    CancelToken? cancelToken,
    bool authenticated = true,
    bool allowRefresh = true,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    // Proactively refresh a token that is about to expire.
    if (authenticated && store.isLoggedIn && store.isAccessTokenExpired && allowRefresh) {
      await _ensureRefreshed();
    }

    try {
      return await _send(
        method,
        path,
        data: data,
        query: query,
        contentType: contentType,
        cancelToken: cancelToken,
        authenticated: authenticated,
        onSendProgress: onSendProgress,
      );
    } on ApiException catch (error) {
      final canRetry = error.isUnauthorized &&
          authenticated &&
          allowRefresh &&
          store.hasRefreshToken &&
          !path.contains('/users/token');
      if (!canRetry) rethrow;

      await _ensureRefreshed();
      return _send(
        method,
        path,
        data: data,
        query: query,
        contentType: contentType,
        cancelToken: cancelToken,
        authenticated: authenticated,
        onSendProgress: onSendProgress,
      );
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    String? contentType,
    CancelToken? cancelToken,
    required bool authenticated,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final headers = <String, dynamic>{};
    if (authenticated) {
      final token = store.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: _cleanQuery(query),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: Options(
          method: method,
          headers: headers,
          contentType: contentType,
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw _mapDioError(error);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: '$error');
    }
  }

  /// Removes `null` values so they are not serialised into the query string.
  Map<String, dynamic>? _cleanQuery(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return null;
    final result = <String, dynamic>{};
    query.forEach((key, dynamic value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      if (value is Iterable && value.isEmpty) return;
      result[key] = value is Iterable ? value.toList() : value;
    });
    return result.isEmpty ? null : result;
  }

  ApiException _mapDioError(DioException error) {
    final response = error.response;

    if (response != null) {
      final body = response.data;
      final map = jsonMap(body);

      var message = jsonStringOrNull(map['detail']) ?? jsonStringOrNull(map['title']);
      message ??= _extractValidationMessage(map);
      message ??= jsonStringOrNull(map['error']);
      message ??= jsonStringOrNull(map['error_description']);
      message ??= _httpStatusMessage(response.statusCode);

      var code = jsonStringOrNull(map['code']);
      if (code == null || code.isEmpty) {
        code = jsonStringOrNull(map['error']);
      }

      // PeerTube signals a missing two factor code through a response header.
      if (response.statusCode == 401 &&
          response.headers.value('x-peertube-otp') != null) {
        code = 'missing_two_factor';
      }

      return ApiException(
        message: message,
        statusCode: response.statusCode,
        type: code,
        details: body,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(message: '连接超时，请检查网络后重试');
      case DioExceptionType.connectionError:
        return ApiException(message: '无法连接到 $baseUrl，请检查实例地址或网络');
      case DioExceptionType.cancel:
        return ApiException(message: '请求已取消');
      case DioExceptionType.badCertificate:
        return ApiException(message: '实例的 HTTPS 证书无效');
      default:
        return ApiException(message: error.message ?? '网络请求失败');
    }
  }

  String? _extractValidationMessage(Map<String, dynamic> map) {
    final errors = map['errors'];
    if (errors is List && errors.isNotEmpty) {
      final messages = <String>[];
      for (final entry in errors) {
        final msg = jsonStringOrNull(jsonMap(entry)['msg']);
        if (msg != null && msg.isNotEmpty) messages.add(msg);
      }
      if (messages.isNotEmpty) return messages.join('\n');
    }
    return null;
  }

  String _httpStatusMessage(int? status) {
    switch (status) {
      case 400:
        return '请求参数有误 (400)';
      case 401:
        return '需要登录或登录已过期 (401)';
      case 403:
        return '没有权限执行该操作 (403)';
      case 404:
        return '请求的资源不存在 (404)';
      case 409:
        return '操作冲突 (409)';
      case 413:
        return '文件过大 (413)';
      case 429:
        return '操作过于频繁，请稍后再试 (429)';
      case 500:
        return '服务器内部错误 (500)';
      case 503:
        return '服务暂时不可用 (503)';
      default:
        return '请求失败 (${status ?? 'unknown'})';
    }
  }

  // -------------------------------------------------------------------------
  // OAuth2
  // -------------------------------------------------------------------------

  /// Fetches (and caches) the instance's local OAuth client credentials.
  Future<void> ensureOAuthClient() async {
    if ((store.oauthClientId ?? '').isNotEmpty && (store.oauthClientSecret ?? '').isNotEmpty) {
      return;
    }

    final data = jsonMap(await get('/oauth-clients/local', authenticated: false));
    final clientId = jsonStringOrNull(data['client_id']);
    final clientSecret = jsonStringOrNull(data['client_secret']);

    if (clientId == null || clientSecret == null) {
      throw ApiException(message: '实例未返回有效的 OAuth 客户端信息');
    }
    await store.saveOAuthClient(clientId: clientId, clientSecret: clientSecret);
  }

  /// Logs in with the resource owner password grant.
  ///
  /// [otp] carries the two factor code when the account has 2FA enabled.
  Future<void> login({
    required String username,
    required String password,
    String? otp,
  }) async {
    await ensureOAuthClient();

    final body = <String, dynamic>{
      'grant_type': 'password',
      'username': username,
      'password': password,
      'client_id': store.oauthClientId,
      'client_secret': store.oauthClientSecret,
      'response_type': 'code',
    };
    if (otp != null && otp.isNotEmpty) {
      body['otp'] = otp;
    }

    await _storeTokenResponse(
      await post(
        '/users/token',
        data: body,
        contentType: Headers.formUrlEncodedContentType,
        authenticated: false,
      ),
    );
  }

  Future<void> _storeTokenResponse(dynamic response) async {
    final data = jsonMap(response);
    final accessToken = jsonStringOrNull(data['access_token']);
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(message: '登录失败：服务器未返回访问令牌');
    }

    await store.saveTokens(
      accessToken: accessToken,
      refreshToken: jsonStringOrNull(data['refresh_token']),
      expiresInSeconds: jsonIntOrNull(data['expires_in']),
      refreshExpiresInSeconds: jsonIntOrNull(data['refresh_token_expires_in']),
    );
  }

  Future<void> _ensureRefreshed() {
    final pending = _refreshing;
    if (pending != null) return pending;

    final future = _refresh().whenComplete(() => _refreshing = null);
    _refreshing = future;
    return future;
  }

  Future<void> _refresh() async {
    final refreshToken = store.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await store.clearTokens();
      onSessionExpired?.call();
      return;
    }

    try {
      await ensureOAuthClient();
      final response = await post(
        '/users/token',
        data: <String, dynamic>{
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': store.oauthClientId,
          'client_secret': store.oauthClientSecret,
        },
        contentType: Headers.formUrlEncodedContentType,
        authenticated: false,
      );
      await _storeTokenResponse(response);
    } on ApiException {
      await store.clearTokens();
      onSessionExpired?.call();
      rethrow;
    }
  }

  /// Revokes the current token on the server, then clears it locally.
  Future<void> logout() async {
    if (store.isLoggedIn) {
      try {
        await post('/users/revoke-token', authenticated: true);
      } on ApiException {
        // Logging out locally is always good enough.
      }
    }
    await store.clearTokens();
  }

  /// `GET /users/me` style call used to validate the session.
  Future<dynamic> getMe() => get('/users/me');
}
