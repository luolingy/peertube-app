import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/file_utils.dart';
import '../../core/option_lists.dart';
import '../../data/peertube_api.dart';
import '../../models/playlist.dart';
import '../../router/routes.dart';
import '../../widgets/actor_avatar.dart';
import '../../widgets/state_views.dart';

/// Edits a playlist (name, description, privacy, thumbnail).
class PlaylistEditScreen extends StatefulWidget {
  const PlaylistEditScreen({super.key, required this.playlistId});

  final int playlistId;

  @override
  State<PlaylistEditScreen> createState() => _PlaylistEditScreenState();
}

class _PlaylistEditScreenState extends State<PlaylistEditScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();

  VideoPlaylist? _playlist;
  bool _loading = true;
  bool _saving = false;
  Object? _error;
  int _privacy = 1;
  PickedFileData? _thumbnail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final playlist = await context.read<PeertubeApi>().getPlaylist(widget.playlistId);
      if (!mounted) return;
      setState(() {
        _playlist = playlist;
        _name.text = playlist.displayName;
        _description.text = playlist.description ?? '';
        _privacy = playlist.privacy?.id ?? 1;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写名称')));
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<PeertubeApi>().updatePlaylist(
            widget.playlistId,
            displayName: _name.text.trim(),
            description: _description.text,
            privacy: _privacy,
            thumbnailBytes: _thumbnail?.bytes,
            thumbnailPath: _thumbnail?.path,
            thumbnailFilename: _thumbnail?.name ?? 'playlist.jpg',
          );
      messenger.showSnackBar(const SnackBar(content: Text('已保存')));
      if (mounted) context.pop();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
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
      if (mounted) context.go(Routes.myPlaylists);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败：$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const LoadingView());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑播放列表')),
        body: ErrorView(error: _error, onRetry: _load),
      );
    }

    final playlist = _playlist!;
    final baseUrl = context.read<PeertubeApi>().client.baseUrl;
    final thumbnail = playlist.thumbnailUrl(baseUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑播放列表'),
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        children: <Widget>[
          Card(
            child: Column(
              children: <Widget>[
                if (thumbnail != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: PreviewImage(
                      url: thumbnail,
                      aspectRatio: 16 / 9,
                      borderRadius: 10,
                      placeholderIcon: Icons.playlist_play_rounded,
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: Text(_thumbnail?.name ?? '更换封面'),
                  trailing: TextButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final picked = await pickImageFile();
                        if (picked == null) return;
                        setState(() => _thumbnail = picked);
                      } catch (error) {
                        messenger.showSnackBar(SnackBar(content: Text('$error')));
                      }
                    },
                    child: const Text('选择'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: '名称',
                      prefixIcon: Icon(Icons.playlist_play_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _description,
                    minLines: 2,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: '简介',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: _privacy,
                    decoration: const InputDecoration(
                      labelText: '可见性',
                      prefixIcon: Icon(Icons.visibility_outlined),
                    ),
                    items: kPlaylistPrivacies
                        .map(
                          (IdOption option) => DropdownMenuItem<int>(
                            value: option.id,
                            child: Text(option.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (int? value) {
                      if (value != null) setState(() => _privacy = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存修改'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _delete,
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('删除播放列表'),
          ),
        ],
      ),
    );
  }
}
