import 'json_utils.dart';

/// An avatar or banner image of an account/channel.
class ActorImage {
  const ActorImage({
    required this.path,
    this.fileUrl,
    this.width,
    this.height,
    this.createdAt,
    this.updatedAt,
  });

  final String path;
  final String? fileUrl;
  final int? width;
  final int? height;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ActorImage.fromJson(Map<String, dynamic> json) {
    return ActorImage(
      path: jsonString(json['path']),
      fileUrl: jsonStringOrNull(json['fileUrl']),
      width: jsonIntOrNull(json['width']),
      height: jsonIntOrNull(json['height']),
      createdAt: jsonDate(json['createdAt']),
      updatedAt: jsonDate(json['updatedAt']),
    );
  }

  String urlOn(String baseUrl) {
    final url = fileUrl;
    if (url != null && url.isNotEmpty) return url;
    return '$baseUrl$path';
  }
}

List<ActorImage> parseActorImages(dynamic value) {
  return jsonMapList(value).map(ActorImage.fromJson).toList(growable: false);
}

/// Picks the image whose width is closest to [preferredWidth].
ActorImage? pickActorImage(List<ActorImage> images, {int preferredWidth = 120}) {
  if (images.isEmpty) return null;

  ActorImage best = images.first;
  var bestDelta = (best.width ?? 0) - preferredWidth;
  if (bestDelta < 0) bestDelta = -bestDelta;

  for (final image in images.skip(1)) {
    var delta = (image.width ?? 0) - preferredWidth;
    if (delta < 0) delta = -delta;
    if (delta < bestDelta) {
      best = image;
      bestDelta = delta;
    }
  }
  return best;
}

/// A user account. The API returns a lighter shape inside video payloads and a
/// richer one from `/accounts/:handle`; every optional field is therefore
/// nullable and the same class is used for both.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.displayName,
    required this.url,
    required this.host,
    required this.avatars,
    this.description,
    this.userId,
    this.followersCount,
    this.followingCount,
    this.createdAt,
    this.updatedAt,
    this.isLocal = true,
  });

  final int id;
  final String name;
  final String displayName;
  final String url;
  final String host;
  final List<ActorImage> avatars;
  final String? description;
  final int? userId;
  final int? followersCount;
  final int? followingCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isLocal;

  /// `name@host`, or just `name` for a local account.
  String get handle => host.isEmpty || isLocal ? name : '$name@$host';

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: jsonInt(json['id']),
      name: jsonString(json['name']),
      displayName: jsonString(json['displayName'], jsonString(json['name'])),
      url: jsonString(json['url']),
      host: jsonString(json['host']),
      avatars: parseActorImages(json['avatars']),
      description: jsonStringOrNull(json['description']),
      userId: jsonIntOrNull(json['userId']),
      followersCount: jsonIntOrNull(json['followersCount']),
      followingCount: jsonIntOrNull(json['followingCount']),
      createdAt: jsonDate(json['createdAt']),
      updatedAt: jsonDate(json['updatedAt']),
    );
  }

  static const Account unknown = Account(
    id: 0,
    name: '',
    displayName: '',
    url: '',
    host: '',
    avatars: <ActorImage>[],
  );
}

/// A video channel.
class VideoChannel {
  const VideoChannel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.url,
    required this.host,
    this.avatars = const <ActorImage>[],
    this.banners = const <ActorImage>[],
    this.description,
    this.support,
    this.publicEmail,
    this.ownerAccount,
    this.followersCount,
    this.followingCount,
    this.createdAt,
    this.updatedAt,
    this.isLocal = true,
  });

  final int id;
  final String name;
  final String displayName;
  final String url;
  final String host;
  final List<ActorImage> avatars;
  final List<ActorImage> banners;
  final String? description;
  final String? support;
  final String? publicEmail;
  final Account? ownerAccount;
  final int? followersCount;
  final int? followingCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isLocal;

  String get handle => host.isEmpty || isLocal ? name : '$name@$host';

  factory VideoChannel.fromJson(Map<String, dynamic> json) {
    final owner = json['ownerAccount'];

    return VideoChannel(
      id: jsonInt(json['id']),
      name: jsonString(json['name']),
      displayName: jsonString(json['displayName'], jsonString(json['name'])),
      url: jsonString(json['url']),
      host: jsonString(json['host']),
      avatars: parseActorImages(json['avatars']),
      banners: parseActorImages(json['banners']),
      description: jsonStringOrNull(json['description']),
      support: jsonStringOrNull(json['support']),
      publicEmail: jsonStringOrNull(json['publicEmail']),
      ownerAccount: owner == null ? null : Account.fromJson(jsonMap(owner)),
      followersCount: jsonIntOrNull(json['followersCount']),
      followingCount: jsonIntOrNull(json['followingCount']),
      createdAt: jsonDate(json['createdAt']),
      updatedAt: jsonDate(json['updatedAt']),
    );
  }

  static const VideoChannel unknown = VideoChannel(
    id: 0,
    name: '',
    displayName: '',
    url: '',
    host: '',
  );
}

/// A logged-in (or admin-listed) user.
class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.roleLabel,
    required this.account,
    this.videoChannels = const <VideoChannel>[],
    this.videoQuota = 0,
    this.videoQuotaDaily = 0,
    this.emailVerified = false,
    this.blocked = false,
    this.blockedReason,
    this.blockedAt,
    this.createdAt,
    this.nsfwPolicy = 'display',
    this.autoPlayVideo = false,
    this.autoPlayNextVideo = false,
    this.autoPlayNextVideoPlaylist = false,
    this.videosHistoryEnabled = false,
    this.p2pEnabled = true,
    this.theme,
    this.adminFlags = 0,
    this.notificationSettings,
    this.videoQuotaUsed,
    this.videoQuotaUsedDaily,
  });

  final int id;
  final String username;
  final String email;
  final int role;
  final String roleLabel;
  final Account account;
  final List<VideoChannel> videoChannels;
  final int videoQuota;
  final int videoQuotaDaily;
  final bool emailVerified;
  final bool blocked;
  final String? blockedReason;
  final DateTime? blockedAt;
  final DateTime? createdAt;
  final String nsfwPolicy;
  final bool autoPlayVideo;
  final bool autoPlayNextVideo;
  final bool autoPlayNextVideoPlaylist;
  final bool videosHistoryEnabled;
  final bool p2pEnabled;
  final String? theme;
  final int adminFlags;
  final Map<String, dynamic>? notificationSettings;
  final int? videoQuotaUsed;
  final int? videoQuotaUsedDaily;

  bool get isAdmin => role >= 2;
  bool get isModerator => role >= 1;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: jsonInt(json['id']),
      username: jsonString(json['username']),
      email: jsonString(json['email']),
      role: jsonInt(json['role']),
      roleLabel: jsonString(json['roleLabel']),
      account: Account.fromJson(jsonMap(json['account'])),
      videoChannels: jsonMapList(json['videoChannels'])
          .map(VideoChannel.fromJson)
          .toList(growable: false),
      videoQuota: jsonInt(json['videoQuota']),
      videoQuotaDaily: jsonInt(json['videoQuotaDaily']),
      emailVerified: jsonBool(json['emailVerified']),
      blocked: jsonBool(json['blocked']),
      blockedReason: jsonStringOrNull(json['blockedReason']),
      blockedAt: jsonDate(json['blockedAt']),
      createdAt: jsonDate(json['createdAt']),
      nsfwPolicy: jsonString(json['nsfwPolicy'], 'display'),
      autoPlayVideo: jsonBool(json['autoPlayVideo']),
      autoPlayNextVideo: jsonBool(json['autoPlayNextVideo']),
      autoPlayNextVideoPlaylist: jsonBool(json['autoPlayNextVideoPlaylist']),
      videosHistoryEnabled: jsonBool(json['videosHistoryEnabled']),
      p2pEnabled: jsonBool(json['p2pEnabled'], true),
      theme: jsonStringOrNull(json['theme']),
      adminFlags: jsonInt(json['adminFlags']),
      notificationSettings: json['notificationSettings'] == null
          ? null
          : jsonMap(json['notificationSettings']),
      videoQuotaUsed: jsonIntOrNull(json['videoQuotaUsed']),
      videoQuotaUsedDaily: jsonIntOrNull(json['videoQuotaUsedDaily']),
    );
  }
}
