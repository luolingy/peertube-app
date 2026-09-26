import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/json_utils.dart';
import '../../models/paged.dart';
import '../../models/playlist.dart';
import '../../models/video.dart';
import '../api_section.dart';

/// Everything under `/video-playlists`.
mixin PlaylistsApi on ApiSection {
  /// `GET /video-playlists` — public playlists of the instance.
  Future<PagedResult<VideoPlaylist>> listPlaylists({
    int start = 0,
    int count = 20,
    String? sort,
    int? playlistType,
    String? search,
    String? owner,
    Iterable<String>? channelNameOneOf,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/video-playlists',
      cancelToken: cancelToken,
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'playlistType': playlistType,
        'search': search,
        'owner': owner,
        'channelNameOneOf': csv(channelNameOneOf),
      },
    );
    return PagedResult<VideoPlaylist>.fromJson(data, VideoPlaylist.fromJson);
  }

  /// `GET /video-playlists/:playlistId`.
  Future<VideoPlaylist> getPlaylist(int playlistId) async {
    return VideoPlaylist.fromJson(jsonMap(await client.get('/video-playlists/$playlistId')));
  }

  /// `GET /video-playlists/:playlistId/videos`.
  Future<PagedResult<VideoPlaylistElement>> listPlaylistVideos(
    int playlistId, {
    int start = 0,
    int count = 50,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/video-playlists/$playlistId/videos',
      cancelToken: cancelToken,
      query: <String, dynamic>{'start': start, 'count': count},
    );
    return PagedResult<VideoPlaylistElement>.fromJson(data, VideoPlaylistElement.fromJson);
  }

  /// `GET /video-playlists/privacies`.
  Future<List<VideoConstant>> listPlaylistPrivacies() async {
    final data = await client.get('/video-playlists/privacies', authenticated: false);
    if (data is! List) return const <VideoConstant>[];
    return data
        .map((dynamic e) => VideoConstant.fromJson(jsonMap(e)))
        .toList(growable: false);
  }

  /// `POST /video-playlists`.
  Future<VideoPlaylist> createPlaylist({
    required String displayName,
    String? description,
    int privacy = 1,
    int? channelId,
    String? thumbnailPath,
    Uint8List? thumbnailBytes,
    String thumbnailFilename = 'playlist.jpg',
  }) async {
    final hasThumbnail = thumbnailPath != null || thumbnailBytes != null;

    dynamic data;
    if (hasThumbnail) {
      data = FormData.fromMap(<String, dynamic>{
        'displayName': displayName,
        'description': description,
        'privacy': privacy,
        'videoChannelId': channelId,
        'thumbnailfile': await client.multipartFile(
          path: thumbnailPath,
          bytes: thumbnailBytes,
          filename: thumbnailFilename,
        ),
      });
    } else {
      data = <String, dynamic>{
        'displayName': displayName,
        'description': description,
        'privacy': privacy,
        'videoChannelId': channelId,
      };
    }

    final response = hasThumbnail
        ? await client.upload('/video-playlists', formData: data as FormData)
        : await client.post('/video-playlists', data: data);

    return VideoPlaylist.fromJson(jsonMap(jsonMap(response)['videoPlaylist']));
  }

  /// `PUT /video-playlists/:playlistId`.
  Future<VideoPlaylist> updatePlaylist(
    int playlistId, {
    String? displayName,
    String? description,
    int? privacy,
    int? channelId,
    String? thumbnailPath,
    Uint8List? thumbnailBytes,
    String thumbnailFilename = 'playlist.jpg',
  }) async {
    final hasThumbnail = thumbnailPath != null || thumbnailBytes != null;

    dynamic response;
    if (hasThumbnail) {
      final form = FormData.fromMap(<String, dynamic>{
        'displayName': displayName,
        'description': description,
        'privacy': privacy,
        'videoChannelId': channelId,
        'thumbnailfile': await client.multipartFile(
          path: thumbnailPath,
          bytes: thumbnailBytes,
          filename: thumbnailFilename,
        ),
      });
      response = await client.upload('/video-playlists/$playlistId', formData: form);
    } else {
      response = await client.put(
        '/video-playlists/$playlistId',
        data: <String, dynamic>{
          'displayName': displayName,
          'description': description,
          'privacy': privacy,
          'videoChannelId': channelId,
        },
      );
    }

    return VideoPlaylist.fromJson(jsonMap(jsonMap(response)['videoPlaylist']));
  }

  /// `DELETE /video-playlists/:playlistId`.
  Future<void> deletePlaylist(int playlistId) async {
    await client.delete('/video-playlists/$playlistId');
  }

  /// `POST /video-playlists/:playlistId/videos`.
  Future<void> addVideoToPlaylist(
    int playlistId,
    String videoId, {
    int? startTimestamp,
    int? stopTimestamp,
  }) async {
    await client.post(
      '/video-playlists/$playlistId/videos',
      data: <String, dynamic>{
        'videoId': videoId,
        'startTimestamp': startTimestamp,
        'stopTimestamp': stopTimestamp,
      },
    );
  }

  /// `PUT /video-playlists/:playlistId/videos/:elementId`.
  Future<void> updatePlaylistElement(
    int playlistId,
    int elementId, {
    int? startTimestamp,
    int? stopTimestamp,
  }) async {
    await client.put(
      '/video-playlists/$playlistId/videos/$elementId',
      data: <String, dynamic>{
        'startTimestamp': startTimestamp,
        'stopTimestamp': stopTimestamp,
      },
    );
  }

  /// `DELETE /video-playlists/:playlistId/videos/:elementId`.
  Future<void> removeVideoFromPlaylist(int playlistId, int elementId) async {
    await client.delete('/video-playlists/$playlistId/videos/$elementId');
  }

  /// `POST /video-playlists/:playlistId/videos/reorder`.
  Future<void> reorderPlaylist(
    int playlistId, {
    required int startPosition,
    required int insertAfterPosition,
    int? reorderLength,
  }) async {
    await client.post(
      '/video-playlists/$playlistId/videos/reorder',
      data: <String, dynamic>{
        'startPosition': startPosition,
        'insertAfterPosition': insertAfterPosition,
        'reorderLength': reorderLength,
      },
    );
  }
}
