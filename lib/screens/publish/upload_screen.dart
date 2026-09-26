import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/file_utils.dart';
import '../../core/formatters.dart';
import '../../data/peertube_api.dart';
import '../../models/actor.dart';
import '../../router/routes.dart';
import '../../state/metadata_controller.dart';
import '../../state/session_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/actor_avatar.dart';
import 'video_metadata_form.dart';

/// Uploads a local video file with the full metadata form.
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  late final VideoMetadataController _metadata;

  PickedFileData? _video;
  PickedFileData? _thumbnail;

  int _sent = 0;
  int _total = 0;
  bool _uploading = false;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsController>();
    final session = context.read<SessionController>();

    _metadata = VideoMetadataController(
      privacy: settings.defaultPrivacy,
      channelId: session.myChannels.isEmpty ? null : session.myChannels.first.id,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetadataController>().load();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _metadata.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }

  double get _progress => _total <= 0 ? 0 : (_sent / _total).clamp(0, 1);

  Future<void> _pickVideo() async {
    try {
      final picked = await pickVideoFile();
      if (picked == null) return;
      setState(() {
        _video = picked;
        if (_metadata.name.isEmpty) {
          _metadata.name = picked.name.replaceAll(RegExp(r'\.[^.]+$'), '');
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
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

  Future<void> _upload() async {
    final video = _video;
    final channelId = _metadata.channelId;

    if (video == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择要上传的视频文件')));
      return;
    }
    if (channelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择要发布到的频道')));
      return;
    }
    if (_metadata.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写视频标题')));
      return;
    }

    setState(() {
      _uploading = true;
      _sent = 0;
      _total = video.size;
      _cancelToken = CancelToken();
    });

    final messenger = ScaffoldMessenger.of(context);
    final api = context.read<PeertubeApi>();

    try {
      final result = await api.uploadVideo(
        channelId: channelId.toString(),
        name: _metadata.name.trim(),
        videoPath: video.path ?? '',
        videoBytes: video.path == null ? video.bytes : null,
        videoFilename: video.name,
        description: _metadata.description.isEmpty ? null : _metadata.description,
        privacy: _metadata.privacy,
        category: _metadata.category,
        licence: _metadata.licence,
        language: _metadata.language,
        tags: _metadata.tags.isEmpty ? null : _metadata.tags,
        nsfw: _metadata.nsfw,
        commentsEnabled: _metadata.commentsPolicy == 1,
        downloadEnabled: _metadata.downloadEnabled,
        waitTranscoding: _metadata.waitTranscoding,
        support: _metadata.support.isEmpty ? null : _metadata.support,
        originallyPublishedAt: _metadata.originallyPublishedAt?.toIso8601String(),
        thumbnailBytes: _thumbnail?.bytes,
        thumbnailPath: _thumbnail?.path,
        thumbnailFilename: _thumbnail?.name,
        onProgress: (int sent, int total) {
          if (!mounted) return;
          setState(() {
            _sent = sent;
            _total = total;
          });
        },
        cancelToken: _cancelToken,
      );

      messenger.showSnackBar(
        SnackBar(content: Text('《${result.name}》已上传')),
      );
      if (mounted) context.go(Routes.myVideos);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('上传失败：$error')));
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _cancelToken = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final api = context.read<PeertubeApi>();
    final baseUrl = api.client.baseUrl;
    final channels = session.myChannels;

    return Scaffold(
      appBar: AppBar(
        title: const Text('上传视频'),
        actions: <Widget>[
          TextButton(
            onPressed: _uploading ? null : _upload,
            child: const Text('发布'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: channels.isEmpty
          ? _buildNoChannel()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
              children: <Widget>[
                if (_uploading) _buildProgress(),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('视频文件', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.movie_creation_outlined),
                          title: Text(_video?.name ?? '未选择文件'),
                          subtitle: _video == null
                              ? const Text('支持 MP4、WebM、MKV 等格式')
                              : Text(formatBytes(_video!.size)),
                          trailing: TextButton(
                            onPressed: _uploading ? null : _pickVideo,
                            child: Text(_video == null ? '选择' : '更换'),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.image_outlined),
                          title: Text(_thumbnail?.name ?? '缩略图（可选）'),
                          subtitle: const Text('不上传时自动截取一帧'),
                          trailing: TextButton(
                            onPressed: _uploading ? null : _pickThumbnail,
                            child: Text(_thumbnail == null ? '选择' : '更换'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('发布到频道', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...channels.map(
                          (VideoChannel channel) => RadioListTile<int>(
                            value: channel.id,
                            groupValue: _metadata.channelId,
                            title: Row(
                              children: <Widget>[
                                ActorAvatar(
                                  images: channel.avatars,
                                  baseUrl: baseUrl,
                                  fallbackLabel: channel.displayName,
                                  radius: 14,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(channel.displayName)),
                              ],
                            ),
                            onChanged: (int? value) => setState(() => _metadata.channelId = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: VideoMetadataForm(controller: _metadata),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _uploading ? null : _upload,
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text('发布视频'),
                ),
              ],
            ),
    );
  }

  Widget _buildProgress() {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('正在上传 ${(_progress * 100).toStringAsFixed(1)}%'),
                const Spacer(),
                TextButton(
                  onPressed: () => _cancelToken?.cancel(),
                  child: const Text('取消'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 6),
            Text(
              '${formatBytes(_sent)} / ${formatBytes(_total)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoChannel() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.tv_off_rounded, size: 56),
            const SizedBox(height: 12),
            const Text('你需要先创建一个频道'),
            const SizedBox(height: 6),
            Text(
              '视频必须发布到某个频道下。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.push(Routes.channelCreate),
              child: const Text('创建频道'),
            ),
          ],
        ),
      ),
    );
  }
}
