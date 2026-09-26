import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/option_lists.dart';
import '../../data/peertube_api.dart';
import '../../models/actor.dart';
import '../../models/playlist.dart';
import '../../models/video.dart';
import '../../router/routes.dart';
import '../../state/paged_list_controller.dart';
import '../../state/session_controller.dart';
import '../../widgets/action_buttons.dart';
import '../../widgets/actor_avatar.dart';
import '../../widgets/actor_tiles.dart';
import '../../widgets/markdown_text.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/state_views.dart';
import '../../widgets/video_cards.dart';

/// A video channel page: videos, playlists and about.
class ChannelScreen extends StatefulWidget {
  const ChannelScreen({super.key, required this.handle});

  final String handle;

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  VideoChannel? _channel;
  Object? _error;
  bool _loading = true;

  PagedListController<Video>? _videos;
  PagedListController<VideoPlaylist>? _playlists;

  String _sort = '-publishedAt';
  bool _liveOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ChannelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handle != widget.handle) {
      _videos?.dispose();
      _playlists?.dispose();
      _videos = null;
      _playlists = null;
      _load();
    }
  }

  @override
  void dispose() {
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
      final channel = await context.read<PeertubeApi>().getChannel(widget.handle);
      if (!mounted) return;

      setState(() {
        _channel = channel;
        _loading = false;
        _videos = PagedListController<Video>(loader: _videoLoader());
        _playlists = PagedListController<VideoPlaylist>(
          loader: (int start, int count) => context.read<PeertubeApi>().listChannelPlaylists(
                channel.handle,
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

  PageLoader<Video> _videoLoader() {
    return (int start, int count) => context.read<PeertubeApi>().listChannelVideos(
          _channel?.handle ?? widget.handle,
          start: start,
          count: count,
          sort: _sort,
          isLive: _liveOnly ? true : null,
        );
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

    final channel = _channel!;
    final api = context.read<PeertubeApi>();
    final baseUrl = api.client.baseUrl;
    final session = context.watch<SessionController>();
    final isOwner = session.myChannels.any((VideoChannel c) => c.id == channel.id);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) => <Widget>[
            SliverAppBar(
              pinned: true,
              expandedHeight: 220,
              actions: <Widget>[
                if (isOwner)
                  IconButton(
                    tooltip: '编辑频道',
                    onPressed: () => context.push(Routes.editChannel(channel.handle)),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _ChannelHeader(
                  channel: channel,
                  baseUrl: baseUrl,
                  showSubscribe: !isOwner,
                ),
              ),
              bottom: const TabBar(
                tabs: <Widget>[
                  Tab(text: '视频'),
                  Tab(text: '播放列表'),
                  Tab(text: '关于'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: <Widget>[
              _videos == null
                  ? const LoadingView()
                  : VideoGrid(
                      controller: _videos!,
                      baseUrl: baseUrl,
                      emptyTitle: '该频道还没有视频',
                      header: _buildVideoHeader(),
                    ),
              _playlists == null
                  ? const LoadingView()
                  : PagedListView<VideoPlaylist>(
                      controller: _playlists!,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      emptyTitle: '该频道还没有播放列表',
                      emptyIcon: Icons.playlist_play_rounded,
                      itemBuilder: (BuildContext context, VideoPlaylist playlist, int index) =>
                          PlaylistListTile(playlist: playlist, baseUrl: baseUrl),
                    ),
              _ChannelAbout(channel: channel, baseUrl: baseUrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: <Widget>[
          ActionChip(
            avatar: const Icon(Icons.sort_rounded, size: 16),
            label: Text(_sortLabel()),
            onPressed: _pickSort,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('仅直播'),
            selected: _liveOnly,
            onSelected: (bool value) {
              setState(() => _liveOnly = value);
              _videos?.setLoader(_videoLoader());
            },
          ),
        ],
      ),
    );
  }

  String _sortLabel() {
    for (final option in kMyVideoSorts) {
      if (option.value == _sort) return option.label;
    }
    return '最新';
  }

  Future<void> _pickSort() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: kMyVideoSorts
              .map(
                (OptionItem option) => ListTile(
                  title: Text(option.label),
                  trailing: option.value == _sort ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.of(context).pop(option.value),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );

    if (selected != null && selected != _sort) {
      setState(() => _sort = selected);
      _videos?.setLoader(_videoLoader());
    }
  }
}

class _ChannelHeader extends StatelessWidget {
  const _ChannelHeader({
    required this.channel,
    required this.baseUrl,
    required this.showSubscribe,
  });

  final VideoChannel channel;
  final String baseUrl;
  final bool showSubscribe;

  @override
  Widget build(BuildContext context) {
    final banner = channel.banners.isEmpty ? null : channel.banners.last.urlOn(baseUrl);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (banner != null)
          Image.network(banner, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 52,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              ActorAvatar(
                images: channel.avatars,
                baseUrl: baseUrl,
                fallbackLabel: channel.displayName,
                radius: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      channel.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '@${channel.handle} · ${formatCount(channel.followersCount)} 位订阅者',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (showSubscribe) SubscribeButton(uri: channel.handle),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChannelAbout extends StatelessWidget {
  const _ChannelAbout({required this.channel, required this.baseUrl});

  final VideoChannel channel;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    final description = (channel.description ?? '').trim();

    return ListView(
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
                if (description.isEmpty)
                  const Text('该频道还没有填写简介。')
                else
                  MarkdownText(data: description),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.tag_rounded),
                title: const Text('频道标识'),
                subtitle: Text(channel.handle),
              ),
              ListTile(
                leading: const Icon(Icons.public_rounded),
                title: const Text('来源'),
                subtitle: Text(channel.host.isEmpty ? '本站' : channel.host),
              ),
              ListTile(
                leading: const Icon(Icons.people_outline_rounded),
                title: const Text('订阅者'),
                subtitle: Text('${formatCount(channel.followersCount)}'),
              ),
              if ((channel.publicEmail ?? '').isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded),
                  title: const Text('联系邮箱'),
                  subtitle: Text(channel.publicEmail!),
                ),
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded),
                title: const Text('创建于'),
                subtitle: Text(formatDate(channel.createdAt)),
              ),
            ],
          ),
        ),
        if ((channel.support ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '支持该频道',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  MarkdownText(data: channel.support!),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
