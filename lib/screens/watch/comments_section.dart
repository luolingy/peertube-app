import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/option_lists.dart';
import '../../data/peertube_api.dart';
import '../../models/actor.dart';
import '../../models/comment.dart';
import '../../router/routes.dart';
import '../../state/paged_list_controller.dart';
import '../../state/session_controller.dart';
import '../../widgets/actor_avatar.dart';
import '../../widgets/state_views.dart';

/// Threaded comments of a video, with posting, replying and moderation.
class CommentsSection extends StatefulWidget {
  const CommentsSection({
    super.key,
    required this.videoId,
    required this.baseUrl,
    this.commentsEnabled = true,
    this.onCountChanged,
  });

  final String videoId;
  final String baseUrl;
  final bool commentsEnabled;
  final ValueChanged<int>? onCountChanged;

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  late final PagedListController<VideoCommentThread> _controller;
  final TextEditingController _input = TextEditingController();

  String _sort = '-createdAt';
  int? _replyToCommentId;
  String? _replyToAuthor;
  bool _posting = false;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _sort = context.read<SessionController>().isLoggedIn
        ? context.read<PeertubeApi>().client.store.commentsSort
        : '-createdAt';

    _controller = PagedListController<VideoCommentThread>(
      pageSize: 20,
      loader: (int start, int count) => context.read<PeertubeApi>().listCommentThreads(
            widget.videoId,
            start: start,
            count: count,
            sort: _sort,
          ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    final api = context.read<PeertubeApi>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _posting = true);

    try {
      if (_replyToCommentId != null) {
        await api.replyToComment(widget.videoId, _replyToCommentId!, text);
      } else {
        await api.createCommentThread(widget.videoId, text);
      }
      _input.clear();
      setState(() {
        _replyToCommentId = null;
        _replyToAuthor = null;
      });
      await _controller.refresh();
      _notifyCount();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('发送失败：$error')));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _notifyCount() {
    final total = _controller.total;
    if (total != _total) {
      _total = total;
      widget.onCountChanged?.call(total);
    }
  }

  Future<void> _delete(VideoComment comment) async {
    final api = context.read<PeertubeApi>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除评论'),
        content: const Text('删除后无法恢复，确定继续吗？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await api.deleteComment(widget.videoId, comment.id);
      await _controller.refresh();
      _notifyCount();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('删除失败：$error')));
    }
  }

  void _startReply(VideoComment comment) {
    setState(() {
      _replyToCommentId = comment.id;
      _replyToAuthor = comment.account.displayName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Row(
            children: <Widget>[
              Text(
                '评论',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text(
                '${_controller.total}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: '排序',
                initialValue: _sort,
                onSelected: (String value) {
                  setState(() => _sort = value);
                  _controller.setLoader(
                    (int start, int count) => context.read<PeertubeApi>().listCommentThreads(
                          widget.videoId,
                          start: start,
                          count: count,
                          sort: value,
                        ),
                  );
                },
                itemBuilder: (BuildContext context) => kCommentSorts
                    .map(
                      (OptionItem option) => PopupMenuItem<String>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
        if (!widget.commentsEnabled)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('该视频已关闭评论。'),
          )
        else if (session.isLoggedIn)
          _buildComposer(session, theme)
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () => context.push(Routes.login),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('登录后发表评论'),
            ),
          ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? _) {
            if (_controller.isInitialLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: LoadingView(),
              );
            }
            if (_controller.error != null && _controller.isEmpty) {
              return ErrorView(error: _controller.error, onRetry: _controller.refresh);
            }
            if (_controller.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: EmptyView(
                  icon: Icons.mode_comment_outlined,
                  title: '还没有评论',
                  subtitle: '来说点什么吧',
                  compact: true,
                ),
              );
            }

            _notifyCount();

            return Column(
              children: <Widget>[
                ..._controller.items.map(
                  (VideoCommentThread thread) => _CommentThreadTile(
                    videoId: widget.videoId,
                    baseUrl: widget.baseUrl,
                    thread: thread,
                    onReply: _startReply,
                    onDelete: _delete,
                  ),
                ),
                if (_controller.hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _controller.isLoadingMore
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : OutlinedButton(
                            onPressed: _controller.loadMore,
                            child: const Text('加载更多评论'),
                          ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildComposer(SessionController session, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_replyToCommentId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '正在回复 ${_replyToAuthor ?? ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _replyToCommentId = null;
                    _replyToAuthor = null;
                  }),
                  child: const Text('取消'),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ActorAvatar(
              images: session.me?.account.avatars ?? const <ActorImage>[],
              baseUrl: widget.baseUrl,
              fallbackLabel: session.me?.account.displayName ?? '?',
              radius: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: _replyToCommentId == null ? '添加评论…' : '回复…',
                  filled: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FilledButton(
                onPressed: _posting ? null : _post,
                child: _posting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('发送'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentThreadTile extends StatefulWidget {
  const _CommentThreadTile({
    required this.videoId,
    required this.baseUrl,
    required this.thread,
    required this.onReply,
    required this.onDelete,
  });

  final String videoId;
  final String baseUrl;
  final VideoCommentThread thread;
  final ValueChanged<VideoComment> onReply;
  final ValueChanged<VideoComment> onDelete;

  @override
  State<_CommentThreadTile> createState() => _CommentThreadTileState();
}

class _CommentThreadTileState extends State<_CommentThreadTile> {
  late List<VideoComment> _replies = widget.thread.children
      .map((VideoCommentThreadTree tree) => tree.comment)
      .toList(growable: true);
  bool _expanded = true;
  bool _loadingReplies = false;
  int _loadedReplies = 0;

  Future<void> _loadMoreReplies() async {
    setState(() => _loadingReplies = true);
    try {
      final page = await context.read<PeertubeApi>().listCommentReplies(
            widget.videoId,
            widget.thread.comment.id,
            start: _replies.length,
            count: 20,
          );
      setState(() {
        _replies = <VideoComment>[..._replies, ...page.data];
        _loadedReplies = page.total;
      });
    } catch (_) {
      // Ignored: the button simply stays available.
    } finally {
      if (mounted) setState(() => _loadingReplies = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalReplies = widget.thread.comment.totalReplies;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _CommentTile(
            comment: widget.thread.comment,
            baseUrl: widget.baseUrl,
            onReply: widget.onReply,
            onDelete: widget.onDelete,
          ),
          if (_replies.isNotEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Column(
                children: _replies
                    .map(
                      (VideoComment reply) => _CommentTile(
                        comment: reply,
                        baseUrl: widget.baseUrl,
                        isReply: true,
                        onReply: widget.onReply,
                        onDelete: widget.onDelete,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          if (totalReplies > _replies.length || _loadedReplies > _replies.length)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: TextButton.icon(
                onPressed: _loadingReplies ? null : _loadMoreReplies,
                icon: _loadingReplies
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded, size: 18),
                label: Text('查看其余 ${totalReplies - _replies.length} 条回复'),
              ),
            )
          else if (_replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? '收起回复' : '展开 ${_replies.length} 条回复'),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.baseUrl,
    required this.onReply,
    required this.onDelete,
    this.isReply = false,
  });

  final VideoComment comment;
  final String baseUrl;
  final ValueChanged<VideoComment> onReply;
  final ValueChanged<VideoComment> onDelete;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.watch<SessionController>();
    final canDelete = session.isLoggedIn &&
        (session.myAccount?.id == comment.account.id || session.isModerator);

    return Padding(
      padding: EdgeInsets.only(bottom: isReply ? 6 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ActorAvatar(
            images: comment.account.avatars,
            baseUrl: baseUrl,
            fallbackLabel: comment.account.displayName,
            radius: isReply ? 15 : 18,
            onTap: () => context.push(Routes.accountByHandle(comment.account.handle)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        comment.account.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatRelativeTime(comment.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    if (comment.isHeldForReview)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '待审核',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (comment.isEffectivelyDeleted)
                  Text(
                    '该评论已被删除',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.outline,
                    ),
                  )
                else
                  SelectableText(
                    comment.text,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    TextButton(
                      onPressed: session.isLoggedIn
                          ? () => onReply(comment)
                          : () => context.push(Routes.login),
                      child: const Text('回复'),
                    ),
                    if (canDelete)
                      TextButton(
                        onPressed: () => onDelete(comment),
                        child: const Text('删除'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
