import 'actor.dart';
import 'json_utils.dart';

/// A comment or a reply.
class VideoComment {
  const VideoComment({
    required this.id,
    required this.text,
    required this.threadId,
    required this.videoId,
    required this.account,
    this.url,
    this.inReplyToCommentId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isDeleted = false,
    this.isHeldForReview = false,
    this.totalReplies = 0,
    this.isLocal = true,
    this.originComment,
  });

  final int id;
  final String text;
  final int threadId;
  final String videoId;
  final Account account;
  final String? url;
  final int? inReplyToCommentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isDeleted;
  final bool isHeldForReview;
  final int totalReplies;
  final bool isLocal;
  final VideoComment? originComment;

  bool get isEffectivelyDeleted => isDeleted || deletedAt != null;
  bool get isReply => inReplyToCommentId != null;

  factory VideoComment.fromJson(Map<String, dynamic> json) {
    final origin = json['originComment'];

    return VideoComment(
      id: jsonInt(json['id']),
      text: jsonString(json['text']),
      threadId: jsonInt(json['threadId']),
      videoId: jsonString(json['videoId']),
      account: Account.fromJson(jsonMap(json['account'])),
      url: jsonStringOrNull(json['url']),
      inReplyToCommentId: jsonIntOrNull(json['inReplyToCommentId']),
      createdAt: jsonDate(json['createdAt']),
      updatedAt: jsonDate(json['updatedAt']),
      deletedAt: jsonDate(json['deletedAt']),
      isDeleted: jsonBool(json['isDeleted']),
      isHeldForReview: jsonBool(json['isHeldForReview']),
      totalReplies: jsonInt(json['totalReplies']),
      isLocal: jsonBool(json['isLocal'], true),
      originComment: origin == null ? null : VideoComment.fromJson(jsonMap(origin)),
    );
  }
}

/// `{ comment, children }` recursive tree returned by `/comment-threads`.
class VideoCommentThreadTree {
  const VideoCommentThreadTree({required this.comment, this.children = const []});

  final VideoComment comment;
  final List<VideoCommentThreadTree> children;

  factory VideoCommentThreadTree.fromJson(Map<String, dynamic> json) {
    return VideoCommentThreadTree(
      comment: VideoComment.fromJson(jsonMap(json['comment'])),
      children: jsonMapList(json['children'])
          .map(VideoCommentThreadTree.fromJson)
          .toList(growable: false),
    );
  }
}

/// `PagedResult<VideoCommentThreadTree>` companion: threads carry both the
/// comment and the total number of replies.
class VideoCommentThread {
  const VideoCommentThread({required this.comment, this.children = const []});

  final VideoComment comment;
  final List<VideoCommentThreadTree> children;

  factory VideoCommentThread.fromJson(Map<String, dynamic> json) {
    return VideoCommentThread(
      comment: VideoComment.fromJson(jsonMap(json['comment'])),
      children: jsonMapList(json['children'])
          .map(VideoCommentThreadTree.fromJson)
          .toList(growable: false),
    );
  }
}
