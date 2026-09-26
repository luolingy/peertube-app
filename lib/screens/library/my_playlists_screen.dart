import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/peertube_api.dart';
import '../../models/playlist.dart';
import '../../router/routes.dart';
import '../../state/paged_list_controller.dart';
import '../../widgets/actor_tiles.dart';
import '../../widgets/state_views.dart';

/// The current user's playlists.
class MyPlaylistsScreen extends StatefulWidget {
  const MyPlaylistsScreen({super.key});

  @override
  State<MyPlaylistsScreen> createState() => _MyPlaylistsScreenState();
}

class _MyPlaylistsScreenState extends State<MyPlaylistsScreen> {
  late final PagedListController<VideoPlaylist> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PagedListController<VideoPlaylist>(
      loader: (int start, int count) =>
          context.read<PeertubeApi>().listMyPlaylists(start: start, count: count, sort: '-updatedAt'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('新建播放列表'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名称'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !mounted) return;

    try {
      final playlist = await context.read<PeertubeApi>().createPlaylist(displayName: name);
      _controller.insertFirst(playlist);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败：$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<PeertubeApi>();
    final baseUrl = api.client.baseUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('我的播放列表')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('新建'),
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
              icon: Icons.playlist_play_rounded,
              title: '还没有播放列表',
              subtitle: '把喜欢的视频整理成播放列表',
              action: FilledButton(
                onPressed: _create,
                child: const Text('新建播放列表'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: _controller.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (BuildContext context, int index) {
                final playlist = _controller.items[index];
                return PlaylistListTile(
                  playlist: playlist,
                  baseUrl: baseUrl,
                  onTap: () => context.push(Routes.playlistById(playlist.id)),
                  trailing: IconButton(
                    tooltip: '编辑',
                    onPressed: () => context.push(Routes.editPlaylist(playlist.id)),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
