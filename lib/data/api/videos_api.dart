import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/json_utils.dart';
import '../../models/paged.dart';
import '../../models/video.dart';
import '../api_section.dart';

/// Everything under `/videos`.
mixin VideosApi on ApiSection {
  /// `GET /videos` — the browse/trending feed.
  Future<PagedResult<Video>> listVideos({
    int start = 0,
    int count = 20,
    String? sort,
    bool? isLocal,
    bool? nsfw,
    Iterable<int>? categoryOneOf,
    Iterable<int>? licenceOneOf,
    Iterable<String>? languageOneOf,
    Iterable<String>? tagsOneOf,
    Iterable<String>? tagsAllOf,
    Iterable<int>? privacyOneOf,
    Iterable<int>? stateOneOf,
    bool? isLive,
    bool? includeScheduledLive,
    bool? hasHLSFiles,
    bool? hasWebVideoFiles,
    bool? excludeAlreadyWatched,
    bool? skipCount,
    int? include,
    String? search,
    String? host,
    String? autoTagOneOf,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/videos',
      cancelToken: cancelToken,
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'isLocal': isLocal,
        'nsfw': nsfw == null ? 'both' : (nsfw ? 'true' : 'false'),
        'categoryOneOf': csv(categoryOneOf),
        'licenceOneOf': csv(licenceOneOf),
        'languageOneOf': csv(languageOneOf),
        'tagsOneOf': csv(tagsOneOf),
        'tagsAllOf': csv(tagsAllOf),
        'privacyOneOf': csv(privacyOneOf),
        'stateOneOf': csv(stateOneOf),
        'isLive': isLive,
        'includeScheduledLive': includeScheduledLive,
        'hasHLSFiles': hasHLSFiles,
        'hasWebVideoFiles': hasWebVideoFiles,
        'excludeAlreadyWatched': excludeAlreadyWatched,
        'skipCount': skipCount,
        'include': include,
        'search': search,
        'host': host,
        'autoTagOneOf': csv(autoTagOneOf == null ? null : <String>[autoTagOneOf]),
      },
    );
    return PagedResult<Video>.fromJson(data, Video.fromJson);
  }

  /// `GET /videos/:id` — accepts a numeric id, a uuid or a short uuid.
  Future<Video> getVideo(String idOrUUID, {String? password, CancelToken? cancelToken}) async {
    final data = await client.get(
      '/videos/$idOrUUID',
      cancelToken: cancelToken,
      query: password == null ? null : <String, dynamic>{'password': password},
    );
    return Video.fromJson(jsonMap(data));
  }

  /// `GET /videos/categories`, `/videos/licences`, `/videos/languages`,
  /// `/videos/privacies`.
  Future<List<VideoConstant>> getVideoConstants(String kind) async {
    final data = await client.get('/videos/$kind', authenticated: false);
    if (data is! List) return const <VideoConstant>[];
    return data
        .map((dynamic e) => VideoConstant.fromJson(jsonMap(e)))
        .toList(growable: false);
  }

  /// `POST /videos/:id/views` — records a view (and history when logged in).
  Future<void> addVideoView(String idOrUUID, {required int currentTime}) async {
    await client.post(
      '/videos/$idOrUUID/views',
      data: <String, dynamic>{'currentTime': currentTime},
    );
  }

  /// `PUT /videos/:id/rate` — [rating] is `like`, `dislike` or `none`.
  Future<void> rateVideo(String idOrUUID, String rating) async {
    await client.put(
      '/videos/$idOrUUID/rate',
      data: <String, dynamic>{'rating': rating},
    );
  }

  /// `GET /videos/:id/captions`.
  Future<List<VideoCaption>> listCaptions(String idOrUUID) async {
    final data = await client.get('/videos/$idOrUUID/captions');
    if (data is! List) return const <VideoCaption>[];
    return data
        .map((dynamic e) => VideoCaption.fromJson(jsonMap(e)))
        .toList(growable: false);
  }

  /// `GET /videos/:id/chapters` — returns an empty list when the plugin is
  /// missing (404) so the UI can simply hide the section.
  Future<List<VideoChapter>> listChapters(String idOrUUID) async {
    try {
      final data = await client.get('/videos/$idOrUUID/chapters');
      if (data is! List) return const <VideoChapter>[];
      return data
          .map((dynamic e) => VideoChapter.fromJson(jsonMap(e)))
          .toList(growable: false);
    } catch (_) {
      return const <VideoChapter>[];
    }
  }

  /// `POST /videos/:id/token` — required to play a private video.
  Future<Map<String, dynamic>> getVideoToken(String idOrUUID) async {
    final data = await client.post('/videos/$idOrUUID/token');
    return jsonMap(data);
  }

  /// `DELETE /videos/:id`.
  Future<void> deleteVideo(String idOrUUID) async {
    await client.delete('/videos/$idOrUUID');
  }

  /// `PUT /videos/:id` — updates the metadata of a video.
  Future<void> updateVideo(
    String idOrUUID, {
    String? name,
    String? description,
    int? category,
    int? licence,
    String? language,
    bool? nsfw,
    List<String>? tags,
    int? privacy,
    int? commentsPolicy,
    bool? downloadEnabled,
    bool? waitTranscoding,
    String? support,
    String? scheduleUpdate,
    String? originallyPublishedAt,
    List<int>? nsfwFlags,
    bool? replaceThumbnail,
    String? thumbnailPath,
    Uint8List? thumbnailBytes,
    String? thumbnailFilename,
  }) async {
    if (replaceThumbnail == true) {
      final form = FormData.fromMap(<String, dynamic>{
        'thumbnailfile': await client.multipartFile(
          path: thumbnailPath,
          bytes: thumbnailBytes,
          filename: thumbnailFilename ?? 'thumbnail.jpg',
        ),
      });
      await client.upload('/videos/$idOrUUID', formData: form);
    }

    await client.put(
      '/videos/$idOrUUID',
      data: <String, dynamic>{
        'name': name,
        'description': description,
        'category': category,
        'licence': licence,
        'language': language,
        'nsfw': nsfw,
        'tags': tags,
        'privacy': privacy,
        'commentsPolicy': commentsPolicy,
        'downloadEnabled': downloadEnabled,
        'waitTranscoding': waitTranscoding,
        'support': support,
        'scheduleUpdate': scheduleUpdate,
        'originallyPublishedAt': originallyPublishedAt,
        'nsfwFlags': nsfwFlags,
      },
    );
  }

  /// `POST /videos/upload` — multipart upload with progress.
  Future<Video> uploadVideo({
    required String channelId,
    required String name,
    required String videoPath,
    Uint8List? videoBytes,
    required String videoFilename,
    String? description,
    int? privacy,
    int? category,
    int? licence,
    String? language,
    List<String>? tags,
    bool? nsfw,
    List<int>? nsfwFlags,
    bool? commentsEnabled,
    int? commentsPolicy,
    bool? downloadEnabled,
    bool? waitTranscoding,
    String? support,
    String? scheduleUpdate,
    String? originallyPublishedAt,
    String? thumbnailPath,
    Uint8List? thumbnailBytes,
    String? thumbnailFilename,
    String? previewPath,
    Uint8List? previewBytes,
    String? previewFilename,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final form = FormData.fromMap(<String, dynamic>{
      'channelId': channelId,
      'name': name,
      'description': description,
      'privacy': privacy,
      'category': category,
      'licence': licence,
      'language': language,
      'tags': tags,
      'nsfw': nsfw,
      'nsfwFlags': nsfwFlags,
      'commentsEnabled': commentsEnabled,
      'commentsPolicy': commentsPolicy,
      'downloadEnabled': downloadEnabled,
      'waitTranscoding': waitTranscoding,
      'support': support,
      'scheduleUpdate': scheduleUpdate,
      'originallyPublishedAt': originallyPublishedAt,
      'videofile': await client.multipartFile(
        path: videoPath,
        bytes: videoBytes,
        filename: videoFilename,
      ),
    });

    if (thumbnailPath != null || thumbnailBytes != null) {
      form.files.add(
        MapEntry(
          'thumbnailfile',
          await client.multipartFile(
            path: thumbnailPath,
            bytes: thumbnailBytes,
            filename: thumbnailFilename ?? 'thumbnail.jpg',
          ),
        ),
      );
    }
    if (previewPath != null || previewBytes != null) {
      form.files.add(
        MapEntry(
          'previewfile',
          await client.multipartFile(
            path: previewPath,
            bytes: previewBytes,
            filename: previewFilename ?? 'preview.jpg',
          ),
        ),
      );
    }

    final data = await client.upload(
      '/videos/upload',
      formData: form,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
    return Video.fromJson(jsonMap(jsonMap(data)['video']));
  }

  /// `POST /videos/imports` — import from a URL or a torrent/magnet.
  Future<void> importVideo({
    required int channelId,
    String? targetUrl,
    String? magnetUri,
    String? torrentfilePath,
    String? name,
    String? description,
    int? privacy,
    int? category,
    int? licence,
    String? language,
    List<String>? tags,
    bool? nsfw,
    bool? commentsEnabled,
    bool? downloadEnabled,
    bool? waitTranscoding,
    String? support,
    String? scheduleUpdate,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (torrentfilePath != null) {
      final form = FormData.fromMap(<String, dynamic>{
        'channelId': channelId,
        'torrentfile': await client.multipartFile(
          path: torrentfilePath,
          filename: 'video.torrent',
        ),
        'name': name,
        'description': description,
        'privacy': privacy,
        'category': category,
        'licence': licence,
        'language': language,
        'tags': tags,
        'nsfw': nsfw,
        'commentsEnabled': commentsEnabled,
        'downloadEnabled': downloadEnabled,
        'waitTranscoding': waitTranscoding,
        'support': support,
        'scheduleUpdate': scheduleUpdate,
      });
      await client.upload('/videos/imports', formData: form, onProgress: onProgress);
      return;
    }

    await client.post(
      '/videos/imports',
      data: <String, dynamic>{
        'channelId': channelId,
        'targetUrl': targetUrl,
        'magnetUri': magnetUri,
        'name': name,
        'description': description,
        'privacy': privacy,
        'category': category,
        'licence': licence,
        'language': language,
        'tags': tags,
        'nsfw': nsfw,
        'commentsEnabled': commentsEnabled,
        'downloadEnabled': downloadEnabled,
        'waitTranscoding': waitTranscoding,
        'support': support,
        'scheduleUpdate': scheduleUpdate,
      },
    );
  }

  /// `GET /videos/imports` — the current user's import jobs.
  Future<PagedResult<Map<String, dynamic>>> listVideoImports({
    int start = 0,
    int count = 20,
    String? sort,
    String? state,
  }) async {
    final data = await client.get(
      '/videos/imports',
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'videoImportState': state,
      },
    );
    return PagedResult<Map<String, dynamic>>.fromJson(data, (Map<String, dynamic> e) => e);
  }

  /// `POST /videos/live` — creates a live video and returns its RTMP info.
  Future<Map<String, dynamic>> createLive({
    required int channelId,
    required String name,
    String? description,
    int? privacy,
    int? category,
    int? licence,
    String? language,
    List<String>? tags,
    bool? nsfw,
    bool? commentsEnabled,
    bool? downloadEnabled,
    bool? saveReplay,
    int? latencyMode,
    String? thumbnailPath,
    Uint8List? thumbnailBytes,
    String? thumbnailFilename,
    String? previewPath,
    Uint8List? previewBytes,
    String? previewFilename,
    String? scheduleStartAt,
    int? saveReplayDuration,
    bool? permanentLive,
  }) async {
    final form = FormData.fromMap(<String, dynamic>{
      'channelId': channelId,
      'name': name,
      'description': description,
      'privacy': privacy,
      'category': category,
      'licence': licence,
      'language': language,
      'tags': tags,
      'nsfw': nsfw,
      'commentsEnabled': commentsEnabled,
      'downloadEnabled': downloadEnabled,
      'saveReplay': saveReplay,
      'latencyMode': latencyMode,
      'scheduleStartAt': scheduleStartAt,
      'saveReplayDuration': saveReplayDuration,
      'permanentLive': permanentLive,
    });
    if (thumbnailPath != null || thumbnailBytes != null) {
      form.files.add(
        MapEntry(
          'thumbnailfile',
          await client.multipartFile(
            path: thumbnailPath,
            bytes: thumbnailBytes,
            filename: thumbnailFilename ?? 'thumbnail.jpg',
          ),
        ),
      );
    }
    if (previewPath != null || previewBytes != null) {
      form.files.add(
        MapEntry(
          'previewfile',
          await client.multipartFile(
            path: previewPath,
            bytes: previewBytes,
            filename: previewFilename ?? 'preview.jpg',
          ),
        ),
      );
    }

    return jsonMap(await client.upload('/videos/live', formData: form));
  }

  /// `PUT /videos/live/:videoId` — updates a live's settings.
  Future<void> updateLive(
    String videoId, {
    bool? saveReplay,
    int? saveReplayDuration,
    int? latencyMode,
    bool? permanentLive,
  }) async {
    await client.put(
      '/videos/live/$videoId',
      data: <String, dynamic>{
        'saveReplay': saveReplay,
        'saveReplayDuration': saveReplayDuration,
        'latencyMode': latencyMode,
        'permanentLive': permanentLive,
      },
    );
  }

  /// `GET /videos/live/:videoId/sessions`.
  Future<PagedResult<Map<String, dynamic>>> listLiveSessions(
    String videoId, {
    int start = 0,
    int count = 20,
  }) async {
    final data = await client.get(
      '/videos/live/$videoId/sessions',
      query: <String, dynamic>{'start': start, 'count': count},
    );
    return PagedResult<Map<String, dynamic>>.fromJson(data, (Map<String, dynamic> e) => e);
  }

  /// `POST /videos/:videoId/transcoding` — re-run transcoding.
  Future<void> runTranscoding(String videoId) async {
    await client.post('/videos/$videoId/transcoding');
  }

  /// `GET /videos/:videoId/passwords`.
  Future<List<Map<String, dynamic>>> listVideoPasswords(String videoId) async {
    final data = await client.get('/videos/$videoId/passwords');
    return jsonMapList(data);
  }

  /// `POST /videos/:videoId/passwords`.
  Future<void> addVideoPassword(String videoId, String password) async {
    await client.post(
      '/videos/$videoId/passwords',
      data: <String, dynamic>{'password': password},
    );
  }

  /// `DELETE /videos/:videoId/passwords/:passwordId`.
  Future<void> deleteVideoPassword(String videoId, int passwordId) async {
    await client.delete('/videos/$videoId/passwords/$passwordId');
  }

  /// `GET /videos/:videoId/source` (source file download).
  Future<Map<String, dynamic>> getVideoSource(String videoId) async {
    return jsonMap(await client.get('/videos/$videoId/source'));
  }
}
