import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/option_lists.dart';
import '../../state/metadata_controller.dart';

/// Mutable state of the video metadata form, shared by the upload and edit
/// screens.
class VideoMetadataController extends ChangeNotifier {
  VideoMetadataController({
    this.name = '',
    this.description = '',
    this.category,
    this.licence,
    this.language,
    List<String>? tags,
    this.nsfw = false,
    this.privacy = 1,
    this.commentsPolicy = 1,
    this.downloadEnabled = true,
    this.waitTranscoding = true,
    this.support = '',
    this.originallyPublishedAt,
    this.channelId,
  }) : tags = tags ?? <String>[];

  String name;
  String description;
  int? category;
  int? licence;
  String? language;
  List<String> tags;
  bool nsfw;
  int privacy;
  int commentsPolicy;
  bool downloadEnabled;
  bool waitTranscoding;
  String support;
  DateTime? originallyPublishedAt;
  int? channelId;

  /// `1` = enabled, `2` = disabled.
  int get commentsEnabled => commentsPolicy == 1 ? 1 : 0;

  void touch() => notifyListeners();
}

/// The metadata part of the upload/edit forms.
class VideoMetadataForm extends StatefulWidget {
  const VideoMetadataForm({
    super.key,
    required this.controller,
    this.showName = true,
    this.nameLabel = '标题',
  });

  final VideoMetadataController controller;
  final bool showName;
  final String nameLabel;

  @override
  State<VideoMetadataForm> createState() => _VideoMetadataFormState();
}

class _VideoMetadataFormState extends State<VideoMetadataForm> {
  late final TextEditingController _name = TextEditingController(text: widget.controller.name);
  late final TextEditingController _description =
      TextEditingController(text: widget.controller.description);
  late final TextEditingController _support =
      TextEditingController(text: widget.controller.support);
  late final TextEditingController _tags =
      TextEditingController(text: widget.controller.tags.join(', '));

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _support.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metadata = context.watch<MetadataController>();
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.showName) ...<Widget>[
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: widget.nameLabel,
              prefixIcon: const Icon(Icons.title_rounded),
            ),
            onChanged: (String value) => controller.name = value,
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _description,
          minLines: 3,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: '简介',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes_rounded),
          ),
          onChanged: (String value) => controller.description = value,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _tags,
          decoration: const InputDecoration(
            labelText: '标签',
            hintText: '用逗号分隔，例如：音乐, 现场',
            prefixIcon: Icon(Icons.tag_rounded),
          ),
          onChanged: (String value) {
            controller.tags = value
                .split(RegExp(r'[,\uFF0C\s]+'))
                .map((String tag) => tag.trim())
                .where((String tag) => tag.isNotEmpty)
                .toList(growable: false);
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          initialValue: controller.category,
          decoration: const InputDecoration(
            labelText: '分类',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: metadata.categories
              .map(
                (IdOption option) => DropdownMenuItem<int>(
                  value: option.id,
                  child: Text(option.label),
                ),
              )
              .toList(growable: false),
          onChanged: (int? value) {
            controller.category = value;
            controller.touch();
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          initialValue: controller.licence,
          decoration: const InputDecoration(
            labelText: '许可协议',
            prefixIcon: Icon(Icons.copyright_rounded),
          ),
          items: metadata.licences
              .map(
                (IdOption option) => DropdownMenuItem<int>(
                  value: option.id,
                  child: Text(option.label),
                ),
              )
              .toList(growable: false),
          onChanged: (int? value) {
            controller.licence = value;
            controller.touch();
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: controller.language,
          decoration: const InputDecoration(
            labelText: '语言',
            prefixIcon: Icon(Icons.language_rounded),
          ),
          items: metadata.languages
              .map(
                (OptionItem option) => DropdownMenuItem<String>(
                  value: option.value,
                  child: Text(option.label),
                ),
              )
              .toList(growable: false),
          onChanged: (String? value) {
            controller.language = value;
            controller.touch();
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          initialValue: controller.privacy,
          decoration: const InputDecoration(
            labelText: '可见性',
            prefixIcon: Icon(Icons.visibility_outlined),
          ),
          items: kVideoPrivacies
              .map(
                (IdOption option) => DropdownMenuItem<int>(
                  value: option.id,
                  child: Text(option.label),
                ),
              )
              .toList(growable: false),
          onChanged: (int? value) {
            if (value == null) return;
            controller.privacy = value;
            controller.touch();
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          initialValue: controller.commentsPolicy,
          decoration: const InputDecoration(
            labelText: '评论',
            prefixIcon: Icon(Icons.mode_comment_outlined),
          ),
          items: const <DropdownMenuItem<int>>[
            DropdownMenuItem<int>(value: 1, child: Text('允许评论')),
            DropdownMenuItem<int>(value: 2, child: Text('关闭评论')),
          ],
          onChanged: (int? value) {
            if (value == null) return;
            controller.commentsPolicy = value;
            controller.touch();
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _support,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: '支持说明（可选）',
            hintText: '例如：支持我的创作 / 打赏方式',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.favorite_outline_rounded),
          ),
          onChanged: (String value) => controller.support = value,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: controller.nsfw,
          onChanged: (bool value) {
            controller.nsfw = value;
            controller.touch();
          },
          title: const Text('包含敏感内容'),
          subtitle: const Text('标记为 NSFW，默认对访客隐藏'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: controller.downloadEnabled,
          onChanged: (bool value) {
            controller.downloadEnabled = value;
            controller.touch();
          },
          title: const Text('允许下载'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: controller.waitTranscoding,
          onChanged: (bool value) {
            controller.waitTranscoding = value;
            controller.touch();
          },
          title: const Text('转码完成后再发布'),
          subtitle: const Text('关闭后可以先以原始画质发布'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_rounded),
          title: const Text('原始发布时间'),
          subtitle: Text(
            controller.originallyPublishedAt == null
                ? '未设置'
                : '${controller.originallyPublishedAt}'.split(' ').first,
          ),
          trailing: controller.originallyPublishedAt == null
              ? const Icon(Icons.chevron_right_rounded)
              : IconButton(
                  onPressed: () {
                    controller.originallyPublishedAt = null;
                    controller.touch();
                  },
                  icon: const Icon(Icons.clear_rounded),
                ),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: controller.originallyPublishedAt ?? now,
              firstDate: DateTime(1970),
              lastDate: now,
            );
            if (picked == null) return;
            controller.originallyPublishedAt = picked.toUtc();
            controller.touch();
          },
        ),
      ],
    );
  }
}
