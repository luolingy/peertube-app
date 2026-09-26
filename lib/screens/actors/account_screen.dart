import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/formatters.dart';
import '../../data/peertube_api.dart';
import '../../models/actor.dart';
import '../../models/playlist.dart';
import '../../models/video.dart';
import '../../state/paged_list_controller.dart';
import '../../state/session_controller.dart';
import '../../widgets/action_buttons.dart';
import '../../widgets/actor_avatar.dart';
import '../../widgets/actor_tiles.dart';
import '../../widgets/markdown_text.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/state_views.dart';
import '../../widgets/video_cards.dart';

/// An account page: its channels, videos, playlists and about.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.handle});

  final String handle;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Account? _account;
  Object? _error;
  bool _loading = true;

  PagedListController<VideoChannel>? _channels;
  PagedListController<Video>? _videos;
  PagedListController<VideoPlaylist>? _playlists;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handle != widget.handle) {
      _channels?.dispose();
      _videos?.dispose();
      _playlists?.dispose();
      _channels = null;
      _videos = null;
      _playlists = null;
      _load();
    }
  }

  @override
  void dispose() {
    _channels?.dispose();
    _videos?.dispose();
    _playlists?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<PeertubeApi>();
      final account = await api.getAccount(widget.handle);
      if (!mounted) return;

      setState(() {
        _account = account;
        _loading = false;
        _channels = PagedListController<VideoChannel>(
          loader: (int start, int count) => api.listAccountChannels(
            account.handle,
            start: start,
            count: count,
          ),
        );
        _videos = PagedListController<Video>(
          loader: (int start, int count) => api.listAccountVideos(
            account.handle,
            start: start,
            count: count,
            sort: '-publishedAt',
          ),
        );
        _playlists = PagedListController<VideoPlaylist>(
          loader: (int start, int count) => api.listAccountPlaylists(
            account.handle,
            start: start,
            count: count,
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const LoadingView());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.handle)),
        body: ErrorView(error: _error, onRetry: _load),
      );
    }

    final account = _account!;
    final api = context.read<PeertubeApi>();
    final baseUrl = api.client.baseUrl;
    final session = context.watch<SessionController>();
    final isMe = session.myAccount?.id == account.id;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) => <Widget>[
            SliverAppBar(
              pinned: true,
              expandedHeight: 190,
              flexibleSpace: FlexibleSpaceBar(
                background: _AccountHeader(
                  account: account,
                  baseUrl: baseUrl,
                  showFollow: !isMe,
                ),
              ),
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: <Widget>[
                  Tab(text: '频道'),
                  Tab(text: '视频'),
                  Tab(text: '播放列表'),
                  Tab(text: '关于'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: <Widget>[
              _channels == null
                  ? const LoadingView()
                  : PagedListView<VideoChannel>(
                      controller: _channels!,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      emptyTitle: '该账号还没有频道',
                      emptyIcon: Icons.tv_off_rounded,
                      itemBuilder: (BuildContext context, VideoChannel channel, int index) =>
                          ChannelListTile(channel: channel, baseUrl: baseUrl),
                    ),
              _videos == null
                  ? const LoadingView()
                  : VideoGrid(
                      controller: _videos!,
                      baseUrl: baseUrl,
                      emptyTitle: '该账号还没有视频',
                    ),
              _playlists == null
                  ? const LoadingView()
                  : PagedListView<VideoPlaylist>(
                      controller: _playlists!,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      emptyTitle: '该账号还没有播放列表',
                      emptyIcon: Icons.playlist_play_rounded,
                      itemBuilder: (BuildContext context, VideoPlaylist playlist, int index) =>
                          PlaylistListTile(playlist: playlist, baseUrl: baseUrl),
                    ),
              ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '简介',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          if ((account.description ?? '').trim().isEmpty)
                            const Text('该账号还没有填写简介。')
                          else
                            MarkdownText(data: account.description!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.alternate_email_rounded),
                          title: const Text('账号标识'),
                          subtitle: Text(account.handle),
                        ),
                        ListTile(
                          leading: const Icon(Icons.public_rounded),
                          title: const Text('来源'),
                          subtitle: Text(account.host.isEmpty ? '本站' : account.host),
                        ),
                        ListTile(
                          leading: const Icon(Icons.people_outline_rounded),
                          title: const Text('关注者'),
                          subtitle: Text('${formatCount(account.followersCount)}'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.calendar_today_rounded),
                          title: const Text('创建于'),
                          subtitle: Text(formatDate(account.createdAt)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({
    required this.account,
    required this.baseUrl,
    required this.showFollow,
  });

  final Account account;
  final String baseUrl;
  final bool showFollow;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 48),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            ActorAvatar(
              images: account.avatars,
              baseUrl: baseUrl,
              fallbackLabel: account.displayName,
              radius: 34,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    account.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '@${account.handle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (showFollow) SubscribeButton(uri: account.handle),
          ],
        ),
      ),
    );
  }
}
