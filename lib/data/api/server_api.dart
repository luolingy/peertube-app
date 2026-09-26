import 'package:dio/dio.dart';

import '../../models/json_utils.dart';
import '../../models/misc.dart';
import '../../models/paged.dart';
import '../../models/server_config.dart';
import '../api_section.dart';

/// Instance level endpoints: config, stats, jobs, plugins, moderation.
mixin ServerApi on ApiSection {
  /// `GET /config`.
  Future<ServerConfig> getConfig() async {
    return ServerConfig.fromJson(jsonMap(await client.get('/config', authenticated: false)));
  }

  /// `GET /config/about`.
  Future<Map<String, dynamic>> getAbout() async {
    return jsonMap(await client.get('/config/about', authenticated: false));
  }

  /// `GET /server/stats`.
  Future<ServerStats> getServerStats() async {
    return ServerStats.fromJson(jsonMap(await client.get('/server/stats', authenticated: false)));
  }

  /// `GET /overviews/videos` — randomised discovery samples.
  Future<Map<String, dynamic>> getVideosOverview({int page = 1}) async {
    return jsonMap(await client.get('/overviews/videos', query: <String, dynamic>{'page': page}));
  }

  /// `POST /server/contact`.
  Future<void> contactAdministrator({
    required String fromEmail,
    required String subject,
    required String body,
  }) async {
    await client.post(
      '/server/contact',
      data: <String, dynamic>{'fromEmail': fromEmail, 'subject': subject, 'body': body},
      authenticated: false,
    );
  }

  // --- jobs ---------------------------------------------------------------

  /// `GET /jobs/:state`.
  Future<PagedResult<Job>> listJobs({
    String state = 'active',
    int start = 0,
    int count = 20,
    String? sort,
    String? jobType,
  }) async {
    final data = await client.get(
      '/jobs/$state',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'jobType': jobType,
      },
    );
    return PagedResult<Job>.fromJson(data, Job.fromJson);
  }

  /// `POST /jobs/:jobType/:jobId/cancel`.
  Future<void> cancelJob(String jobType, String jobId) async {
    await client.post('/jobs/$jobType/$jobId/cancel');
  }

  /// `POST /jobs/pause`.
  Future<void> pauseJobs() async {
    await client.post('/jobs/pause');
  }

  /// `POST /jobs/resume`.
  Future<void> resumeJobs() async {
    await client.post('/jobs/resume');
  }

  // --- plugins ------------------------------------------------------------

  /// `GET /plugins`.
  Future<PagedResult<Plugin>> listPlugins({
    int start = 0,
    int count = 50,
    String? sort,
    String? pluginType,
  }) async {
    final data = await client.get(
      '/plugins',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'pluginType': pluginType,
      },
    );
    return PagedResult<Plugin>.fromJson(data, Plugin.fromJson);
  }

  /// `GET /plugins/available`.
  Future<PagedResult<Map<String, dynamic>>> listAvailablePlugins({
    int start = 0,
    int count = 20,
    String? search,
    String? sort,
    String? pluginType,
  }) async {
    final data = await client.get(
      '/plugins/available',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'search': search,
        'sort': sort,
        'pluginType': pluginType,
      },
    );
    return PagedResult<Map<String, dynamic>>.fromJson(data, (Map<String, dynamic> e) => e);
  }

  /// `GET /plugins/:npmName`.
  Future<Map<String, dynamic>> getPlugin(String npmName) async {
    return jsonMap(await client.get('/plugins/$npmName'));
  }

  /// `POST /plugins/install`.
  Future<void> installPlugin(String npmName, {bool forceLatest = false}) async {
    await client.post(
      '/plugins/install',
      data: <String, dynamic>{'npmName': npmName, 'forceLatest': forceLatest},
    );
  }

  /// `POST /plugins/update`.
  Future<void> updatePlugin(String npmName, {bool forceLatest = false}) async {
    await client.post(
      '/plugins/update',
      data: <String, dynamic>{'npmName': npmName, 'forceLatest': forceLatest},
    );
  }

  /// `POST /plugins/uninstall`.
  Future<void> uninstallPlugin(String npmName) async {
    await client.post('/plugins/uninstall', data: <String, dynamic>{'npmName': npmName});
  }

  /// `PUT /plugins/:npmName/settings`.
  Future<void> updatePluginSettings(String npmName, Map<String, dynamic> settings) async {
    await client.put('/plugins/$npmName/settings', data: settings);
  }

  // --- logs ---------------------------------------------------------------

  /// `GET /server/logs`.
  Future<List<LogLine>> getLogs({String? startDate, String? endDate, String? level}) async {
    final data = await client.get(
      '/server/logs',
      query: <String, dynamic>{
        'startDate': startDate,
        'endDate': endDate,
        'level': level,
      },
    );
    if (data is! List) return const <LogLine>[];
    return data.map((dynamic e) => LogLine.fromJson(jsonMap(e))).toList(growable: false);
  }

  /// `GET /server/audit-logs`.
  Future<PagedResult<Map<String, dynamic>>> getAuditLogs({
    int start = 0,
    int count = 20,
    String? sort,
    String? search,
  }) async {
    final data = await client.get(
      '/server/audit-logs',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'search': search,
      },
    );
    return PagedResult<Map<String, dynamic>>.fromJson(data, (Map<String, dynamic> e) => e);
  }

  /// `POST /server/logs/client` — reports a client side error.
  Future<void> reportClientLog(String message, {String? url, String? level}) async {
    await client.post(
      '/server/logs/client',
      data: <String, dynamic>{'message': message, 'url': url, 'level': level ?? 'error'},
      authenticated: false,
    );
  }

  // --- moderation ---------------------------------------------------------

  /// `GET /abuses` (moderator).
  Future<PagedResult<Abuse>> listAbuses({
    int start = 0,
    int count = 20,
    String? sort,
    int? state,
    String? search,
  }) async {
    final data = await client.get(
      '/abuses',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'state': state,
        'search': search,
      },
    );
    return PagedResult<Abuse>.fromJson(data, Abuse.fromJson);
  }

  /// `GET /abuses/:id`.
  Future<Abuse> getAbuse(int id) async {
    return Abuse.fromJson(jsonMap(await client.get('/abuses/$id')));
  }

  /// `PUT /abuses/:id` (moderator).
  Future<void> updateAbuse(
    int id, {
    required int state,
    String? moderationComment,
  }) async {
    await client.put(
      '/abuses/$id',
      data: <String, dynamic>{'state': state, 'moderationComment': moderationComment},
    );
  }

  /// `DELETE /abuses/:id` (moderator).
  Future<void> deleteAbuse(int id) async {
    await client.delete('/abuses/$id');
  }

  /// `POST /abuses` — reports a video or an account.
  Future<void> reportAbuse({
    required String reason,
    required String message,
    String? videoId,
    int? videoStartAt,
    int? videoEndAt,
    int? accountId,
    int? commentId,
    List<String>? predefinedReasons,
  }) async {
    await client.post(
      '/abuses',
      data: <String, dynamic>{
        'reason': reason,
        'message': message,
        'predefinedReasons': predefinedReasons,
        if (videoId != null)
          'video': <String, dynamic>{
            'id': videoId,
            'startAt': videoStartAt,
            'endAt': videoEndAt,
          },
        if (accountId != null) 'account': <String, dynamic>{'id': accountId},
        if (commentId != null) 'comment': <String, dynamic>{'id': commentId},
      },
    );
  }

  /// `GET /server/blocklist`.
  Future<PagedResult<Map<String, dynamic>>> listServerBlocklist({
    int start = 0,
    int count = 20,
    String? sort,
    String? search,
  }) async {
    final data = await client.get(
      '/server/blocklist/servers',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'search': search,
      },
    );
    return PagedResult<Map<String, dynamic>>.fromJson(data, (Map<String, dynamic> e) => e);
  }

  /// `POST /server/blocklist/servers`.
  Future<void> blockServer(String host) async {
    await client.post('/server/blocklist/servers', data: <String, dynamic>{'host': host});
  }

  /// `DELETE /server/blocklist/servers/:host`.
  Future<void> unblockServer(String host) async {
    await client.delete('/server/blocklist/servers/$host');
  }

  /// `GET /users/me/blocklist/accounts`.
  Future<PagedResult<Map<String, dynamic>>> listMyBlockedAccounts({
    int start = 0,
    int count = 20,
    String? sort,
    String? search,
  }) async {
    final data = await client.get(
      '/users/me/blocklist/accounts',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'search': search,
      },
    );
    return PagedResult<Map<String, dynamic>>.fromJson(data, (Map<String, dynamic> e) => e);
  }

  /// `POST /users/me/blocklist/accounts`.
  Future<void> blockAccount(String accountName) async {
    await client.post(
      '/users/me/blocklist/accounts',
      data: <String, dynamic>{'accountName': accountName},
    );
  }

  /// `DELETE /users/me/blocklist/accounts/:accountName`.
  Future<void> unblockAccount(String accountName) async {
    await client.delete('/users/me/blocklist/accounts/$accountName');
  }

  /// `GET /users/me/blocklist/servers`.
  Future<PagedResult<Map<String, dynamic>>> listMyBlockedServers({
    int start = 0,
    int count = 20,
    String? sort,
    String? search,
  }) async {
    final data = await client.get(
      '/users/me/blocklist/servers',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'search': search,
      },
    );
    return PagedResult<Map<String, dynamic>>.fromJson(data, (Map<String, dynamic> e) => e);
  }

  /// `POST /users/me/blocklist/servers`.
  Future<void> blockServerForMe(String host) async {
    await client.post('/users/me/blocklist/servers', data: <String, dynamic>{'host': host});
  }

  /// `DELETE /users/me/blocklist/servers/:host`.
  Future<void> unblockServerForMe(String host) async {
    await client.delete('/users/me/blocklist/servers/$host');
  }

  // --- instance federation ------------------------------------------------

  /// `GET /server/following`.
  Future<PagedResult<ActorFollow>> listInstanceFollowing({
    int start = 0,
    int count = 20,
    String? sort,
    String? search,
  }) async {
    final data = await client.get(
      '/server/following',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'search': search,
      },
    );
    return PagedResult<ActorFollow>.fromJson(data, ActorFollow.fromJson);
  }

  /// `GET /server/followers`.
  Future<PagedResult<ActorFollow>> listInstanceFollowers({
    int start = 0,
    int count = 20,
    String? sort,
    String? search,
  }) async {
    final data = await client.get(
      '/server/followers',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'search': search,
      },
    );
    return PagedResult<ActorFollow>.fromJson(data, ActorFollow.fromJson);
  }

  /// `POST /server/following`.
  Future<void> followInstance(String hostOrHandle) async {
    await client.post(
      '/server/following',
      data: <String, dynamic>{'hostOrHandle': hostOrHandle},
    );
  }

  /// `DELETE /server/following/:hostOrHandle`.
  Future<void> unfollowInstance(String hostOrHandle) async {
    await client.delete('/server/following/$hostOrHandle');
  }

  /// `POST /server/followers/:handle/accept`.
  Future<void> acceptInstanceFollower(String handle) async {
    await client.post('/server/followers/$handle/accept');
  }

  /// `POST /server/followers/:handle/reject`.
  Future<void> rejectInstanceFollower(String handle) async {
    await client.post('/server/followers/$handle/reject');
  }

  /// `GET /server/redundancy/:host`.
  Future<Map<String, dynamic>> getRedundancy(String host) async {
    return jsonMap(await client.get('/server/redundancy/$host'));
  }

  /// `PUT /server/redundancy/:host`.
  Future<void> addRedundancy(String host, {required int redundancyVideos}) async {
    await client.put(
      '/server/redundancy/$host',
      data: <String, dynamic>{'redundancyVideos': redundancyVideos},
    );
  }

  /// `DELETE /server/redundancy/:host`.
  Future<void> removeRedundancy(String host) async {
    await client.delete('/server/redundancy/$host');
  }

  /// `POST /metrics/playback` — anonymous playback metrics.
  Future<void> sendPlaybackMetric(Map<String, dynamic> payload) async {
    await client.post('/metrics/playback', data: payload, authenticated: false);
  }

  /// `GET /player-settings/videos/:videoId` — per-video player preferences.
  Future<Map<String, dynamic>> getVideoPlayerSettings(String videoId) async {
    return jsonMap(await client.get('/player-settings/videos/$videoId'));
  }

  /// `PUT /player-settings/videos/:videoId`.
  Future<void> saveVideoPlayerSettings(String videoId, Map<String, dynamic> settings) async {
    await client.put('/player-settings/videos/$videoId', data: settings);
  }

  /// `GET /player-settings/video-channels/:handle`.
  Future<Map<String, dynamic>> getChannelPlayerSettings(String handle) async {
    return jsonMap(await client.get('/player-settings/video-channels/$handle'));
  }

  /// `PUT /player-settings/video-channels/:handle`.
  Future<void> saveChannelPlayerSettings(String handle, Map<String, dynamic> settings) async {
    await client.put('/player-settings/video-channels/$handle', data: settings);
  }

  /// `GET /ping` — cheap reachability probe.
  Future<bool> ping({CancelToken? cancelToken}) async {
    try {
      await client.get('/ping', authenticated: false, cancelToken: cancelToken);
      return true;
    } catch (_) {
      return false;
    }
  }
}
