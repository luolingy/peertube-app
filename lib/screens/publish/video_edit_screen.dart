import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/file_utils.dart';
import '../../data/peertube_api.dart';
import '../../models/video.dart';
import '../../router/routes.dart';
import '../../state/metadata_controller.dart';
import '../../widgets/state_views.dart';
import 'video_metadata_form.dart';

/// Edits an existing video (metadata, thumbnail, passwords, transcoding).
class VideoEditScreen extends StatefulWidget {
  const VideoEditScreen({super.key, required this.videoId});

  final String videoId;

  @override
  State<VideoEditScreen> createState() => _VideoEditScreenState();
}

class _VideoEditScreenState extends State<VideoEditScreen> {
  Video? _video;
  Object? _error;
  bool _loading = true;
  bool _saving = false;

  VideoMetadataController? _metadata;
  PickedFileData? _thumbnail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _metadata?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<PeertubeApi>();
      final video = await api.getVideo(widget.videoId);
      if (!mounted) return;

      setState(() {
        _video = video;
        _loading = false;
        _metadata = VideoMetadataController(
          name: video.name,
          description: video.description ?? '',
          category: video.category?.id,
          licence: video.licence?.id,
          language: video.language?.key,
          tags: video.tags,
          nsfw: video.nsfw,
          privacy: video.privacy?.id ?? 1,
          commentsPolicy: video.commentsPolicy?.id ?? 1,
          downloadEnabled: video.downloadEnabled,
          waitTranscoding: video.waitTranscoding,
          support: video.support ?? '',
          originallyPublishedAt: video.originallyPublishedAt,
          channelId: video.channel?.id,
        );
      });

      context.read<MetadataController>().load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final video = _video;
    final metadata = _metadata;
    if (video == null || metadata == null) return;

    if (metadata.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('标题不能为空')));
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<PeertubeApi>().updateVideo(
            video.uuid,
            name: metadata.name.trim(),
            description: metadata.description,
            category: metadata.category,
            licence: metadata.licence,
            language: metadata.language,
            nsfw: metadata.nsfw,
            tags: metadata.tags,
            privacy: metadata.privacy,
            commentsPolicy: metadata.commentsPolicy,
            downloadEnabled: metadata.downloadEnabled,
            waitTranscoding: metadata.waitTranscoding,
            support: metadata.support,
            originallyPublishedAt: metadata.originallyPublishedAt?.toIso8601String(),
            replaceThumbnail: _thumbnail != null,
            thumbnailPath: _thumbnail?.path,
            thumbnailBytes: _thumbnail?.bytes,
            thumbnailFilename: _thumbnail?.name,
          );
      messenger.showSnackBar(const SnackBar(content: Text('已保存')));
      if (mounted) context.pop();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final picked = await pickImageFile();
      if (picked == null) return;
      setState(() => _thumbnail = picked);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _managePasswords() async {
    final video = _video;
    if (video == null) return;

    final api = context.read<PeertubeApi>();
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    const Expanded(child: Text('视频密码')),
                    TextButton(
                      onPressed: () async {
                        if (controller.text.trim().isEmpty) return;
                        try {
                          await api.addVideoPassword(video.uuid, controller.text.trim());
                          controller.clear();
                          setSheetState(() {});
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('添加失败：$error')));
                          }
                        }
                      },
                      child: const Text('添加'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: '新密码',
                    prefixIcon: Icon(Icons.password_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: api.listVideoPasswords(video.uuid),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (!snapshot.hasData) return const LoadingView();
                    final passwords = snapshot.data!;
                    if (passwords.isEmpty) {
                      return const EmptyView(
                        icon: Icons.password_rounded,
                        title: '还没有设置密码',
                      );
                    }
                    return ListView(
                      children: passwords
                          .map(
                            (Map<String, dynamic> entry) => ListTile(
                              leading: const Icon(Icons.key_rounded),
                              title: Text('${entry['password'] ?? ''}'),
                              trailing: IconButton(
                                onPressed: () async {
                                  final id = entry['id'];
                                  if (id is! int) return;
                                  try {
                                    await api.deleteVideoPassword(video.uuid, id);
                                    setSheetState(() {});
                                  } catch (_) {}
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const LoadingView());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑视频')),
        body: ErrorView(error: _error, onRetry: _load),
      );
    }

    final video = _video!;
    final metadata = _metadata!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑视频'),
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
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: Text(_thumbnail?.name ?? '更换缩略图'),
                  trailing: TextButton(
                    onPressed: _pickThumbnail,
                    child: const Text('选择'),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline_rounded),
                  title: const Text('预览视频页面'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(Routes.watchVideo(video.shortUUID)),
                ),
                ListTile(
                  leading: const Icon(Icons.password_rounded),
                  title: const Text('视频密码'),
                  subtitle: const Text('仅对“密码保护”的可见性生效'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _managePasswords,
                ),
                ListTile(
                  leading: const Icon(Icons.autorenew_rounded),
                  title: const Text('重新转码'),
                  subtitle: const Text('视频出现播放问题时可以尝试'),
                  onTap: () async {
                    try {
                      await context.read<PeertubeApi>().runTranscoding(video.uuid);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已提交转码任务')),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('提交失败：$error')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: VideoMetadataForm(controller: metadata),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('保存修改'),
          ),
        ],
      ),
    );
  }
}
