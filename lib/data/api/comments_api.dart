import 'package:dio/dio.dart';

import '../../models/comment.dart';
import '../../models/json_utils.dart';
import '../../models/paged.dart';
import '../api_section.dart';

/// Everything under `/videos/:videoId/comments` and `comment-threads`.
mixin CommentsApi on ApiSection {
  /// `GET /videos/:videoId/comment-threads` — threaded comments.
  Future<PagedResult<VideoCommentThread>> listCommentThreads(
    String videoId, {
    int start = 0,
    int count = 20,
    String? sort,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/videos/$videoId/comment-threads',
      cancelToken: cancelToken,
      query: <String, dynamic>{'start': start, 'count': count, 'sort': sort},
    );
    return PagedResult<VideoCommentThread>.fromJson(data, VideoCommentThread.fromJson);
  }

  /// `GET /videos/:videoId/comment-threads/:threadId`.
  Future<VideoCommentThread> getCommentThread(String videoId, int threadId) async {
    final data = await client.get('/videos/$videoId/comment-threads/$threadId');
    return VideoCommentThread.fromJson(jsonMap(data));
  }

  /// `GET /videos/:videoId/comments` — flat list (used by moderation views).
  Future<PagedResult<VideoComment>> listComments(
    String videoId, {
    int start = 0,
    int count = 20,
    String? sort,
  }) async {
    final data = await client.get(
      '/videos/$videoId/comments',
      query: <String, dynamic>{'start': start, 'count': count, 'sort': sort},
    );
    return PagedResult<VideoComment>.fromJson(data, VideoComment.fromJson);
  }

  /// `GET /videos/:videoId/comments/:commentId/replies`.
  Future<PagedResult<VideoComment>> listCommentReplies(
    String videoId,
    int commentId, {
    int start = 0,
    int count = 20,
    CancelToken? cancelToken,
  }) async {
    final data = await client.get(
      '/videos/$videoId/comments/$commentId/replies',
      cancelToken: cancelToken,
      query: <String, dynamic>{'start': start, 'count': count},
    );
    return PagedResult<VideoComment>.fromJson(data, VideoComment.fromJson);
  }

  /// `POST /videos/:videoId/comment-threads` — creates a top level comment.
  Future<VideoComment> createCommentThread(
    String videoId,
    String text, {
    bool isSensitive = false,
  }) async {
    final data = await client.post(
      '/videos/$videoId/comment-threads',
      data: <String, dynamic>{'text': text, 'isSensitive': isSensitive},
    );
    return VideoComment.fromJson(jsonMap(jsonMap(data)['comment']));
  }

  /// `POST /videos/:videoId/comments/:commentId` — replies to a comment.
  Future<VideoComment> replyToComment(
    String videoId,
    int commentId,
    String text, {
    bool isSensitive = false,
  }) async {
    final data = await client.post(
      '/videos/$videoId/comments/$commentId',
      data: <String, dynamic>{'text': text, 'isSensitive': isSensitive},
    );
    return VideoComment.fromJson(jsonMap(jsonMap(data)['comment']));
  }

  /// `DELETE /videos/:videoId/comments/:commentId`.
  Future<void> deleteComment(String videoId, int commentId) async {
    await client.delete('/videos/$videoId/comments/$commentId');
  }

  /// `POST /videos/:videoId/comments/:commentId/approve`.
  Future<void> approveComment(String videoId, int commentId) async {
    await client.post('/videos/$videoId/comments/$commentId/approve');
  }
}
