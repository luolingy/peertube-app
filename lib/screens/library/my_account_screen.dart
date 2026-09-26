import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/file_utils.dart';
import '../../core/formatters.dart';
import '../../core/option_lists.dart';
import '../../data/peertube_api.dart';
import '../../models/actor.dart';
import '../../router/routes.dart';
import '../../state/session_controller.dart';
import '../../widgets/actor_avatar.dart';
import '../../widgets/state_views.dart';

/// Profile, security and channel management for the logged in user.
class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _currentPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();

  bool _initialized = false;
  bool _savingProfile = false;
  bool _savingPassword = false;

  @override
  void dispose() {
    _displayName.dispose();
    _description.dispose();
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final me = session.me;

    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('我的账号')),
        body: const EmptyView(
          icon: Icons.lock_outline_rounded,
          title: '请先登录',
        ),
      );
    }

    if (!_initialized) {
      _displayName.text = me.account.displayName;
      _description.text = me.account.description ?? '';
      _email.text = me.email;
      _initialized = true;
    }

    final api = context.read<PeertubeApi>();
    final baseUrl = api.client.baseUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('我的账号')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: <Widget>[
          Row(
            children: <Widget>[
              ActorAvatar(
                images: me.account.avatars,
                baseUrl: baseUrl,
                fallbackLabel: me.account.displayName,
                radius: 36,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '@${me.account.handle}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${me.roleLabel} · 注册于 ${formatDate(me.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: _changeAvatar,
                          icon: const Icon(Icons.upload_rounded, size: 18),
                          label: const Text('更换头像'),
                        ),
                        if (me.account.avatars.isNotEmpty)
                          TextButton(
                            onPressed: _deleteAvatar,
                            child: const Text('移除头像'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('个人资料', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _displayName,
                    decoration: const InputDecoration(
                      labelText: '显示名称',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _description,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: '简介',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: '邮箱',
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
                      suffixIcon: me.emailVerified
                          ? const Icon(Icons.verified_rounded, color: Colors.green)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _savingProfile ? null : _saveProfile,
                      child: _savingProfile
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存资料'),
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
                  Text('修改密码', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _currentPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '当前密码',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '新密码',
                      prefixIcon: Icon(Icons.lock_reset_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _savingPassword ? null : _savePassword,
                      child: _savingPassword
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('更新密码'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: const Text('通知设置'),
                  subtitle: const Text('选择每种通知的接收方式'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(Routes.notificationSettings),
                ),
                ListTile(
                  leading: const Icon(Icons.security_rounded),
                  title: const Text('两步验证'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(Routes.twoFactor),
                ),
                ListTile(
                  leading: const Icon(Icons.devices_rounded),
                  title: const Text('登录设备'),
                  subtitle: const Text('查看并撤销已登录的设备'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(Routes.tokenSessions),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text('我的频道', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => context.push(Routes.channelCreate),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('新建'),
                      ),
                    ],
                  ),
                  if (me.videoChannels.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('还没有频道，创建一个开始发布视频吧。'),
                    )
                  else
                    ...me.videoChannels.map(
                      (VideoChannel channel) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ActorAvatar(
                          images: channel.avatars,
                          baseUrl: baseUrl,
                          fallbackLabel: channel.displayName,
                          radius: 20,
                        ),
                        title: Text(channel.displayName),
                        subtitle: Text('@${channel.handle}'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(Routes.editChannel(channel.handle)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.data_usage_rounded),
                  title: const Text('存储用量'),
                  subtitle: Text(
                    me.videoQuota < 0
                        ? '${formatBytes(me.videoQuotaUsed ?? 0)} / 无限制'
                        : '${formatBytes(me.videoQuotaUsed ?? 0)} / ${formatBytes(me.videoQuota)}',
                  ),
                ),
                if (me.videoQuotaDaily > 0)
                  ListTile(
                    leading: const Icon(Icons.today_rounded),
                    title: const Text('每日额度'),
                    subtitle: Text(
                      '${formatBytes(me.videoQuotaUsedDaily ?? 0)} / ${formatBytes(me.videoQuotaDaily)}',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _deleteAccount,
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('注销账号'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<SessionController>().updateProfile(
            displayName: _displayName.text.trim(),
            description: _description.text,
            email: _email.text.trim(),
          );
      messenger.showSnackBar(const SnackBar(content: Text('资料已保存')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$error')));
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    if (_currentPassword.text.isEmpty || _newPassword.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写当前密码和新密码')),
      );
      return;
    }

    setState(() => _savingPassword = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<SessionController>().updateProfile(
            currentPassword: _currentPassword.text,
            password: _newPassword.text,
          );
      _currentPassword.clear();
      _newPassword.clear();
      messenger.showSnackBar(const SnackBar(content: Text('密码已更新')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('更新失败：$error')));
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _changeAvatar() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await pickImageFile();
      if (picked == null || !mounted) return;

      await context.read<SessionController>().uploadAvatar(
            path: picked.path,
            bytes: picked.bytes,
            filename: picked.name,
          );
      messenger.showSnackBar(const SnackBar(content: Text('头像已更新')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('上传失败：$error')));
    }
  }

  Future<void> _deleteAvatar() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<SessionController>().deleteAvatar();
      messenger.showSnackBar(const SnackBar(content: Text('头像已移除')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('操作失败：$error')));
    }
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('注销账号'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('账号及其所有内容将被永久删除，此操作无法撤销。'),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '输入密码以确认'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('永久删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<SessionController>().deleteAccount(passwordController.text);
      if (mounted) context.go(Routes.home);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('注销失败：$error')));
    }
  }
}

/// Per-type notification settings (`UserNotificationSetting`).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  Map<String, dynamic> _settings = <String, dynamic>{};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final me = context.read<SessionController>().me;
    _settings = Map<String, dynamic>.from(me?.notificationSettings ?? <String, dynamic>{});
    _loading = false;
  }

  int _valueOf(String key) {
    final raw = _settings[key];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 1;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final api = context.read<PeertubeApi>();
    final session = context.read<SessionController>();

    try {
      await api.updateNotificationSettings(_settings);
      await session.refreshMe(silent: true);
      messenger.showSnackBar(const SnackBar(content: Text('通知设置已保存')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const LoadingView());

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知设置'),
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: kNotificationTypes
            .map(
              (OptionItem type) => ListTile(
                title: Text(type.label),
                subtitle: Text(
                  kNotificationSettingValues
                      .firstWhere(
                        (IdOption option) => option.id == _valueOf(type.value),
                        orElse: () => kNotificationSettingValues.first,
                      )
                      .label,
                ),
                trailing: DropdownButton<int>(
                  value: _valueOf(type.value),
                  underline: const SizedBox.shrink(),
                  items: kNotificationSettingValues
                      .map(
                        (IdOption option) => DropdownMenuItem<int>(
                          value: option.id,
                          child: Text(option.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (int? value) {
                    if (value == null) return;
                    setState(() => _settings[type.value] = value);
                  },
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

/// Enables/disables two factor authentication.
class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _otp = TextEditingController();

  Map<String, dynamic>? _twoFactorRequest;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _beginRequest() async {
    final me = context.read<SessionController>().me;
    if (me == null) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await context.read<PeertubeApi>().requestTwoFactor(me.id, _password.text);
      setState(() => _twoFactorRequest = result);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('请求失败：$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final me = context.read<SessionController>().me;
    final request = _twoFactorRequest;
    if (me == null || request == null) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final api = context.read<PeertubeApi>();
    final session = context.read<SessionController>();

    try {
      await api.confirmTwoFactor(
        me.id,
        '${request['requestToken']}',
        _otp.text.trim(),
      );
      await session.refreshMe(silent: true);
      messenger.showSnackBar(const SnackBar(content: Text('两步验证已开启')));
      if (mounted) context.pop();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('验证失败：$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    final me = context.read<SessionController>().me;
    if (me == null) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final api = context.read<PeertubeApi>();
    final session = context.read<SessionController>();

    try {
      await api.disableTwoFactor(me.id, _password.text);
      await session.refreshMe(silent: true);
      messenger.showSnackBar(const SnackBar(content: Text('两步验证已关闭')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('操作失败：$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final secret = _twoFactorRequest?['secret'];
    final uri = _twoFactorRequest?['uri'];

    return Scaffold(
      appBar: AppBar(title: const Text('两步验证')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                '开启两步验证后，登录时需要额外输入认证器应用生成的 6 位验证码。',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '当前密码',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _beginRequest,
            child: const Text('生成密钥'),
          ),
          if (_twoFactorRequest != null) ...<Widget>[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('在认证器应用中手动添加以下密钥：'),
                    const SizedBox(height: 8),
                    SelectableText(
                      '$secret',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (uri != null) ...<Widget>[
                      const SizedBox(height: 8),
                      SelectableText('$uri', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '验证码',
                prefixIcon: Icon(Icons.password_rounded),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _confirm,
              child: const Text('确认开启'),
            ),
          ],
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _disable,
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('关闭两步验证'),
          ),
        ],
      ),
    );
  }
}

/// Lists the active token sessions (logged in devices).
class TokenSessionsScreen extends StatefulWidget {
  const TokenSessionsScreen({super.key});

  @override
  State<TokenSessionsScreen> createState() => _TokenSessionsScreenState();
}

class _TokenSessionsScreenState extends State<TokenSessionsScreen> {
  List<Map<String, dynamic>> _sessions = const <Map<String, dynamic>>[];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final me = context.read<SessionController>().me;
    if (me == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await context.read<PeertubeApi>().listTokenSessions(me.id, count: 50);
      if (!mounted) return;
      setState(() {
        _sessions = page.data;
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

  Future<void> _revoke(int tokenSessionId) async {
    final me = context.read<SessionController>().me;
    if (me == null) return;

    try {
      await context.read<PeertubeApi>().revokeTokenSession(me.id, tokenSessionId);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('撤销失败：$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录设备')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(error: _error, onRetry: _load)
              : _sessions.isEmpty
                  ? const EmptyView(
                      icon: Icons.devices_rounded,
                      title: '没有其他登录设备',
                    )
                  : ListView.separated(
                      itemCount: _sessions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final session = _sessions[index];
                        final id = session['id'];
                        final createdAt = session['createdAt'];
                        final lastActivity = session['lastActivityDate'];

                        return ListTile(
                          leading: const Icon(Icons.devices_other_rounded),
                          title: Text('${session['deviceName'] ?? '未知设备'}'),
                          subtitle: Text(
                            '登录于 ${formatDateTime(_parseDate(createdAt))}'
                            '${lastActivity == null ? '' : '\n最近活动 ${formatRelativeTime(_parseDate(lastActivity))}'}',
                          ),
                          isThreeLine: lastActivity != null,
                          trailing: IconButton(
                            tooltip: '撤销',
                            onPressed: id is int ? () => _revoke(id) : null,
                            icon: const Icon(Icons.logout_rounded),
                          ),
                        );
                      },
                    ),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
