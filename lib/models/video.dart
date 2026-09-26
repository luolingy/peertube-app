import 'actor.dart';
import 'json_utils.dart';

/// `{ id, label }` pair returned for categories, licences, languages,
/// privacies and states.
///
/// Categories, licences and privacies use numeric ids while languages use ISO
/// codes (`en`, `zh-Hans`, ...), so both representations are kept.
class VideoConstant {
  const VideoConstant({this.id, this.rawId, required this.label});

  final int? id;
  final String? rawId;
  final String label;

  /// The id as a string, whichever form the API used.
  String get key => rawId ?? (id?.toString() ?? '');

  factory VideoConstant.fromJson(Map<String, dynamic> json) {
    final raw = json['id'];
    return VideoConstant(
      id: jsonIntOrNull(raw),
      rawId: raw == null ? null : '$raw',
      label: jsonString(json['label']),
    );
  }

  static VideoConstant? fromJsonOrNull(dynamic value) {
    if (value == null) return null;
    final map = jsonMap(value);
    if (map.isEmpty) return null;
    return VideoConstant.fromJson(map);
  }

  @override
  String toString() => label;
}

/// One entry of `video.thumbnails`.
class VideoThumbnail {
  const VideoThumbnail({
    required this.fileUrl,
    this.width,
    this.height,
    this.aspectRatio,
  });

  final String fileUrl;
  final int? width;
  final int? height;
  final String? aspectRatio;

  factory VideoThumbnail.fromJson(Map<String, dynamic> json) {
    return VideoThumbnail(
      fileUrl: jsonString(json['fileUrl']),
      width: jsonIntOrNull(json['width']),
      height: jsonIntOrNull(json['height']),
      aspectRatio: jsonStringOrNull(json['aspectRatio']),
    );
  }
}

/// A progressive video/audio file (`video.files`).
class VideoFile {
  const VideoFile({
    required this.id,
    required this.fileUrl,
    required this.fileDownloadUrl,
    required this.resolution,
    this.width = 0,
    this.height = 0,
    this.size = 0,
    this.fps = 0,
    this.hasAudio = true,
    this.hasVideo = true,
    this.torrentUrl,
    this.torrentDownloadUrl,
    this.magnetUri,
    this.playlistUrl,
    this.metadataUrl,
    this.storage,
  });

  final int id;
  final String fileUrl;
  final String fileDownloadUrl;
  final VideoConstant resolution;
  final int width;
  final int height;
  final int size;
  final int fps;
  final bool hasAudio;
  final bool hasVideo;
  final String? torrentUrl;
  final String? torrentDownloadUrl;
  final String? magnetUri;

  /// Present for HLS files: the per-resolution media playlist.
  final String? playlistUrl;
  final String? metadataUrl;
  final int? storage;

  /// `1080p`, `Audio only`, ...
  String get label => resolution.label;

  /// A human readable quality label, e.g. `1080p`.
  String get qualityLabel {
    if (hasVideo && height > 0) return '${height}p';
    if (!hasVideo && hasAudio) return '仅音频';
    return resolution.label;
  }

  factory VideoFile.fromJson(Map<String, dynamic> json) {
    return VideoFile(
      id: jsonInt(json['id']),
      fileUrl: jsonString(json['fileUrl']),
      fileDownloadUrl: jsonString(json['fileDownloadUrl']),
      resolution: VideoConstant.fromJson(jsonMap(json['resolution'])),
      width: jsonInt(json['width']),
      height: jsonInt(json['height']),
      size: jsonInt(json['size']),
      fps: jsonInt(json['fps']),
      hasAudio: jsonBool(json['hasAudio'], true),
      hasVideo: jsonBool(json['hasVideo'], true),
      torrentUrl: jsonStringOrNull(json['torrentUrl']),
      torrentDownloadUrl: jsonStringOrNull(json['torrentDownloadUrl']),
      magnetUri: jsonStringOrNull(json['magnetUri']),
      playlistUrl: jsonStringOrNull(json['playlistUrl']),
      metadataUrl: jsonStringOrNull(json['metadataUrl']),
      storage: jsonIntOrNull(json['storage']),
    );
  }
}

/// An HLS playlist (`video.streamingPlaylists`).
class VideoStreamingPlaylist {
  const VideoStreamingPlaylist({
    required this.id,
    required this.playlistUrl,
    this.segmentsSha256Url,
    this.files = const <VideoFile>[],
  });

  final int id;

  /// Master playlist (`master.m3u8`).
  final String playlistUrl;
  final String? segmentsSha256Url;
  final List<VideoFile> files;

  factory VideoStreamingPlaylist.fromJson(Map<String, dynamic> json) {
    return VideoStreamingPlaylist(
      id: jsonInt(json['id']),
      playlistUrl: jsonString(json['playlistUrl']),
      segmentsSha256Url: jsonStringOrNull(json['segmentsSha256Url']),
      files: jsonMapList(json['files']).map(VideoFile.fromJson).toList(growable: false),
    );
  }
}

/// A video, both in its list form and in its full `/videos/:id` form.
///
/// Every field that only exists in the "details" payload is nullable or empty,
/// which lets a single class flow through the whole UI.
class Video {
  const Video({
    required this.id,
    required this.uuid,
    required this.shortUUID,
    required this.name,
    required this.url,
    required this.account,
    this.channel,
    this.description,
    this.truncatedDescription,
    this.category,
    this.licence,
    this.language,
    this.privacy,
    this.nsfw = false,
    this.nsfwFlags = 0,
    this.nsfwSummary,
    this.isLocal = true,
    this.duration = 0,
    this.aspectRatio = 16 / 9,
    this.views = 0,
    this.viewers = 0,
    this.downloads = 0,
    this.likes = 0,
    this.dislikes = 0,
    this.comments = 0,
    this.thumbnailPath = '',
    this.previewPath = '',
    this.thumbnails = const <VideoThumbnail>[],
    this.embedPath = '',
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.originallyPublishedAt,
    this.isLive = false,
    this.streamingPlaylists = const <VideoStreamingPlaylist>[],
    this.files = const <VideoFile>[],
    this.tags = const <String>[],
    this.support,
    this.commentsPolicy,
    this.downloadEnabled = true,
    this.waitTranscoding = false,
    this.state,
    this.trackerUrls = const <String>[],
    this.blacklisted = false,
    this.blacklistedReason,
    this.pluginData = const <String, dynamic>{},
    this.liveSchedules = const <Map<String, dynamic>>[],
    this.inputFileUpdatedAt,
    this.embedPrivacyPolicy,
    this.hasHlsFiles = false,
    this.hasWebVideoFiles = false,
    this.isPasswordProtected = false,
  });

  final int id;
  final String uuid;
  final String shortUUID;
  final String name;
  final String url;
  final Account account;
  final VideoChannel? channel;
  final String? description;
  final String? truncatedDescription;
  final VideoConstant? category;
  final VideoConstant? licence;
  final VideoConstant? language;
  final VideoConstant? privacy;
  final bool nsfw;
  final int nsfwFlags;
  final String? nsfwSummary;
  final bool isLocal;
  final int duration;
  final double aspectRatio;
  final int views;
  final int viewers;
  final int downloads;
  final int likes;
  final int dislikes;
  final int comments;
  final String thumbnailPath;
  final String previewPath;
  final List<VideoThumbnail> thumbnails;
  final String embedPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;
  final DateTime? originallyPublishedAt;
  final bool isLive;

  // Details-only fields.
  final List<VideoStreamingPlaylist> streamingPlaylists;
  final List<VideoFile> files;
  final List<String> tags;
  final String? support;
  final VideoConstant? commentsPolicy;
  final bool downloadEnabled;
  final bool waitTranscoding;
  final VideoConstant? state;
  final List<String> trackerUrls;
  final bool blacklisted;
  final String? blacklistedReason;
  final Map<String, dynamic> pluginData;
  final List<Map<String, dynamic>> liveSchedules;
  final DateTime? inputFileUpdatedAt;
  final VideoConstant? embedPrivacyPolicy;
  final bool hasHlsFiles;
  final bool hasWebVideoFiles;
  final bool isPasswordProtected;

  bool get isPublished => state == null || state?.id == 1;
  bool get isPasswordProtectedVideo => privacy?.id == 5;

  /// A `mm:ss` / `h:mm:ss` label for the video length.
  String get durationLabel {
    if (isLive) return '直播';
    final h = duration ~/ 3600;
    final m = (duration % 3600) ~/ 60;
    final s = duration % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Best thumbnail URL for the requested width.
  String thumbnailUrl(String baseUrl, {int width = 480}) {
    if (thumbnails.isEmpty) {
      if (thumbnailPath.isEmpty) return '';
      return '$baseUrl$thumbnailPath';
    }

    VideoThumbnail best = thumbnails.first;
    var bestDelta = (best.width ?? 0) - width;
    if (bestDelta < 0) bestDelta = -bestDelta;

    for (final thumbnail in thumbnails.skip(1)) {
      var delta = (thumbnail.width ?? 0) - width;
      if (delta < 0) delta = -delta;
      if (delta < bestDelta) {
        best = thumbnail;
        bestDelta = delta;
      }
    }
    return best.fileUrl;
  }

  /// Animated preview used on hover, if the instance provides one.
  String? previewUrl(String baseUrl) {
    if (previewPath.isEmpty) return null;
    return '$baseUrl$previewPath';
  }

  /// The HLS master playlist, when the video was transcoded.
  String? get hlsMasterUrl {
    for (final playlist in streamingPlaylists) {
      if (playlist.playlistUrl.isNotEmpty) return playlist.playlistUrl;
    }
    return null;
  }

  /// Progressive files that contain both audio and video, best quality first.
  List<VideoFile> get progressiveVideoFiles {
    final result = files.where((f) => f.hasVideo && f.hasAudio && f.fileUrl.isNotEmpty).toList();
    result.sort((a, b) => b.height.compareTo(a.height));
    return result;
  }

  /// Audio-only progressive files (used as a last resort fallback).
  List<VideoFile> get audioFiles =>
      files.where((f) => !f.hasVideo && f.hasAudio && f.fileUrl.isNotEmpty).toList();

  /// URL used by the player.
  ///
  /// HLS is preferred because PeerTube only keeps HLS files for most videos;
  /// progressive MP4 remains the fallback for instances without transcoding.
  String? playbackUrl({bool preferHls = true}) {
    if (preferHls) {
      final hls = hlsMasterUrl;
      if (hls != null) return hls;
    }
    final progressive = progressiveVideoFiles;
    if (progressive.isNotEmpty) return progressive.first.fileUrl;
    final audio = audioFiles;
    if (audio.isNotEmpty) return audio.first.fileUrl;
    return hlsMasterUrl;
  }

  /// True when the player must use an HLS manifest.
  bool get isHlsOnly => hlsMasterUrl != null && progressiveVideoFiles.isEmpty;

  /// Available quality choices, for the in-player quality menu.
  List<VideoFile> get qualityOptions {
    final hlsFiles = <VideoFile>[];
    for (final playlist in streamingPlaylists) {
      hlsFiles.addAll(playlist.files.where((f) => f.hasVideo && f.playlistUrl != null));
    }
    if (hlsFiles.isNotEmpty) {
      hlsFiles.sort((a, b) => b.height.compareTo(a.height));
      return hlsFiles;
    }
    return progressiveVideoFiles;
  }

  factory Video.fromJson(Map<String, dynamic> json) {
    final channel = json['channel'];

    return Video(
      id: jsonInt(json['id']),
      uuid: jsonString(json['uuid']),
      shortUUID: jsonString(json['shortUUID']),
      name: jsonString(json['name']),
      url: jsonString(json['url']),
      account: Account.fromJson(jsonMap(json['account'])),
      channel: channel == null ? null : VideoChannel.fromJson(jsonMap(channel)),
      description: jsonStringOrNull(json['description']),
      truncatedDescription: jsonStringOrNull(json['truncatedDescription']),
      category: VideoConstant.fromJsonOrNull(json['category']),
      licence: VideoConstant.fromJsonOrNull(json['licence']),
      language: VideoConstant.fromJsonOrNull(json['language']),
      privacy: VideoConstant.fromJsonOrNull(json['privacy']),
      nsfw: jsonBool(json['nsfw']),
      nsfwFlags: jsonInt(json['nsfwFlags']),
      nsfwSummary: jsonStringOrNull(json['nsfwSummary']),
      isLocal: jsonBool(json['isLocal'], true),
      duration: jsonInt(json['duration']),
      aspectRatio: jsonDouble(json['aspectRatio'], 16 / 9),
      views: jsonInt(json['views']),
      viewers: jsonInt(json['viewers']),
      downloads: jsonInt(json['downloads']),
      likes: jsonInt(json['likes']),
      dislikes: jsonInt(json['dislikes']),
      comments: jsonInt(json['comments']),
      thumbnailPath: jsonString(json['thumbnailPath']),
      previewPath: jsonString(json['previewPath']),
      thumbnails: jsonMapList(json['thumbnails'])
          .map(VideoThumbnail.fromJson)
          .toList(growable: false),
      embedPath: jsonString(json['embedPath']),
      createdAt: jsonDate(json['createdAt']),
      updatedAt: jsonDate(json['updatedAt']),
      publishedAt: jsonDate(json['publishedAt']),
      originallyPublishedAt: jsonDate(json['originallyPublishedAt']),
      isLive: jsonBool(json['isLive']),
      streamingPlaylists: jsonMapList(json['streamingPlaylists'])
          .map(VideoStreamingPlaylist.fromJson)
          .toList(growable: false),
      files: jsonMapList(json['files']).map(VideoFile.fromJson).toList(growable: false),
      tags: jsonStringList(json['tags']),
      support: jsonStringOrNull(json['support']),
      commentsPolicy: VideoConstant.fromJsonOrNull(json['commentsPolicy']),
      downloadEnabled: jsonBool(json['downloadEnabled'], true),
      waitTranscoding: jsonBool(json['waitTranscoding']),
      state: VideoConstant.fromJsonOrNull(json['state']),
      trackerUrls: jsonStringList(json['trackerUrls']),
      blacklisted: jsonBool(json['blacklisted']),
      blacklistedReason: jsonStringOrNull(json['blacklistedReason']),
      pluginData: jsonMap(json['pluginData']),
      liveSchedules: jsonMapList(json['liveSchedules']),
      inputFileUpdatedAt: jsonDate(json['inputFileUpdatedAt']),
      embedPrivacyPolicy: VideoConstant.fromJsonOrNull(json['embedPrivacyPolicy']),
      hasHlsFiles: (json['streamingPlaylists'] is List &&
          (json['streamingPlaylists'] as List).isNotEmpty),
      hasWebVideoFiles: (json['files'] is List) && (json['files'] as List).isNotEmpty,
      isPasswordProtected: jsonIntOrNull(jsonMap(json['privacy'])['id']) == 5,
    );
  }

  static const Video empty = Video(
    id: 0,
    uuid: '',
    shortUUID: '',
    name: '',
    url: '',
    account: Account.unknown,
  );
}

/// A caption/subtitle track (`/videos/:id/captions`).
class VideoCaption {
  const VideoCaption({
    required this.language,
    required this.label,
    required this.captionPath,
    this.fileUrl,
    this.updatedAt,
  });

  final String language;
  final String label;
  final String captionPath;
  final String? fileUrl;
  final DateTime? updatedAt;

  String urlOn(String baseUrl) {
    final url = fileUrl;
    if (url != null && url.isNotEmpty) return url;
    return '$baseUrl$captionPath';
  }

  factory VideoCaption.fromJson(Map<String, dynamic> json) {
    return VideoCaption(
      language: jsonString(json['language']),
      label: jsonString(json['label']),
      captionPath: jsonString(json['captionPath']),
      fileUrl: jsonStringOrNull(json['fileUrl']),
      updatedAt: jsonDate(json['updatedAt']),
    );
  }
}

/// A chapter (`/videos/:id/chapters`).
class VideoChapter {
  const VideoChapter({required this.title, required this.timecode});

  final String title;
  final int timecode;

  factory VideoChapter.fromJson(Map<String, dynamic> json) {
    return VideoChapter(
      title: jsonString(json['title']),
      timecode: jsonInt(json['timecode']),
    );
  }
}

/// An entry of `/overviews/videos`.
class VideoOverview {
  const VideoOverview({
    required this.id,
    required this.name,
    required this.views,
    this.category,
    this.thumbnailPath,
    this.thumbnails = const <VideoThumbnail>[],
    this.channel,
    this.isLive = false,
  });

  final int id;
  final String name;
  final int views;
  final VideoConstant? category;
  final String? thumbnailPath;
  final List<VideoThumbnail> thumbnails;
  final VideoChannel? channel;
  final bool isLive;

  factory VideoOverview.fromJson(Map<String, dynamic> json) {
    final channel = json['channel'];
    return VideoOverview(
      id: jsonInt(json['id']),
      name: jsonString(json['name']),
      views: jsonInt(json['views']),
      category: VideoConstant.fromJsonOrNull(json['category']),
      thumbnailPath: jsonStringOrNull(json['thumbnailPath']),
      thumbnails: jsonMapList(json['thumbnails'])
          .map(VideoThumbnail.fromJson)
          .toList(growable: false),
      channel: channel == null ? null : VideoChannel.fromJson(jsonMap(channel)),
      isLive: jsonBool(json['isLive']),
    );
  }

  String thumbnailUrl(String baseUrl, {int width = 280}) {
    if (thumbnails.isEmpty) {
      final path = thumbnailPath;
      if (path == null || path.isEmpty) return '';
      return '$baseUrl$path';
    }
    VideoThumbnail best = thumbnails.first;
    var bestDelta = (best.width ?? 0) - width;
    if (bestDelta < 0) bestDelta = -bestDelta;
    for (final thumbnail in thumbnails.skip(1)) {
      var delta = (thumbnail.width ?? 0) - width;
      if (delta < 0) delta = -delta;
      if (delta < bestDelta) {
        best = thumbnail;
        bestDelta = delta;
      }
    }
    return best.fileUrl;
  }
}
