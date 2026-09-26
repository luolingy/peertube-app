import 'actor.dart';
import 'json_utils.dart';
import 'video.dart';

/// A video playlist.
class VideoPlaylist {
  const VideoPlaylist({
    required this.id,
    required this.uuid,
    required this.shortUUID,
    required this.displayName,
    required this.url,
    required this.ownerAccount,
    this.description,
    this.privacy,
    this.thumbnailPath,
    this.videosLength = 0,
    this.createdAt,
    this.updatedAt,
    this.isLocal = true,
  });

  final int id;
  final String uuid;
  final String shortUUID;
  final String displayName;
  final String url;
  final Account ownerAccount;
  final String? description;
  final VideoConstant? privacy;
  final String? thumbnailPath;
  final int videosLength;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isLocal;

  String? thumbnailUrl(String baseUrl) {
    final path = thumbnailPath;
    if (path == null || path.isEmpty) return null;
    return '$baseUrl$path';
  }

  factory VideoPlaylist.fromJson(Map<String, dynamic> json) {
    return VideoPlaylist(
      id: jsonInt(json['id']),
      uuid: jsonString(json['uuid']),
      shortUUID: jsonString(json['shortUUID']),
      displayName: jsonString(json['displayName']),
      url: jsonString(json['url']),
      ownerAccount: Account.fromJson(jsonMap(json['ownerAccount'])),
      description: jsonStringOrNull(json['description']),
      privacy: VideoConstant.fromJsonOrNull(json['privacy']),
      thumbnailPath: jsonStringOrNull(json['thumbnailPath']),
      videosLength: jsonInt(json['videosLength']),
      createdAt: jsonDate(json['createdAt']),
      updatedAt: jsonDate(json['updatedAt']),
      isLocal: jsonBool(json['isLocal'], true),
    );
  }

  static const VideoPlaylist empty = VideoPlaylist(
    id: 0,
    uuid: '',
    shortUUID: '',
    displayName: '',
    url: '',
    ownerAccount: Account.unknown,
  );
}

/// One entry of a playlist (`/video-playlists/:id/videos`).
class VideoPlaylistElement {
  const VideoPlaylistElement({
    required this.id,
    required this.position,
    this.video,
    this.startTimestamp,
    this.stopTimestamp,
  });

  final int id;
  final int position;
  final Video? video;
  final int? startTimestamp;
  final int? stopTimestamp;

  bool get isUnavailable => video == null;

  factory VideoPlaylistElement.fromJson(Map<String, dynamic> json) {
    final video = json['video'];
    return VideoPlaylistElement(
      id: jsonInt(json['id']),
      position: jsonInt(json['position']),
      video: video == null ? null : Video.fromJson(jsonMap(video)),
      startTimestamp: jsonIntOrNull(json['startTimestamp']),
      stopTimestamp: jsonIntOrNull(json['stopTimestamp']),
    );
  }
}

/// `GET /users/me/video-playlists/videos-exist` helper.
class PlaylistVideoExistence {
  const PlaylistVideoExistence({required this.playlistId, required this.exists});

  final int playlistId;
  final bool exists;

  factory PlaylistVideoExistence.fromJson(Map<String, dynamic> json) {
    return PlaylistVideoExistence(
      playlistId: jsonInt(json['playlistId']),
      exists: jsonBool(json['exists']),
    );
  }
}
