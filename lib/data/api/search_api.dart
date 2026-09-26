import 'package:dio/dio.dart';

import '../../models/actor.dart';
import '../../models/paged.dart';
import '../../models/playlist.dart';
import '../../models/video.dart';
import '../api_section.dart';

/// `/search/*` — the federated search entry points.
///
/// [searchTarget] can be `local`, `search-index` (the instance's search index,
/// e.g. SepiaSearch) or `uris`.
mixin SearchApi on ApiSection {
  /// `GET /search/videos`.
  Future<PagedResult<Video>> searchVideos({
    required String search,
    int start = 0,
    int count = 20,
    String? sort,
    bool? nsfw,
    bool? isLocal,
    String? searchTarget,
    String? host,
    Iterable<int>? categoryOneOf,
    Iterable<int>? licenceOneOf,
    Iterable<String>? languageOneOf,
    Iterable<String>? tagsOneOf,
    Iterable<String>? tagsAllOf,
    Iterable<int>? privacyOneOf,
    Iterable<String>? uuids,
    String? startDate,
    String? endDate,
    int? durationMin,
    int? durationMax,
    bool? isLive,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/search/videos',
      cancelToken: cancelToken,
      query: <String, dynamic>{
        'search': search,
        'start': start,
        'count': count,
        'sort': sort,
        'nsfw': nsfw == null ? 'both' : (nsfw ? 'true' : 'false'),
        'isLocal': isLocal,
        'searchTarget': searchTarget,
        'host': host,
        'categoryOneOf': csv(categoryOneOf),
        'licenceOneOf': csv(licenceOneOf),
        'languageOneOf': csv(languageOneOf),
        'tagsOneOf': csv(tagsOneOf),
        'tagsAllOf': csv(tagsAllOf),
        'privacyOneOf': csv(privacyOneOf),
        'uuids': csv(uuids),
        'startDate': startDate,
        'endDate': endDate,
        'durationMin': durationMin,
        'durationMax': durationMax,
        'isLive': isLive,
      },
    );
    return PagedResult<Video>.fromJson(data, Video.fromJson);
  }

  /// `GET /search/video-channels`.
  Future<PagedResult<VideoChannel>> searchChannels({
    required String search,
    int start = 0,
    int count = 20,
    String? sort,
    String? searchTarget,
    String? host,
    Iterable<String>? handles,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/search/video-channels',
      cancelToken: cancelToken,
      query: <String, dynamic>{
        'search': search,
        'start': start,
        'count': count,
        'sort': sort,
        'searchTarget': searchTarget,
        'host': host,
        'handles': csv(handles),
      },
    );
    return PagedResult<VideoChannel>.fromJson(data, VideoChannel.fromJson);
  }

  /// `GET /search/video-playlists`.
  Future<PagedResult<VideoPlaylist>> searchPlaylists({
    required String search,
    int start = 0,
    int count = 20,
    String? sort,
    String? searchTarget,
    String? host,
    Iterable<String>? uuids,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/search/video-playlists',
      cancelToken: cancelToken,
      query: <String, dynamic>{
        'search': search,
        'start': start,
        'count': count,
        'sort': sort,
        'searchTarget': searchTarget,
        'host': host,
        'uuids': csv(uuids),
      },
    );
    return PagedResult<VideoPlaylist>.fromJson(data, VideoPlaylist.fromJson);
  }
}
