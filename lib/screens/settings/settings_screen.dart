import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/option_lists.dart';
import '../../data/local_store.dart';
import '../../router/routes.dart';
import '../../state/config_controller.dart';
import '../../state/metadata_controller.dart';
import '../../state/notifications_controller.dart';
import '../../state/session_controller.dart';
import '../../state/settings_controller.dart';
import '../../state/subscription_store.dart';

/// Application settings: instance, appearance, player and browse defaults.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final config = context.watch<ConfigController>();
    final session = context.watch<SessionController>();

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: <Widget>[
          const _SectionTitle('实例'),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('服务器地址'),
            subtitle: Text(settings.baseUrl),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _editInstance(context, settings),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('实例名称'),
            subtitle: Text(config.instanceName),
          ),
          if (config.error != null)
            ListTile(
              leading: Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error),
              title: const Text('无法连接实例'),
              subtitle: const Text('点击重试'),
              onTap: config.reload,
            ),
          const Divider(),
          const _SectionTitle('外观'),
          RadioListTile<String>(
            value: 'system',
            groupValue: settings.themeMode,
            title: const Text('跟随系统'),
            onChanged: (String? value) => settings.themeMode = value ?? 'system',
          ),
          RadioListTile<String>(
            value: 'light',
            groupValue: settings.themeMode,
            title: const Text('浅色'),
            onChanged: (String? value) => settings.themeMode = value ?? 'system',
          ),
          RadioListTile<String>(
            value: 'dark',
            groupValue: settings.themeMode,
            title: const Text('深色'),
            onChanged: (String? value) => settings.themeMode = value ?? 'system',
          ),
          const Divider(),
          const _SectionTitle('播放'),
          SwitchListTile(
            value: settings.autoplay,
            onChanged: (bool value) => settings.autoplay = value,
            title: const Text('自动播放'),
            subtitle: const Text('打开视频页面时自动开始播放'),
          ),
          SwitchListTile(
            value: settings.autoplayNext,
            onChanged: (bool value) => settings.autoplayNext = value,
            title: const Text('自动播放下一个'),
            subtitle: const Text('播放结束后自动切换到相关视频'),
          ),
          SwitchListTile(
            value: settings.historyEnabled,
            onChanged: (bool value) => settings.historyEnabled = value,
            title: const Text('记录观看历史'),
            subtitle: const Text('关闭后不再向服务器上报观看进度'),
          ),
          ListTile(
            leading: const Icon(Icons.speed_rounded),
            title: const Text('默认播放速度'),
            subtitle: Text('${settings.playbackRate}x'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickRate(context, settings),
          ),
          ListTile(
            leading: const Icon(Icons.volume_up_outlined),
            title: const Text('默认音量'),
            subtitle: Text('${(settings.volume * 100).round()}%'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickVolume(context, settings),
          ),
          const Divider(),
          const _SectionTitle('浏览默认值'),
          ListTile(
            leading: const Icon(Icons.public_rounded),
            title: const Text('默认范围'),
            subtitle: Text(settings.defaultScope == 'local' ? '本站' : '联合'),
            onTap: () => _pickOption(
              context,
              title: '默认范围',
              options: kVideoScopes,
              current: settings.defaultScope,
              onPicked: (String value) => settings.defaultScope = value,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sort_rounded),
            title: const Text('默认排序'),
            subtitle: Text(_labelOf(kBrowseSorts, settings.defaultSort)),
            onTap: () => _pickOption(
              context,
              title: '默认排序',
              options: kBrowseSorts,
              current: settings.defaultSort,
              onPicked: (String value) => settings.defaultSort = value,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.search_rounded),
            title: const Text('搜索结果排序'),
            subtitle: Text(_labelOf(kSearchVideoSorts, settings.defaultSearchSort)),
            onTap: () => _pickOption(
              context,
              title: '搜索结果排序',
              options: kSearchVideoSorts,
              current: settings.defaultSearchSort,
              onPicked: (String value) => settings.defaultSearchSort = value,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.mode_comment_outlined),
            title: const Text('评论排序'),
            subtitle: Text(_labelOf(kCommentSorts, settings.commentsSort)),
            onTap: () => _pickOption(
              context,
              title: '评论排序',
              options: kCommentSorts,
              current: settings.commentsSort,
              onPicked: (String value) => settings.commentsSort = value,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline_rounded),
            title: const Text('上传默认可见性'),
            subtitle: Text(_labelOfId(kVideoPrivacies, settings.defaultPrivacy)),
            onTap: () => _pickIdOption(
              context,
              title: '上传默认可见性',
              options: kVideoPrivacies,
              current: settings.defaultPrivacy,
              onPicked: (int value) => settings.defaultPrivacy = value,
            ),
          ),
          const Divider(),
          const _SectionTitle('账号'),
          if (session.isLoggedIn)
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('我的账号'),
              subtitle: Text('@${session.me?.account.handle ?? ''}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.myAccount),
            ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('关于本站'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.about),
          ),
          ListTile(
            leading: const Icon(Icons.extension_outlined),
            title: const Text('插件'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.plugins),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded),
            title: const Text('实例统计'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.statistics),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline_rounded),
            title: const Text('联系管理员'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.contact),
          ),
          if (session.isModerator)
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('管理后台'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.admin),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () {
                settings.resetPreferences();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已恢复默认设置')),
                );
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('恢复默认设置'),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${AppConfig.appTitle} · 默认实例 ${AppConfig.defaultHost}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _labelOf(List<OptionItem> options, String value) {
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  String _labelOfId(List<IdOption> options, int value) {
    for (final option in options) {
      if (option.id == value) return option.label;
    }
    return '$value';
  }

  Future<void> _editInstance(BuildContext context, SettingsController settings) async {
    final controller = TextEditingController(text: settings.baseUrl);
    final messenger = ScaffoldMessenger.of(context);
    final config = context.read<ConfigController>();
    final session = context.read<SessionController>();
    final subscriptions = context.read<SubscriptionStore>();
    final notifications = context.read<NotificationsController>();
    final metadata = context.read<MetadataController>();

    final value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('服务器地址'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('切换实例会退出当前登录状态。'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '例如 tv.bi',
                prefixIcon: Icon(Icons.dns_outlined),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('切换'),
          ),
        ],
      ),
    );

    if (value == null || value.isEmpty) return;

    try {
      await session.logout();
      subscriptions.clear();
      notifications.clear();
      await config.changeInstance(LocalStore.normalizeBaseUrl(value));
      await metadata.load();
      messenger.showSnackBar(SnackBar(content: Text('已切换到 ${config.instanceName}')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('切换失败：$error')));
    }
  }

  Future<void> _pickOption(
    BuildContext context, {
    required String title,
    required List<OptionItem> options,
    required String current,
    required ValueChanged<String> onPicked,
  }) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: options
              .map(
                (OptionItem option) => ListTile(
                  title: Text(option.label),
                  trailing: option.value == current ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.of(context).pop(option.value),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (value != null) onPicked(value);
  }

  Future<void> _pickIdOption(
    BuildContext context, {
    required String title,
    required List<IdOption> options,
    required int current,
    required ValueChanged<int> onPicked,
  }) async {
    final value = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: options
              .map(
                (IdOption option) => ListTile(
                  title: Text(option.label),
                  trailing: option.id == current ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.of(context).pop(option.id),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (value != null) onPicked(value);
  }

  Future<void> _pickRate(BuildContext context, SettingsController settings) async {
    final value = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: const <double>[0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
              .map(
                (double rate) => ListTile(
                  title: Text('${rate}x'),
                  trailing: rate == settings.playbackRate ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.of(context).pop(rate),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (value != null) settings.playbackRate = value;
  }

  Future<void> _pickVolume(BuildContext context, SettingsController settings) async {
    var value = settings.volume;
    final result = await showDialog<double>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          title: const Text('默认音量'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter _) => Slider(
              value: value,
              onChanged: (double next) {
                value = next;
                setState(() {});
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(value),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
    if (result != null) settings.volume = result;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
