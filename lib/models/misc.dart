import 'actor.dart';
import 'comment.dart';
import 'json_utils.dart';
import 'video.dart';

/// A server notification (`/users/me/notifications`).
class UserNotification {
  const UserNotification({
    required this.id,
    required this.type,
    required this.read,
    this.createdAt,
    this.updatedAt,
    this.comment,
    this.video,
    this.videoImport,
    this.abuse,
    this.account,
    this.videoChannel,
    this.commentId,
    this.videoId,
    this.abuseId,
    this.accountId,
    this.videoChannelId,
    this.videoImportId,
  });

  final int id;
  final String type;
  final bool read;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final VideoComment? comment;
  final Video? video;
  final VideoImport? videoImport;
  final Abuse? abuse;
  final Account? account;
  final VideoChannel? videoChannel;
  final int? commentId;
  final int? videoId;
  final int? abuseId;
  final int? accountId;
  final int? videoChannelId;
  final int? videoImportId;

  /// A short human readable sentence for the notification.
  String get description {
    switch (type) {
      case 'new_video_from_subscription':
        return '订阅的频道发布了新视频';
      case 'new_comment_on_video':
        return '你的视频收到了新评论';
      case 'new_video_from_import':
        return '视频导入完成';
      case 'new_follower_on_account':
        return '你有新的关注者';
      case 'new_follower_on_channel':
        return '你的频道有新的关注者';
      case 'video_import_failed':
        return '视频导入失败';
      case 'video_auto_blacklist':
        return '你的视频被自动屏蔽';
      case 'video_unblacklisted':
        return '你的视频已解除屏蔽';
      case 'video_unpublished':
        return '你的视频已被下架';
      case 'video_ownership_changed':
        return '视频所有权发生变更';
      case 'new_abuse_for_my_videos':
        return '你的视频被举报';
      case 'new_abuse_for_my_account':
        return '你的账号被举报';
      case 'new_abuse_state_comment':
        return '举报状态已更新';
      case 'comment_mention':
        return '有人在评论中提到了你';
      case 'new_video_from_subscription_live':
        return '订阅的频道正在直播';
      default:
        return type;
    }
  }

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    VideoComment? comment;
    if (json['comment'] != null) {
      comment = VideoComment.fromJson(jsonMap(json['comment']));
    }
    Video? video;
    if (json['video'] != null) {
      video = Video.fromJson(jsonMap(json['video']));
    }
    VideoImport? videoImport;
    if (json['videoImport'] != null) {
      videoImport = VideoImport.fromJson(jsonMap(json['videoImport']));
    }
    Abuse? abuse;
    if (json['abuse'] != null) {
      abuse = Abuse.fromJson(jsonMap(json['abuse']));
    }
    Account? account;
    if (json['account'] != null) {
      account = Account.fromJson(jsonMap(json['account']));
    }
    VideoChannel? channel;
    if (json['videoChannel'] != null) {
      channel = VideoChannel.fromJson(jsonMap(json['videoChannel']));
    }

    return UserNotification(
      id: jsonInt(json['id']),
      type: jsonString(json['type']),
      read: jsonBool(json['read']),
      createdAt: jsonDate(json['createdAt']),
      updatedAt: jsonDate(json['updatedAt']),
      comment: comment,
      video: video,
      videoImport: videoImport,
      abuse: abuse,
      account: account,
      videoChannel: channel,
      commentId: jsonIntOrNull(json['commentId']),
      videoId: jsonIntOrNull(json['videoId']),
      abuseId: jsonIntOrNull(json['abuseId']),
      accountId: jsonIntOrNull(json['accountId']),
      videoChannelId: jsonIntOrNull(json['videoChannelId']),
      videoImportId: jsonIntOrNull(json['videoImportId']),
    );
  }
}

/// A video import job (`/videos/imports`).
class VideoImport {
  const VideoImport({
    required this.id,
    required this.state,
    this.video,
    this.magnetUri,
    this.torrentName,
    this.targetUrl,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final VideoConstant state;
  final Video? video;
  final String? magnetUri;
  final String? torrentName;
  final String? targetUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get sourceLabel {
    final url = targetUrl;
    if (url != null && url.isNotEmpty) return url;
    final magnet = magnetUri;
    if (magnet != null && magnet.isNotEmpty) return magnet;
    return torrentName ?? '';
  }

  factory VideoImport.fromJson(Map<String, dynamic> json) {
    Video? video;
    if (json['video'] != null) {
      video = Video.fromJson(jsonMap(json['video']));
    }

    return VideoImport(
      id: jsonInt(json['id']),
      state: VideoConstant.fromJson(jsonMap(json['state'])),
      video: video,
      magnetUri: jsonStringOrNull(json['magnetUri']),
      torrentName: jsonStringOrNull(json['torrentName']),
      targetUrl: jsonStringOrNull(json['targetUrl']),
      createdAt: jsonDate(json['createdAt']),
      updatedAt: jsonDate(json['updatedAt']),
    );
  }
}

/// A moderation report (`/abuses`).
class Abuse {
  const Abuse({
    required this.id,
    required this.state,
    required this.reason,
    this.moderationComment,
    this.video,
    this.account,
    this.reporterAccount,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final VideoConstant state;
  final String reason;
  final String? moderationComment;
  final Video? video;
  final Account? account;
  final Account? reporterAccount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get reasonLabel {
    switch (reason) {
      case '1':
      case 'sex':
        return '色情内容';
      case '2':
      case 'violence':
        return '暴力内容';
      case '3':
      case 'hate_speech':
        return '仇恨言论';
      case '4':
      case 'copyright':
        return '侵犯版权';
      case '5':
      case 'spam':
        return '垃圾内容';
      default:
        return '其他';
    }
  }

  factory Abuse.fromJson(Map<String, dynamic> json) {
    Video? video;
    if (json['video'] != null) {
      video = Video.fromJson(jsonMap(json['video']));
    }
    Account? account;
    if (json['account'] != null) {
      account = Account.fromJson(jsonMap(json['account']));
    }
    Account? reporter;
    if (json['reporterAccount'] != null) {
      reporter = Account.fromJson(jsonMap(json['reporterAccount']));
    }

    return Abuse(
      id: jsonInt(json['id']),
      state: VideoConstant.fromJson(jsonMap(json['state'])),
      reason: jsonString(json['reason']),
      moderationComment: jsonStringOrNull(json['moderationComment']),
      video: video,
      account: account,
      reporterAccount: reporter,
      createdAt: jsonDate(json['createdAt']),
      updatedAt: jsonDate(json['updatedAt']),
    );
  }
}

/// A background job (`/jobs`).
class Job {
  const Job({
    required this.id,
    required this.state,
    required this.type,
    this.progress = 0,
    this.priority = 0,
    this.createdAt,
    this.processedOn,
    this.finishedOn,
    this.data = const <String, dynamic>{},
    this.error,
  });

  final String id;
  final String state;
  final String type;
  final int progress;
  final int priority;
  final DateTime? createdAt;
  final DateTime? processedOn;
  final DateTime? finishedOn;
  final Map<String, dynamic> data;
  final String? error;

  bool get isFailed => state == 'failed';

  factory Job.fromJson(Map<String, dynamic> json) {
    final error = json['error'];
    return Job(
      id: jsonString(json['id']),
      state: jsonString(json['state']),
      type: jsonString(json['type']),
      progress: jsonInt(json['progress']),
      priority: jsonInt(json['priority']),
      createdAt: jsonDate(json['createdAt']),
      processedOn: jsonDate(json['processedOn']),
      finishedOn: jsonDate(json['finishedOn']),
      data: jsonMap(json['data']),
      error: error == null ? null : jsonString(error),
    );
  }
}

/// A federated follow relationship (`/server/following`, `/server/followers`,
/// `/accounts/:handle/followers`, ...).
class ActorFollow {
  const ActorFollow({
    required this.id,
    required this.state,
    required this.follower,
    required this.following,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final VideoConstant state;
  final ActorRef follower;
  final ActorRef following;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ActorFollow.fromJson(Map<String, dynamic> json) {
    return ActorFollow(
      id: jsonInt(json['id']),
      state: VideoConstant.fromJson(jsonMap(json['state'])),
      follower: ActorRef.fromJson(jsonMap(json['follower'])),
      following: ActorRef.fromJson(jsonMap(json['following'])),
      createdAt: jsonDate(json['createdAt']),
      updatedAt: jsonDate(json['updatedAt']),
    );
  }
}

/// A lightweight `{ host, name, url }` actor reference.
class ActorRef {
  const ActorRef({required this.host, required this.name, required this.url});

  final String host;
  final String name;
  final String url;

  String get handle => host.isEmpty ? name : '$name@$host';

  factory ActorRef.fromJson(Map<String, dynamic> json) {
    return ActorRef(
      host: jsonString(json['host']),
      name: jsonString(json['name']),
      url: jsonString(json['url']),
    );
  }
}

/// Instance statistics (`/server/stats`).
class ServerStats {
  const ServerStats({
    this.totalUsers = 0,
    this.totalVideos = 0,
    this.totalVideoComments = 0,
    this.totalVideoFiles = 0,
    this.totalLocalVideos = 0,
    this.totalLocalVideoFiles = 0,
    this.totalLocalVideoViews = 0,
    this.totalInstanceFollowers = 0,
    this.totalInstanceFollowing = 0,
    this.totalVideosSize = 0,
    this.raw = const <String, dynamic>{},
  });

  final int totalUsers;
  final int totalVideos;
  final int totalVideoComments;
  final int totalVideoFiles;
  final int totalLocalVideos;
  final int totalLocalVideoFiles;
  final int totalLocalVideoViews;
  final int totalInstanceFollowers;
  final int totalInstanceFollowing;
  final int totalVideosSize;
  final Map<String, dynamic> raw;

  factory ServerStats.fromJson(Map<String, dynamic> json) {
    return ServerStats(
      totalUsers: jsonInt(json['totalUsers']),
      totalVideos: jsonInt(json['totalVideos']),
      totalVideoComments: jsonInt(json['totalVideoComments']),
      totalVideoFiles: jsonInt(json['totalVideoFiles']),
      totalLocalVideos: jsonInt(json['totalLocalVideos']),
      totalLocalVideoFiles: jsonInt(json['totalLocalVideoFiles']),
      totalLocalVideoViews: jsonInt(json['totalLocalVideoViews']),
      totalInstanceFollowers: jsonInt(json['totalInstanceFollowers']),
      totalInstanceFollowing: jsonInt(json['totalInstanceFollowing']),
      totalVideosSize: jsonInt(json['totalVideosSize']),
      raw: json,
    );
  }
}

/// An installed plugin/theme (`/plugins`).
class Plugin {
  const Plugin({
    required this.name,
    required this.npmName,
    required this.version,
    required this.description,
    required this.enabled,
    required this.uninstalled,
    this.pluginType = '1',
    this.latestVersion,
  });

  final String name;
  final String npmName;
  final String version;
  final String description;
  final bool enabled;
  final bool uninstalled;
  final String pluginType;
  final String? latestVersion;

  bool get isTheme => pluginType == '2';

  factory Plugin.fromJson(Map<String, dynamic> json) {
    return Plugin(
      name: jsonString(json['name']),
      npmName: jsonString(json['npmName']),
      version: jsonString(json['version']),
      description: jsonString(json['description']),
      enabled: jsonBool(json['enabled'], true),
      uninstalled: jsonBool(json['uninstalled']),
      pluginType: jsonString(json['pluginType'], '1'),
      latestVersion: jsonStringOrNull(json['latestVersion']),
    );
  }
}

/// One line of the server log (`/server/logs`).
class LogLine {
  const LogLine({
    required this.timestamp,
    required this.level,
    required this.message,
    this.meta,
  });

  final String timestamp;
  final String level;
  final String message;
  final String? meta;

  factory LogLine.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'];
    return LogLine(
      timestamp: jsonString(json['timestamp']),
      level: jsonString(json['level']),
      message: jsonString(json['message']),
      meta: meta == null ? null : jsonString(meta),
    );
  }
}
