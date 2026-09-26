import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/peertube_api.dart';
import '../../models/actor.dart';
import '../../models/paged.dart';
import '../../models/video.dart';
import '../../router/routes.dart';
import '../../state/config_controller.dart';
import '../../state/notifications_controller.dart';
import '../../state/paged_list_controller.dart';
import '../../state/session_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/actor_avatar.dart';
import '../../widgets/state_views.dart';
import '../../widgets/video_cards.dart';

/// The landing screen: trending, latest, live and the subscription feed.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  PagedListController<Video>? _trending;
  PagedListController<Video>? _recent;
  PagedListController<Video>? _live;
  PagedListController<Video>? _subscriptions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _build());
  }

  void _build() {
    if (!mounted || _trending != null) return;

    final api = context.read<PeertubeApi>();
    final settings = context.read<SettingsController>();
    final session = context.read<SessionController>();

    setState(() {
      _trending = PagedListController<Video>(
        loader: (int start, int count) => api.listVideos(
          start: start,
          count: count,
          sort: '-trending',
          isLocal: settings.defaultScope == 'local',
        ),
      );
      _recent = PagedListController<Video>(
        loader: (int start, int count) => api.listVideos(
          start: start,
          count: count,
          sort: '-publishedAt',
          isLocal: settings.defaultScope == 'local',
        ),
      );
      _live = PagedListController<Video>(
        loader: (int start, int count) => api.listVideos(
          start: start,
          count: count,
          sort: '-publishedAt',
          isLive: true,
          includeScheduledLive: false,
          isLocal: settings.defaultScope == 'local',
        ),
      );
      _subscriptions = PagedListController<Video>(
        loader: (int start, int count) => session.isLoggedIn
            ? api.listSubscriptionVideos(start: start, count: count, sort: '-publishedAt')
            : Future<PagedResult<Video>>.value(
                const PagedResult<Video>(total: 0, data: <Video>[]),
              ),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trending?.dispose();
    _recent?.dispose();
    _live?.dispose();
    _subscriptions?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigController>();
    final api = context.read<PeertubeApi>();
    final session = context.watch<SessionController>();
    final unread = context.watch<NotificationsController>().unreadCount;
    final baseUrl = api.client.baseUrl;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: <Widget>[
            if (config.logoUrl != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ActorAvatar(
                  images: <ActorImage>[],
                  baseUrl: baseUrl,
                  fallbackLabel: config.instanceName,
                  radius: 14,
                ),
              ),
            Flexible(
              child: Text(
                config.instanceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: '搜索',
            onPressed: () => context.go(Routes.search),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: '通知',
            onPressed: () {
              if (!session.isLoggedIn) {
                context.push(Routes.login);
              } else {
                context.push(Routes.notifications);
              }
            },
            icon: unread > 0
                ? Badge.count(count: unread, child: const Icon(Icons.notifications_none_rounded))
                : const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: '上传',
            onPressed: () {
              if (!session.isLoggedIn) {
                context.push(Routes.login);
              } else {
                context.push(Routes.upload);
              }
            },
            icon: const Icon(Icons.video_call_outlined),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const <Widget>[
            Tab(text: '推荐'),
            Tab(text: '最新'),
            Tab(text: '直播'),
            Tab(text: '订阅'),
          ],
        ),
      ),
      body: _trending == null
          ? const LoadingView()
          : TabBarView(
              controller: _tabController,
              children: <Widget>[
                VideoGrid(
                  controller: _trending!,
                  baseUrl: baseUrl,
                  emptyTitle: '暂时没有推荐视频',
                ),
                VideoGrid(
                  controller: _recent!,
                  baseUrl: baseUrl,
                  emptyTitle: '暂时没有视频',
                ),
                VideoGrid(
                  controller: _live!,
                  baseUrl: baseUrl,
                  emptyTitle: '当前没有直播',
                  emptySubtitle: '稍后再来看看吧',
                ),
                session.isLoggedIn
                    ? VideoGrid(
                        controller: _subscriptions!,
                        baseUrl: baseUrl,
                        emptyTitle: '还没有订阅任何频道',
                        emptySubtitle: '去发现页找找感兴趣的内容',
                        emptyAction: FilledButton(
                          onPressed: () => context.go(Routes.browse),
                          child: const Text('去发现'),
                        ),
                      )
                    : EmptyView(
                        icon: Icons.lock_outline_rounded,
                        title: '登录后查看订阅',
                        subtitle: '订阅的频道有新视频时会出现在这里',
                        action: FilledButton(
                          onPressed: () => context.push(Routes.login),
                          child: const Text('登录'),
                        ),
                      ),
              ],
            ),
    );
  }
}
