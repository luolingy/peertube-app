import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../data/peertube_api.dart';
import '../../models/misc.dart';
import '../../router/routes.dart';
import '../../state/notifications_controller.dart';
import '../../state/paged_list_controller.dart';
import '../../widgets/state_views.dart';

/// The notification centre.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final PagedListController<UserNotification> _controller;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _controller = PagedListController<UserNotification>(loader: _loader());
    WidgetsBinding.instance.addPostFrameCallback((_) => _markVisibleAsRead());
  }

  PageLoader<UserNotification> _loader() {
    return (int start, int count) => context.read<PeertubeApi>().listNotifications(
          start: start,
          count: count,
          sort: '-createdAt',
          unread: _unreadOnly ? true : null,
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markVisibleAsRead() async {
    final ids = _controller.items
        .where((UserNotification notification) => !notification.read)
        .map((UserNotification notification) => notification.id)
        .toList(growable: false);
    if (ids.isEmpty) return;

    try {
      await context.read<PeertubeApi>().markNotificationsAsRead(ids);
      _controller.updateWhere(
        (UserNotification notification) => ids.contains(notification.id),
        (UserNotification notification) => _asRead(notification),
      );
      if (mounted) context.read<NotificationsController>().refresh();
    } catch (_) {
      // Ignored.
    }
  }

  /// Rebuilds a notification as read (the model is immutable).
  UserNotification _asRead(UserNotification notification) {
    return UserNotification(
      id: notification.id,
      type: notification.type,
      read: true,
      createdAt: notification.createdAt,
      updatedAt: notification.updatedAt,
      comment: notification.comment,
      video: notification.video,
      videoImport: notification.videoImport,
      abuse: notification.abuse,
      account: notification.account,
      videoChannel: notification.videoChannel,
      commentId: notification.commentId,
      videoId: notification.videoId,
      abuseId: notification.abuseId,
      accountId: notification.accountId,
      videoChannelId: notification.videoChannelId,
      videoImportId: notification.videoImportId,
    );
  }

  Future<void> _markAllRead() async {
    try {
      await context.read<PeertubeApi>().markAllNotificationsAsRead();
      await _controller.refresh();
      if (mounted) context.read<NotificationsController>().clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败：$error')));
      }
    }
  }

  void _open(UserNotification notification) {
    final video = notification.video;
    if (video != null) {
      context.push(Routes.watchVideo(video.shortUUID));
      return;
    }
    if (notification.videoChannel != null) {
      context.push(Routes.channelByHandle(notification.videoChannel!.handle));
      return;
    }
    if (notification.account != null) {
      context.push(Routes.accountByHandle(notification.account!.handle));
      return;
    }
    if (notification.abuseId != null) {
      context.push(Routes.myAbuses);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        actions: <Widget>[
          IconButton(
            tooltip: _unreadOnly ? '显示全部' : '只看未读',
            onPressed: () {
              setState(() => _unreadOnly = !_unreadOnly);
              _controller.setLoader(_loader());
            },
            icon: Icon(_unreadOnly ? Icons.mark_email_unread_rounded : Icons.filter_alt_outlined),
          ),
          IconButton(
            tooltip: '全部标记为已读',
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          if (_controller.isInitialLoading) return const LoadingView();
          if (_controller.error != null && _controller.isEmpty) {
            return ErrorView(error: _controller.error, onRetry: _controller.refresh);
          }
          if (_controller.isEmpty) {
            return EmptyView(
              icon: Icons.notifications_none_rounded,
              title: _unreadOnly ? '没有未读通知' : '还没有通知',
              subtitle: '订阅的频道发布新视频时会通知你',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _controller.refresh();
              await _markVisibleAsRead();
            },
            child: ListView.separated(
              itemCount: _controller.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final notification = _controller.items[index];
                return ListTile(
                  leading: Icon(
                    notification.read
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                    color: notification.read
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(notification.description),
                  subtitle: Text(
                    <String>[
                      if (notification.video != null) notification.video!.name,
                      formatRelativeTime(notification.createdAt),
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _open(notification),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
