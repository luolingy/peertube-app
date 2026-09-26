import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/file_utils.dart';
import '../../data/peertube_api.dart';
import '../../models/actor.dart';
import '../../models/json_utils.dart';
import '../../router/routes.dart';
import '../../state/metadata_controller.dart';
import '../../state/session_controller.dart';
import '../../widgets/actor_avatar.dart';
import '../../widgets/markdown_text.dart';
import '../../widgets/state_views.dart';
import 'video_metadata_form.dart';

/// Creates a live stream and shows its RTMP ingest information.
class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  late final VideoMetadataController _metadata;

  bool _permanentLive = false;
  bool _saveReplay = true;
  int _latencyMode = 1;
  bool _creating = false;

  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionController>();
    _metadata = VideoMetadataController(
      privacy: 1,
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
    super.dispose();
  }

  Future<void> _create() async {
    final channelId = _metadata.channelId;
    if (channelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择频道')));
      return;
    }
    if (_metadata.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写直播标题')));
      return;
    }

    setState(() => _creating = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await context.read<PeertubeApi>().createLive(
            channelId: channelId,
            name: _metadata.name.trim(),
            description: _metadata.description.isEmpty ? null : _metadata.description,
            privacy: _metadata.privacy,
            category: _metadata.category,
            licence: _metadata.licence,
            language: _metadata.language,
            tags: _metadata.tags.isEmpty ? null : _metadata.tags,
            nsfw: _metadata.nsfw,
            commentsEnabled: _metadata.commentsPolicy == 1,
            downloadEnabled: _metadata.downloadEnabled,
            saveReplay: _saveReplay,
            latencyMode: _latencyMode,
            permanentLive: _permanentLive,
          );
      setState(() => _result = result);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('创建失败：$error')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final channels = session.myChannels;

    return Scaffold(
      appBar: AppBar(title: const Text('开始直播')),
      body: channels.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.tv_off_rounded, size: 56),
                  const SizedBox(height: 12),
                  const Text('你需要先创建一个频道'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push(Routes.channelCreate),
                    child: const Text('创建频道'),
                  ),
                ],
              ),
            )
          : _result != null
              ? _buildIngestInfo(_result!)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                  children: <Widget>[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('直播设置', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              initialValue: _metadata.channelId,
                              decoration: const InputDecoration(labelText: '频道'),
                              items: channels
                                  .map(
                                    (VideoChannel channel) => DropdownMenuItem<int>(
                                      value: channel.id,
                                      child: Text(channel.displayName),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (int? value) =>
                                  setState(() => _metadata.channelId = value),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<int>(
                              initialValue: _latencyMode,
                              decoration: const InputDecoration(
                                labelText: '延迟模式',
                                helperText: '低延迟更快但更容易卡顿',
                              ),
                              items: const <DropdownMenuItem<int>>[
                                DropdownMenuItem<int>(value: 1, child: Text('普通延迟（推荐）')),
                                DropdownMenuItem<int>(value: 2, child: Text('低延迟')),
                                DropdownMenuItem<int>(value: 3, child: Text('超低延迟')),
                              ],
                              onChanged: (int? value) {
                                if (value != null) setState(() => _latencyMode = value);
                              },
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _permanentLive,
                              onChanged: (bool value) =>
                                  setState(() => _permanentLive = value),
                              title: const Text('永久直播'),
                              subtitle: const Text('直播结束后保留为可再次开播的直播间'),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _saveReplay,
                              onChanged: (bool value) => setState(() => _saveReplay = value),
                              title: const Text('保存回放'),
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
                      onPressed: _creating ? null : _create,
                      icon: const Icon(Icons.sensors_rounded),
                      label: const Text('创建直播间'),
                    ),
                  ],
                ),
    );
  }

  Widget _buildIngestInfo(Map<String, dynamic> result) {
    final video = jsonMap(result['video']);
    final rtmp = jsonMap(result['rtmp']);
    final streamKey = '${rtmp['streamKey'] ?? ''}';
    final rtmpUrl = '${rtmp['url'] ?? ''}';
    final shortUUID = '${video['shortUUID'] ?? video['uuid'] ?? ''}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('直播间已创建。把下面的地址和密钥填进 OBS 等推流软件即可开始直播。'),
          ),
        ),
        const SizedBox(height: 16),
        _copyTile('推流地址', rtmpUrl),
        _copyTile('串流密钥', streamKey),
        const SizedBox(height: 16),
        if (shortUUID.isNotEmpty)
          FilledButton.icon(
            onPressed: () => context.go(Routes.watchVideo(shortUUID)),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('前往直播间'),
          ),
        const SizedBox(height: 24),
        const MarkdownText(
          data: '**提示**\n\n'
              '- 在 OBS 中选择「自定义推流服务」，把推流地址填入服务器，串流密钥填入密钥。\n'
              '- 分辨率建议 1920x1080 或 1280x720，码率 2500-6000 Kbps。\n'
              '- 音频建议 AAC 128-192 Kbps。',
        ),
      ],
    );
  }

  Widget _copyTile(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: SelectableText(value.isEmpty ? '（未提供）' : value),
        trailing: IconButton(
          tooltip: '复制',
          onPressed: value.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label 已复制')),
                  );
                },
          icon: const Icon(Icons.copy_rounded),
        ),
      ),
    );
  }
}

/// Creates or edits a video channel.
class ChannelEditScreen extends StatefulWidget {
  const ChannelEditScreen({super.key, this.handle});

  /// `null` creates a new channel.
  final String? handle;

  @override
  State<ChannelEditScreen> createState() => _ChannelEditScreenState();
}

class _ChannelEditScreenState extends State<ChannelEditScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _support = TextEditingController();

  VideoChannel? _channel;
  bool _loading = false;
  bool _saving = false;
  Object? _error;

  bool get _isCreate => widget.handle == null;

  @override
  void initState() {
    super.initState();
    if (!_isCreate) _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _displayName.dispose();
    _description.dispose();
    _support.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final channel = await context.read<PeertubeApi>().getChannel(widget.handle!);
      if (!mounted) return;
      setState(() {
        _channel = channel;
        _name.text = channel.name;
        _displayName.text = channel.displayName;
        _description.text = channel.description ?? '';
        _support.text = channel.support ?? '';
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
    if (_displayName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写频道名称')));
      return;
    }
    if (_isCreate && _name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写频道标识')));
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final api = context.read<PeertubeApi>();
    final session = context.read<SessionController>();

    try {
      if (_isCreate) {
        final channel = await api.createChannel(
          name: _name.text.trim(),
          displayName: _displayName.text.trim(),
          description: _description.text.isEmpty ? null : _description.text,
          support: _support.text.isEmpty ? null : _support.text,
        );
        await session.refreshMe(silent: true);
        messenger.showSnackBar(const SnackBar(content: Text('频道已创建')));
        if (mounted) context.go(Routes.editChannel(channel.handle));
      } else {
        await api.updateChannel(
          widget.handle!,
          displayName: _displayName.text.trim(),
          description: _description.text,
          support: _support.text,
        );
        messenger.showSnackBar(const SnackBar(content: Text('频道已更新')));
        if (mounted) context.pop();
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadImage({required bool banner}) async {
    final handle = _channel?.handle;
    if (handle == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final api = context.read<PeertubeApi>();

    try {
      final picked = await pickImageFile();
      if (picked == null) return;

      if (banner) {
        await api.uploadChannelBanner(
          handle,
          path: picked.path,
          bytes: picked.bytes,
          filename: picked.name,
        );
      } else {
        await api.uploadChannelAvatar(
          handle,
          path: picked.path,
          bytes: picked.bytes,
          filename: picked.name,
        );
      }
      await _load();
      messenger.showSnackBar(SnackBar(content: Text(banner ? '横幅已更新' : '头像已更新')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('上传失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const LoadingView());

    final api = context.read<PeertubeApi>();
    final baseUrl = api.client.baseUrl;
    final channel = _channel;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreate ? '创建频道' : '编辑频道'),
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _error != null
          ? ErrorView(error: _error, onRetry: _load)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
              children: <Widget>[
                if (channel != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          ActorAvatar(
                            images: channel.avatars,
                            baseUrl: baseUrl,
                            fallbackLabel: channel.displayName,
                            radius: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                OutlinedButton(
                                  onPressed: () => _uploadImage(banner: false),
                                  child: const Text('更换头像'),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: () => _uploadImage(banner: true),
                                  child: const Text('更换横幅'),
                                ),
                              ],
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
                      children: <Widget>[
                        TextField(
                          controller: _name,
                          enabled: _isCreate,
                          decoration: const InputDecoration(
                            labelText: '频道标识',
                            helperText: '用于频道链接，创建后不可修改',
                            prefixIcon: Icon(Icons.tag_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _displayName,
                          decoration: const InputDecoration(
                            labelText: '频道名称',
                            prefixIcon: Icon(Icons.tv_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _description,
                          minLines: 3,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: '频道简介',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _support,
                          minLines: 2,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: '支持说明',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.favorite_outline_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_isCreate ? '创建频道' : '保存修改'),
                ),
                if (!_isCreate) ...<Widget>[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('删除频道'),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _delete() async {
    final handle = _channel?.handle;
    if (handle == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除频道'),
        content: const Text('频道及其中的视频都会被删除，此操作无法撤销。'),
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

    final api = context.read<PeertubeApi>();
    final session = context.read<SessionController>();
    try {
      await api.deleteChannel(handle);
      await session.refreshMe(silent: true);
      if (mounted) context.go(Routes.library);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败：$error')));
      }
    }
  }
}
