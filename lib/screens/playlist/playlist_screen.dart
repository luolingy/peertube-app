import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/peertube_api.dart';
import '../../models/playlist.dart';
import '../../router/routes.dart';
import '../../state/paged_list_controller.dart';
import '../../state/session_controller.dart';
import '../../widgets/actor_avatar.dart';
import '../../widgets/markdown_text.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/state_views.dart';

/// A playlist page with its ordered video list.
class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key, required this.playlistId});

  final int playlistId;

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  VideoPlaylist? _playlist;
  Object? _error;
  bool _loading = true;
  PagedListController<VideoPlaylistElement>? _elements;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _elements?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<PeertubeApi>();
      final playlist = await api.getPlaylist(widget.playlistId);
      if (!mounted) return;

      setState(() {
        _playlist = playlist;
        _loading = false;
        _elements = PagedListController<VideoPlaylistElement>(
          pageSize: 30,
          loader: (int start, int count) => api.listPlaylistVideos(
            widget.playlistId,
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除播放列表'),
        content: const Text('播放列表会被删除，其中的视频不受影响。'),
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
    if (confirmed != true || !mounted) return;

    try {
      await context.read<PeertubeApi>().deletePlaylist(widget.playlistId);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败：$error')));
      }
    }
  }

  Future<void> _removeElement(VideoPlaylistElement element) async {
    try {
      await context.read<PeertubeApi>().removeVideoFromPlaylist(widget.playlistId, element.id);
      _elements?.removeWhere((VideoPlaylistElement item) => item.id == element.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('移除失败：$error')));
      }
    }
  }

  Future<void> _move(int index, int delta) async {
    final elements = _elements?.items ?? const <VideoPlaylistElement>[];
    final target = index + delta;
    if (target < 0 || target >= elements.length) return;

    final moved = elements[index];
    final anchor = elements[target];

    // PeerTube reorders by anchoring: insert `moved` after `anchor` when moving
    // down, or before it when moving up.
    try {
      await context.read<PeertubeApi>().reorderPlaylist(
            widget.playlistId,
            startPosition: moved.position,
            insertAfterPosition: delta > 0 ? anchor.position : anchor.position - 1,
            reorderLength: 1,
          );
      await _elements?.refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('排序失败：$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const LoadingView());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('播放列表')),
        body: ErrorView(error: _error, onRetry: _load),
      );
    }

    final playlist = _playlist!;
    final api = context.read<PeertubeApi>();
    final baseUrl = api.client.baseUrl;
    final session = context.watch<SessionController>();
    final isOwner = session.myAccount?.id == playlist.ownerAccount.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          if (isOwner) ...<Widget>[
            IconButton(
              tooltip: '编辑',
              onPressed: () => context.push(Routes.editPlaylist(playlist.id)),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: '删除',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: <Widget>[
          _buildHeader(playlist, baseUrl),
          const Divider(height: 1),
          Expanded(
            child: _elements == null
                ? const LoadingView()
                : PagedListView<VideoPlaylistElement>(
                    controller: _elements!,
                    padding: const EdgeInsets.only(bottom: 24),
                    emptyTitle: '该播放列表还没有视频',
                    emptyIcon: Icons.playlist_remove_rounded,
                    itemBuilder: (BuildContext context, VideoPlaylistElement element, int index) {
                      final video = element.video;
                      if (video == null) {
                        return ListTile(
                          leading: const Icon(Icons.videocam_off_outlined),
                          title: const Text('该视频不可用'),
                          subtitle: Text('位置 ${element.position}'),
                          trailing: isOwner
                              ? IconButton(
                                  onPressed: () => _removeElement(element),
                                  icon: const Icon(Icons.close_rounded),
                                )
                              : null,
                        );
                      }

                      return ListTile(
                        onTap: () => context.push(
                          '${Routes.watchVideo(video.shortUUID)}?playlist=${playlist.id}',
                        ),
                        leading: SizedBox(
                          width: 30,
                          child: Text(
                            '${index + 1}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        title: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 96,
                              child: PreviewImage(
                                url: video.thumbnailUrl(baseUrl, width: 200),
                                aspectRatio: 16 / 9,
                                borderRadius: 6,
                                placeholderIcon: Icons.movie_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    video.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    video.channel?.displayName ?? video.account.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    video.durationLabel,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        trailing: isOwner
                            ? PopupMenuButton<String>(
                                onSelected: (String value) {
                                  if (value == 'up') _move(index, -1);
                                  if (value == 'down') _move(index, 1);
                                  if (value == 'remove') _removeElement(element);
                                },
                                itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(value: 'up', child: Text('上移')),
                                  PopupMenuItem<String>(value: 'down', child: Text('下移')),
                                  PopupMenuItem<String>(value: 'remove', child: Text('从播放列表移除')),
                                ],
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(VideoPlaylist playlist, String baseUrl) {
    final thumbnail = playlist.thumbnailUrl(baseUrl);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (thumbnail != null)
                SizedBox(
                  width: 180,
                  child: PreviewImage(
                    url: thumbnail,
                    aspectRatio: 16 / 9,
                    borderRadius: 10,
                    placeholderIcon: Icons.playlist_play_rounded,
                  ),
                ),
              if (thumbnail != null) const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      playlist.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => context.push(
                        Routes.accountByHandle(playlist.ownerAccount.handle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ActorAvatar(
                            images: playlist.ownerAccount.avatars,
                            baseUrl: baseUrl,
                            fallbackLabel: playlist.ownerAccount.displayName,
                            radius: 12,
                          ),
                          const SizedBox(width: 8),
                          Text(playlist.ownerAccount.displayName),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${playlist.videosLength} 个视频 · ${playlist.privacy?.label ?? '公开'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    if ((_elements?.items.length ?? 0) > 0)
                      FilledButton.icon(
                        onPressed: () {
                          final first = _elements!.items.first.video;
                          if (first != null) {
                            context.push(
                              '${Routes.watchVideo(first.shortUUID)}?playlist=${playlist.id}',
                            );
                          }
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('播放全部'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if ((playlist.description ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            MarkdownText(data: playlist.description!),
          ],
        ],
      ),
    );
  }
}
