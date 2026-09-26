import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/actor.dart';
import '../../models/json_utils.dart';
import '../../models/misc.dart';
import '../../models/paged.dart';
import '../../models/playlist.dart';
import '../../models/video.dart';
import '../api_section.dart';

/// Accounts, video channels and subscription endpoints.
mixin ActorsApi on ApiSection {
  // --- accounts -----------------------------------------------------------

  /// `GET /accounts/:handle`.
  Future<Account> getAccount(String handle) async {
    return Account.fromJson(jsonMap(await client.get('/accounts/$handle')));
  }

  /// `GET /accounts/:handle/videos`.
  Future<PagedResult<Video>> listAccountVideos(
    String handle, {
    int start = 0,
    int count = 20,
    String? sort,
    bool? nsfw,
    bool? excludeAlreadyWatched,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/accounts/$handle/videos',
      cancelToken: cancelToken,
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'nsfw': nsfw == null ? 'both' : (nsfw ? 'true' : 'false'),
        'excludeAlreadyWatched': excludeAlreadyWatched,
      },
    );
    return PagedResult<Video>.fromJson(data, Video.fromJson);
  }

  /// `GET /accounts/:handle/video-channels`.
  Future<PagedResult<VideoChannel>> listAccountChannels(
    String handle, {
    int start = 0,
    int count = 20,
    String? sort,
  }) async {
    final data = await client.get(
      '/accounts/$handle/video-channels',
      query: <String, dynamic>{'start': start, 'count': count, 'sort': sort},
    );
    return PagedResult<VideoChannel>.fromJson(data, VideoChannel.fromJson);
  }

  /// `GET /accounts/:handle/video-playlists`.
  Future<PagedResult<VideoPlaylist>> listAccountPlaylists(
    String handle, {
    int start = 0,
    int count = 20,
    String? sort,
  }) async {
    final data = await client.get(
      '/accounts/$handle/video-playlists',
      query: <String, dynamic>{'start': start, 'count': count, 'sort': sort},
    );
    return PagedResult<VideoPlaylist>.fromJson(data, VideoPlaylist.fromJson);
  }

  /// `GET /accounts/:handle/followers`.
  Future<PagedResult<ActorFollow>> listAccountFollowers(
    String handle, {
    int start = 0,
    int count = 20,
    String? sort,
  }) async {
    final data = await client.get(
      '/accounts/$handle/followers',
      query: <String, dynamic>{'start': start, 'count': count, 'sort': sort},
    );
    return PagedResult<ActorFollow>.fromJson(data, ActorFollow.fromJson);
  }

  /// `GET /accounts/:handle/following`.
  Future<PagedResult<ActorFollow>> listAccountFollowing(
    String handle, {
    int start = 0,
    int count = 20,
    String? sort,
  }) async {
    final data = await client.get(
      '/accounts/$handle/following',
      query: <String, dynamic>{'start': start, 'count': count, 'sort': sort},
    );
    return PagedResult<ActorFollow>.fromJson(data, ActorFollow.fromJson);
  }

  /// `GET /accounts/:handle/ratings` — videos the account liked/disliked.
  Future<PagedResult<Video>> listAccountRatings(
    String handle, {
    required String rating,
    int start = 0,
    int count = 20,
  }) async {
    final data = await client.get(
      '/accounts/$handle/ratings',
      query: <String, dynamic>{'rating': rating, 'start': start, 'count': count},
    );
    return PagedResult<Video>.fromJson(data, Video.fromJson);
  }

  /// `GET /accounts/:handle/video-channel-syncs`.
  Future<PagedResult<Map<String, dynamic>>> listAccountChannelSyncs(
    String handle, {
    int start = 0,
    int count = 20,
  }) async {
    final data = await client.get(
      '/accounts/$handle/video-channel-syncs',
      query: <String, dynamic>{'start': start, 'count': count},
    );
    return PagedResult<Map<String, dynamic>>.fromJson(data, (Map<String, dynamic> e) => e);
  }

  // --- channels -----------------------------------------------------------

  /// `GET /video-channels/:handle`.
  Future<VideoChannel> getChannel(String handle) async {
    return VideoChannel.fromJson(jsonMap(await client.get('/video-channels/$handle')));
  }

  /// `GET /video-channels/:handle/videos`.
  Future<PagedResult<Video>> listChannelVideos(
    String handle, {
    int start = 0,
    int count = 20,
    String? sort,
    bool? nsfw,
    bool? isLive,
    bool? excludeAlreadyWatched,
    Iterable<String>? tagsOneOf,
    Iterable<String>? tagsAllOf,
    Iterable<String>? languageOneOf,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/video-channels/$handle/videos',
      cancelToken: cancelToken,
      query: <String, dynamic>{
        'start': start,
        'count': count,
        'sort': sort,
        'nsfw': nsfw == null ? 'both' : (nsfw ? 'true' : 'false'),
        'isLive': isLive,
        'excludeAlreadyWatched': excludeAlreadyWatched,
        'tagsOneOf': csv(tagsOneOf),
        'tagsAllOf': csv(tagsAllOf),
        'languageOneOf': csv(languageOneOf),
      },
    );
    return PagedResult<Video>.fromJson(data, Video.fromJson);
  }

  /// `GET /video-channels/:handle/followers`.
  Future<PagedResult<ActorFollow>> listChannelFollowers(
    String handle, {
    int start = 0,
    int count = 20,
    String? sort,
  }) async {
    final data = await client.get(
      '/video-channels/$handle/followers',
      query: <String, dynamic>{'start': start, 'count': count, 'sort': sort},
    );
    return PagedResult<ActorFollow>.fromJson(data, ActorFollow.fromJson);
  }

  /// `GET /video-channels/:handle/video-playlists`.
  Future<PagedResult<VideoPlaylist>> listChannelPlaylists(
    String handle, {
    int start = 0,
    int count = 20,
    String? sort,
  }) async {
    final data = await client.get(
      '/video-channels/$handle/video-playlists',
      query: <String, dynamic>{'start': start, 'count': count, 'sort': sort},
    );
    return PagedResult<VideoPlaylist>.fromJson(data, VideoPlaylist.fromJson);
  }

  /// `GET /video-channels/:handle/activities`.
  Future<PagedResult<Map<String, dynamic>>> listChannelActivities(
    String handle, {
    int start = 0,
    int count = 20,
  }) async {
    final data = await client.get(
      '/video-channels/$handle/activities',
      query: <String, dynamic>{'start': start, 'count': count},
    );
    return PagedResult<Map<String, dynamic>>.fromJson(data, (Map<String, dynamic> e) => e);
  }

  /// `POST /video-channels` — creates a channel for the logged in user.
  Future<VideoChannel> createChannel({
    required String name,
    required String displayName,
    String? description,
    String? support,
  }) async {
    final data = await client.post(
      '/video-channels',
      data: <String, dynamic>{
        'name': name,
        'displayName': displayName,
        'description': description,
        'support': support,
      },
    );
    return VideoChannel.fromJson(jsonMap(jsonMap(data)['videoChannel']));
  }

  /// `PUT /video-channels/:handle`.
  Future<void> updateChannel(
    String handle, {
    String? displayName,
    String? description,
    String? support,
  }) async {
    await client.put(
      '/video-channels/$handle',
      data: <String, dynamic>{
        'displayName': displayName,
        'description': description,
        'support': support,
      },
    );
  }

  /// `DELETE /video-channels/:handle`.
  Future<void> deleteChannel(String handle) async {
    await client.delete('/video-channels/$handle');
  }

  /// `POST /video-channels/:handle/avatar/pick`.
  Future<void> uploadChannelAvatar(
    String handle, {
    String? path,
    Uint8List? bytes,
    String filename = 'avatar.png',
  }) async {
    final form = FormData.fromMap(<String, dynamic>{
      'avatarfile': await client.multipartFile(path: path, bytes: bytes, filename: filename),
    });
    await client.upload('/video-channels/$handle/avatar/pick', formData: form);
  }

  /// `POST /video-channels/:handle/banner/pick`.
  Future<void> uploadChannelBanner(
    String handle, {
    String? path,
    Uint8List? bytes,
    String filename = 'banner.png',
  }) async {
    final form = FormData.fromMap(<String, dynamic>{
      'bannerfile': await client.multipartFile(path: path, bytes: bytes, filename: filename),
    });
    await client.upload('/video-channels/$handle/banner/pick', formData: form);
  }

  /// `DELETE /video-channels/:handle/avatar`.
  Future<void> deleteChannelAvatar(String handle) async {
    await client.delete('/video-channels/$handle/avatar');
  }

  /// `DELETE /video-channels/:handle/banner`.
  Future<void> deleteChannelBanner(String handle) async {
    await client.delete('/video-channels/$handle/banner');
  }

  // --- subscriptions ------------------------------------------------------

  /// `GET /users/me/subscriptions/exist?uris=`.
  Future<Map<String, bool>> subscriptionsExist(Iterable<String> uris) async {
    final uriList = uris.toList(growable: false);
    if (uriList.isEmpty) return <String, bool>{};

    final data = await client.get(
      '/users/me/subscriptions/exist',
      query: <String, dynamic>{'uris': csv(uriList)},
    );

    final result = <String, bool>{};
    for (final entry in jsonMapList(data)) {
      final uri = jsonStringOrNull(entry['uri']);
      if (uri != null) result[uri] = jsonBool(entry['exists']);
    }
    return result;
  }

  /// `POST /users/me/subscriptions` — [uri] is `name@host` or `name`.
  Future<void> subscribe(String uri) async {
    await client.post('/users/me/subscriptions', data: <String, dynamic>{'uri': uri});
  }

  /// `DELETE /users/me/subscriptions/:uri`.
  Future<void> unsubscribe(String uri) async {
    await client.delete('/users/me/subscriptions/$uri');
  }

  /// `GET /users/me/subscriptions/:uri`.
  Future<Map<String, dynamic>> getSubscription(String uri) async {
    return jsonMap(await client.get('/users/me/subscriptions/$uri'));
  }
}
