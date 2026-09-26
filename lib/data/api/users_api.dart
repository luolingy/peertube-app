import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/actor.dart';
import '../../models/json_utils.dart';
import '../../models/misc.dart';
import '../../models/paged.dart';
import '../../models/playlist.dart';
import '../../models/video.dart';
import '../api_section.dart';

/// `/users/me/*`, authentication helpers and user administration.
mixin UsersApi on ApiSection {
  // --- current user -------------------------------------------------------

  /// `GET /users/me`.
  Future<User> getMe() async {
    return User.fromJson(jsonMap(await client.get('/users/me')));
  }

  /// `GET /users/me/video-quota-used`.
  Future<Map<String, dynamic>> getVideoQuotaUsed() async {
    return jsonMap(await client.get('/users/me/video-quota-used'));
  }

  /// `PUT /users/me`.
  Future<void> updateMe({
    String? email,
    String? currentPassword,
    String? password,
    String? displayName,
    String? description,
    String? nsfwPolicy,
    bool? p2pEnabled,
    bool? autoPlayVideo,
    bool? autoPlayNextVideo,
    bool? autoPlayNextVideoPlaylist,
    bool? videosHistoryEnabled,
    String? theme,
    bool? noInstanceConfigWarningModal,
    bool? noWelcomeModal,
    bool? noAccountSetupWarningModal,
    Map<String, dynamic>? notificationSettings,
  }) async {
    await client.put(
      '/users/me',
      data: <String, dynamic>{
        'email': email,
        'currentPassword': currentPassword,
        'password': password,
        'displayName': displayName,
        'description': description,
        'nsfwPolicy': nsfwPolicy,
        'p2pEnabled': p2pEnabled,
        'autoPlayVideo': autoPlayVideo,
        'autoPlayNextVideo': autoPlayNextVideo,
        'autoPlayNextVideoPlaylist': autoPlayNextVideoPlaylist,
        'videosHistoryEnabled': videosHistoryEnabled,
        'theme': theme,
        'noInstanceConfigWarningModal': noInstanceConfigWarningModal,
        'noWelcomeModal': noWelcomeModal,
        'noAccountSetupWarningModal': noAccountSetupWarningModal,
        'notificationSettings': notificationSettings,
      },
    );
  }

  /// `DELETE /users/me`.
  Future<void> deleteMe(String password) async {
    await client.delete('/users/me', data: <String, dynamic>{'password': password});
  }

  /// `POST /users/me/avatar/pick`.
  Future<void> uploadMyAvatar({
    String? path,
    Uint8List? bytes,
    String filename = 'avatar.png',
  }) async {
    final form = FormData.fromMap(<String, dynamic>{
      'avatarfile': await client.multipartFile(path: path, bytes: bytes, filename: filename),
    });
    await client.upload('/users/me/avatar/pick', formData: form);
  }

  /// `DELETE /users/me/avatar`.
  Future<void> deleteMyAvatar() async {
    await client.delete('/users/me/avatar');
  }

  /// `POST /users/me/new-feature-info/read`.
  Future<void> markNewFeatureInfoAsRead() async {
    await client.post('/users/me/new-feature-info/read');
  }

  // --- my content ---------------------------------------------------------

  /// `GET /users/me/videos`.
  Future<PagedResult<Video>> listMyVideos({
    int start = 0,
    int count = 20,
    String? sort,
    String? search,
    Iterable<int>? stateOneOf,
    bool? isLive,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/users/me/videos',
      cancelToken: cancelToken,
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'search': search,
        'stateOneOf': csv(stateOneOf),
        'isLive': isLive,
      },
    );
    return PagedResult<Video>.fromJson(data, Video.fromJson);
  }

  /// `GET /users/me/videos/:videoId/rating`.
  Future<String> getMyRating(String videoId) async {
    final data = jsonMap(await client.get('/users/me/videos/$videoId/rating'));
    return jsonString(data['rating'], 'none');
  }

  /// `GET /users/me/videos/comments`.
  Future<PagedResult<Map<String, dynamic>>> listCommentsOnMyVideos({
    int start = 0,
    int count = 20,
    String? sort,
  }) async {
    final data = await client.get(
      '/users/me/videos/comments',
      query: <String, dynamic>{'start': start, 'count': count, 'sort': sort},
    );
    return PagedResult<Map<String, dynamic>>.fromJson(data, (Map<String, dynamic> e) => e);
  }

  /// `GET /users/me/videos/imports`.
  Future<PagedResult<VideoImport>> listMyVideoImports({
    int start = 0,
    int count = 20,
    String? sort,
    String? state,
  }) async {
    final data = await client.get(
      '/users/me/videos/imports',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'videoImportState': state,
      },
    );
    return PagedResult<VideoImport>.fromJson(data, VideoImport.fromJson);
  }

  /// `GET /users/me/history/videos`.
  Future<PagedResult<Video>> listMyHistory({
    int start = 0,
    int count = 20,
    String? sort,
    String? search,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/users/me/history/videos',
      cancelToken: cancelToken,
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'search': search,
      },
    );
    return PagedResult<Video>.fromJson(data, Video.fromJson);
  }

  /// `DELETE /users/me/history/videos/:videoId`.
  Future<void> deleteHistoryEntry(String videoId) async {
    await client.delete('/users/me/history/videos/$videoId');
  }

  /// `POST /users/me/history/videos/remove`.
  Future<void> removeHistoryEntries({
    String? beforeDate,
    Iterable<int>? videoIds,
  }) async {
    await client.post(
      '/users/me/history/videos/remove',
      data: <String, dynamic>{
        'beforeDate': beforeDate,
        'videoIds': videoIds?.toList(growable: false),
      },
    );
  }

  /// `GET /users/me/subscriptions`.
  Future<PagedResult<VideoChannel>> listMySubscriptions({
    int start = 0,
    int count = 20,
    String? sort,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/users/me/subscriptions',
      cancelToken: cancelToken,
      query: <String, dynamic>{'start': start, 'count': count, 'sort': sort},
    );
    return PagedResult<VideoChannel>.fromJson(data, VideoChannel.fromJson);
  }

  /// `GET /users/me/subscriptions/videos` — the subscription feed.
  Future<PagedResult<Video>> listSubscriptionVideos({
    int start = 0,
    int count = 20,
    String? sort,
    bool? nsfw,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/users/me/subscriptions/videos',
      cancelToken: cancelToken,
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'nsfw': nsfw == null ? 'both' : (nsfw ? 'true' : 'false'),
      },
    );
    return PagedResult<Video>.fromJson(data, Video.fromJson);
  }

  /// `GET /users/me/video-playlists`.
  Future<PagedResult<VideoPlaylist>> listMyPlaylists({
    int start = 0,
    int count = 20,
    String? sort,
    int? playlistType,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/users/me/video-playlists',
      cancelToken: cancelToken,
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'playlistType': playlistType,
      },
    );
    return PagedResult<VideoPlaylist>.fromJson(data, VideoPlaylist.fromJson);
  }

  /// `GET /users/me/video-playlists/videos-exist`.
  Future<List<PlaylistVideoExistence>> playlistsContainingVideo(List<int> videoIds) async {
    if (videoIds.isEmpty) return const <PlaylistVideoExistence>[];
    final data = await client.get(
      '/users/me/video-playlists/videos-exist',
      query: <String, dynamic>{'videoIds': csv(videoIds)},
    );
    if (data is! List) return const <PlaylistVideoExistence>[];
    return data
        .map((dynamic e) => PlaylistVideoExistence.fromJson(jsonMap(e)))
        .toList(growable: false);
  }

  // --- notifications ------------------------------------------------------

  /// `GET /users/me/notifications`.
  Future<PagedResult<UserNotification>> listNotifications({
    int start = 0,
    int count = 20,
    String? sort,
    bool? unread,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/users/me/notifications',
      cancelToken: cancelToken,
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'unread': unread,
      },
    );
    return PagedResult<UserNotification>.fromJson(data, UserNotification.fromJson);
  }

  /// `POST /users/me/notifications/read`.
  Future<void> markNotificationsAsRead(List<int> ids) async {
    if (ids.isEmpty) return;
    await client.post('/users/me/notifications/read', data: <String, dynamic>{'ids': ids});
  }

  /// `POST /users/me/notifications/read-all`.
  Future<void> markAllNotificationsAsRead() async {
    await client.post('/users/me/notifications/read-all');
  }

  /// `PUT /users/me/notification-settings`.
  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    await client.put('/users/me/notification-settings', data: settings);
  }

  // --- abuses -------------------------------------------------------------

  /// `GET /users/me/abuses`.
  Future<PagedResult<Abuse>> listMyAbuses({
    int start = 0,
    int count = 20,
    String? sort,
    int? state,
  }) async {
    final data = await client.get(
      '/users/me/abuses',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'state': state,
      },
    );
    return PagedResult<Abuse>.fromJson(data, Abuse.fromJson);
  }

  // --- token sessions -----------------------------------------------------

  /// `GET /users/:userId/token-sessions`.
  Future<PagedResult<Map<String, dynamic>>> listTokenSessions(
    int userId, {
    int start = 0,
    int count = 20,
  }) async {
    final data = await client.get(
      '/users/$userId/token-sessions',
      query: <String, dynamic>{'start': start, 'count': count},
    );
    return PagedResult<Map<String, dynamic>>.fromJson(data, (Map<String, dynamic> e) => e);
  }

  /// `POST /users/:userId/token-sessions/:tokenSessionId/revoke`.
  Future<void> revokeTokenSession(int userId, int tokenSessionId) async {
    await client.post('/users/$userId/token-sessions/$tokenSessionId/revoke');
  }

  /// `GET /users/token/scoped-tokens`.
  Future<Map<String, dynamic>> getScopedTokens() async {
    return jsonMap(await client.get('/users/token/scoped-tokens'));
  }

  /// `POST /users/token/scoped-tokens`.
  Future<Map<String, dynamic>> renewScopedTokens() async {
    return jsonMap(await client.post('/users/token/scoped-tokens'));
  }

  // --- two factor ---------------------------------------------------------

  /// `POST /users/:id/two-factor/request`.
  Future<Map<String, dynamic>> requestTwoFactor(int userId, String password) async {
    final data = jsonMap(
      await client.post(
        '/users/$userId/two-factor/request',
        data: <String, dynamic>{'password': password},
      ),
    );
    return jsonMap(data['otpRequest']);
  }

  /// `POST /users/:id/two-factor/confirm-request`.
  Future<void> confirmTwoFactor(int userId, String requestToken, String otpToken) async {
    await client.post(
      '/users/$userId/two-factor/confirm-request',
      data: <String, dynamic>{'requestToken': requestToken, 'otpToken': otpToken},
    );
  }

  /// `POST /users/:id/two-factor/disable`.
  Future<void> disableTwoFactor(int userId, String password) async {
    await client.post(
      '/users/$userId/two-factor/disable',
      data: <String, dynamic>{'password': password},
    );
  }

  // --- registration & password recovery -----------------------------------

  /// `POST /users/register`.
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    String? displayName,
    String? channelName,
    String? channelDisplayName,
    String? channelDescription,
  }) async {
    final body = <String, dynamic>{
      'username': username,
      'password': password,
      'email': email,
      'displayName': displayName,
    };
    if (channelName != null && channelName.isNotEmpty) {
      body['channel'] = <String, dynamic>{
        'name': channelName,
        'displayName': channelDisplayName ?? channelName,
        'description': channelDescription,
      };
    }

    final data = await client.post('/users/register', data: body, authenticated: false);
    return jsonMap(jsonMap(data)['user']);
  }

  /// `POST /users/registrations/ask-send-verify-email`.
  Future<void> askSendVerifyEmail(String email) async {
    await client.post(
      '/users/registrations/ask-send-verify-email',
      data: <String, dynamic>{'email': email},
      authenticated: false,
    );
  }

  /// `POST /users/ask-reset-password`.
  Future<void> askResetPassword(String email) async {
    await client.post(
      '/users/ask-reset-password',
      data: <String, dynamic>{'email': email},
      authenticated: false,
    );
  }

  /// `POST /users/:id/reset-password`.
  Future<void> resetPassword({
    required int userId,
    required String password,
    required String resetPasswordToken,
  }) async {
    await client.post(
      '/users/$userId/reset-password',
      data: <String, dynamic>{
        'password': password,
        'resetPasswordToken': resetPasswordToken,
      },
      authenticated: false,
    );
  }

  // --- administration -----------------------------------------------------

  /// `GET /users` (admin).
  Future<PagedResult<User>> listUsers({
    int start = 0,
    int count = 20,
    String? sort,
    String? search,
    int? blocked,
  }) async {
    final data = await client.get(
      '/users',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'search': search,
        'blocked': blocked,
      },
    );
    return PagedResult<User>.fromJson(data, User.fromJson);
  }

  /// `GET /users/:id`.
  Future<User> getUser(int id) async {
    return User.fromJson(jsonMap(await client.get('/users/$id')));
  }

  /// `POST /users` — creates a user (admin).
  Future<User> createUser({
    required String username,
    required String password,
    required String email,
    required int role,
    String? displayName,
    String? channelName,
    int? videoQuota,
    int? videoQuotaDaily,
  }) async {
    final data = await client.post(
      '/users',
      data: <String, dynamic>{
        'username': username,
        'password': password,
        'email': email,
        'role': role,
        'displayName': displayName,
        'channelName': channelName,
        'videoQuota': videoQuota,
        'videoQuotaDaily': videoQuotaDaily,
      },
    );
    return User.fromJson(jsonMap(jsonMap(data)['user']));
  }

  /// `PUT /users/:id` (admin).
  Future<void> updateUser(
    int id, {
    String? email,
    String? password,
    int? role,
    String? displayName,
    String? description,
    int? videoQuota,
    int? videoQuotaDaily,
    String? theme,
  }) async {
    await client.put(
      '/users/$id',
      data: <String, dynamic>{
        'email': email,
        'password': password,
        'role': role,
        'displayName': displayName,
        'description': description,
        'videoQuota': videoQuota,
        'videoQuotaDaily': videoQuotaDaily,
        'theme': theme,
      },
    );
  }

  /// `DELETE /users/:id` (admin).
  Future<void> deleteUser(int id) async {
    await client.delete('/users/$id');
  }

  /// `POST /users/:id/block` (admin).
  Future<void> blockUser(int id, String reason) async {
    await client.post('/users/$id/block', data: <String, dynamic>{'reason': reason});
  }

  /// `POST /users/:id/unblock` (admin).
  Future<void> unblockUser(int id) async {
    await client.post('/users/$id/unblock');
  }

  /// `POST /users/:id/reset-password` (admin).
  Future<void> adminResetPassword(int id, String password) async {
    await client.post('/users/$id/reset-password', data: <String, dynamic>{'password': password});
  }

  /// `GET /users/registrations` (admin).
  Future<PagedResult<Map<String, dynamic>>> listRegistrations({
    int start = 0,
    int count = 20,
    String? sort,
    String? search,
  }) async {
    final data = await client.get(
      '/users/registrations',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'search': search,
      },
    );
    return PagedResult<Map<String, dynamic>>.fromJson(data, (Map<String, dynamic> e) => e);
  }

  /// `POST /users/registrations/:registrationId/accept` (admin).
  Future<void> acceptRegistration(int registrationId) async {
    await client.post('/users/registrations/$registrationId/accept');
  }

  /// `POST /users/registrations/:registrationId/reject` (admin).
  Future<void> rejectRegistration(int registrationId, {String? moderationComment}) async {
    await client.post(
      '/users/registrations/$registrationId/reject',
      data: <String, dynamic>{'moderationComment': moderationComment},
    );
  }

  /// `POST /users/:id/verify-email` (admin).
  Future<void> verifyUserEmail(int id) async {
    await client.post('/users/$id/verify-email');
  }

  // --- exports / imports --------------------------------------------------

  /// `GET /users/:userId/exports`.
  Future<PagedResult<Map<String, dynamic>>> listUserExports(
    int userId, {
    int start = 0,
    int count = 20,
  }) async {
    final data = await client.get(
      '/users/$userId/exports',
      query: <String, dynamic>{'start': start, 'count': count},
    );
    return PagedResult<Map<String, dynamic>>.fromJson(data, (Map<String, dynamic> e) => e);
  }

  /// `POST /users/:userId/exports/request`.
  Future<void> requestUserExport(int userId) async {
    await client.post('/users/$userId/exports/request');
  }

  /// `DELETE /users/:userId/exports/:id`.
  Future<void> deleteUserExport(int userId, int id) async {
    await client.delete('/users/$userId/exports/$id');
  }

  /// `GET /users/:userId/imports/latest`.
  Future<Map<String, dynamic>> getLatestUserImport(int userId) async {
    return jsonMap(await client.get('/users/$userId/imports/latest'));
  }
}
