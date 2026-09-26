import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/option_lists.dart';
import '../../data/peertube_api.dart';
import '../../models/actor.dart';
import '../../models/misc.dart';
import '../../router/routes.dart';
import '../../state/config_controller.dart';
import '../../state/paged_list_controller.dart';
import '../../state/session_controller.dart';
import '../../widgets/state_views.dart';

/// Entry point of the moderation / administration area.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final isAdmin = session.isAdmin;

    final entries = <_AdminEntry>[
      const _AdminEntry('举报管理', Icons.flag_outlined, Routes.adminAbuses),
      const _AdminEntry('用户管理', Icons.people_outline_rounded, Routes.adminUsers),
      const _AdminEntry('注册审核', Icons.how_to_reg_outlined, Routes.adminRegistrations),
      const _AdminEntry('后台任务', Icons.settings_suggest_outlined, Routes.adminJobs),
      const _AdminEntry('插件', Icons.extension_outlined, Routes.adminPlugins),
      const _AdminEntry('日志', Icons.receipt_long_outlined, Routes.adminLogs),
      if (isAdmin) const _AdminEntry('屏蔽名单', Icons.block_rounded, Routes.adminBlocklist),
      if (isAdmin) const _AdminEntry('实例配置', Icons.tune_rounded, Routes.adminConfig),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('管理后台')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: entries
            .map(
              (_AdminEntry entry) => Card(
                child: InkWell(
                  onTap: () => context.push(entry.route),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(entry.icon, size: 34),
                      const SizedBox(height: 10),
                      Text(entry.title, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _AdminEntry {
  const _AdminEntry(this.title, this.icon, this.route);

  final String title;
  final IconData icon;
  final String route;
}

/// Moderation queue.
class AdminAbusesScreen extends StatefulWidget {
  const AdminAbusesScreen({super.key});

  @override
  State<AdminAbusesScreen> createState() => _AdminAbusesScreenState();
}

class _AdminAbusesScreenState extends State<AdminAbusesScreen> {
  late final PagedListController<Abuse> _controller;
  int? _state;

  @override
  void initState() {
    super.initState();
    _controller = PagedListController<Abuse>(loader: _loader());
  }

  PageLoader<Abuse> _loader() {
    return (int start, int count) => context.read<PeertubeApi>().listAbuses(
          start: start,
          count: count,
          sort: '-createdAt',
          state: _state,
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolve(Abuse abuse, int state) async {
    final comment = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(state == 2 ? '确认举报' : '驳回举报'),
        content: TextField(
          controller: comment,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: '处理说明（可选）',
            alignLabelWithHint: true,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('提交'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<PeertubeApi>().updateAbuse(
            abuse.id,
            state: state,
            moderationComment: comment.text.isEmpty ? null : comment.text,
          );
      await _controller.refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败：$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('举报管理'),
        actions: <Widget>[
          PopupMenuButton<int>(
            tooltip: '筛选状态',
            onSelected: (int value) {
              setState(() => _state = value == -1 ? null : value);
              _controller.setLoader(_loader());
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(value: -1, child: Text('全部')),
              ...kAbuseStates.map(
                (IdOption option) => PopupMenuItem<int>(
                  value: option.id,
                  child: Text(option.label),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          if (_controller.isInitialLoading) return const LoadingView();
          if (_controller.error != null && _controller.isEmpty) {
            return ErrorView(error: _controller.error, onRetry: _controller.refresh);
          }
          if (_controller.isEmpty) {
            return const EmptyView(icon: Icons.flag_outlined, title: '没有待处理的举报');
          }

          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView.separated(
              itemCount: _controller.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final abuse = _controller.items[index];
                return ListTile(
                  isThreeLine: true,
                  leading: Icon(
                    abuse.state.id == 1
                        ? Icons.hourglass_bottom_rounded
                        : abuse.state.id == 2
                            ? Icons.check_circle_outline_rounded
                            : Icons.cancel_outlined,
                  ),
                  title: Text(
                    abuse.video?.name ?? abuse.account?.displayName ?? '举报 #${abuse.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${abuse.reasonLabel} · ${abuse.state.label} · '
                    '${formatRelativeTime(abuse.createdAt)}\n'
                    '举报人：${abuse.reporterAccount?.displayName ?? '匿名'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String value) {
                      if (value == 'confirm') _resolve(abuse, 2);
                      if (value == 'reject') _resolve(abuse, 3);
                      if (value == 'video' && abuse.video != null) {
                        context.push(Routes.watchVideo(abuse.video!.shortUUID));
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      if (abuse.video != null)
                        const PopupMenuItem<String>(value: 'video', child: Text('查看视频')),
                      const PopupMenuItem<String>(value: 'confirm', child: Text('确认')),
                      const PopupMenuItem<String>(value: 'reject', child: Text('驳回')),
                    ],
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

/// User administration.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late final PagedListController<User> _controller;
  String _search = '';
  int? _blocked;

  @override
  void initState() {
    super.initState();
    _controller = PagedListController<User>(loader: _loader());
  }

  PageLoader<User> _loader() {
    return (int start, int count) => context.read<PeertubeApi>().listUsers(
          start: start,
          count: count,
          sort: '-createdAt',
          search: _search.isEmpty ? null : _search,
          blocked: _blocked,
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _actions(User user) async {
    final api = context.read<PeertubeApi>();

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('修改角色'),
              onTap: () => Navigator.of(context).pop('role'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset_rounded),
              title: const Text('重置密码'),
              onTap: () => Navigator.of(context).pop('password'),
            ),
            if (!user.emailVerified)
              ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: const Text('手动验证邮箱'),
                onTap: () => Navigator.of(context).pop('verify'),
              ),
            if (!user.blocked)
              ListTile(
                leading: const Icon(Icons.block_rounded),
                title: const Text('封禁用户'),
                onTap: () => Navigator.of(context).pop('block'),
              )
            else
              ListTile(
                leading: const Icon(Icons.lock_open_rounded),
                title: const Text('解除封禁'),
                onTap: () => Navigator.of(context).pop('unblock'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('删除用户'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      switch (action) {
        case 'role':
          final role = await showModalBottomSheet<int>(
            context: context,
            showDragHandle: true,
            builder: (BuildContext context) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: kUserRoles
                    .map(
                      (IdOption option) => ListTile(
                        title: Text(option.label),
                        trailing: option.id == user.role ? const Icon(Icons.check_rounded) : null,
                        onTap: () => Navigator.of(context).pop(option.id),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          );
          if (role == null) return;
          await api.updateUser(user.id, role: role);
          break;
        case 'password':
          final password = await _askText('新密码', obscure: true);
          if (password == null || password.isEmpty) return;
          await api.adminResetPassword(user.id, password);
          break;
        case 'verify':
          await api.verifyUserEmail(user.id);
          break;
        case 'block':
          final reason = await _askText('封禁原因');
          if (reason == null || reason.isEmpty) return;
          await api.blockUser(user.id, reason);
          break;
        case 'unblock':
          await api.unblockUser(user.id);
          break;
        case 'delete':
          final confirmed = await _confirm('删除用户', '该用户及其内容会被永久删除。');
          if (!confirmed) return;
          await api.deleteUser(user.id);
          break;
      }
      await _controller.refresh();
      messenger.showSnackBar(const SnackBar(content: Text('操作已完成')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('操作失败：$error')));
    }
  }

  Future<String?> _askText(String label, {bool obscure = false}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          obscureText: obscure,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _createUser() async {
    final username = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    int role = 0;

    final created = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: const Text('新建用户'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: username,
                  decoration: const InputDecoration(labelText: '用户名'),
                ),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: '邮箱'),
                ),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '密码'),
                ),
                DropdownButtonFormField<int>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: '角色'),
                  items: kUserRoles
                      .map(
                        (IdOption option) => DropdownMenuItem<int>(
                          value: option.id,
                          child: Text(option.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (int? value) => setDialogState(() => role = value ?? 0),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );

    if (created != true || !mounted) return;

    try {
      await context.read<PeertubeApi>().createUser(
            username: username.text.trim(),
            password: password.text,
            email: email.text.trim(),
            role: role,
          );
      await _controller.refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败：$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
        actions: <Widget>[
          PopupMenuButton<int>(
            tooltip: '筛选',
            onSelected: (int value) {
              setState(() => _blocked = value == -1 ? null : value);
              _controller.setLoader(_loader());
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<int>>[
              PopupMenuItem<int>(value: -1, child: Text('全部用户')),
              PopupMenuItem<int>(value: 1, child: Text('仅已封禁')),
              PopupMenuItem<int>(value: 0, child: Text('仅正常')),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索用户名或邮箱',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
              onSubmitted: (String value) {
                setState(() => _search = value.trim());
                _controller.setLoader(_loader());
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createUser,
        child: const Icon(Icons.person_add_alt_rounded),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          if (_controller.isInitialLoading) return const LoadingView();
          if (_controller.error != null && _controller.isEmpty) {
            return ErrorView(error: _controller.error, onRetry: _controller.refresh);
          }
          if (_controller.isEmpty) {
            return const EmptyView(icon: Icons.people_outline_rounded, title: '没有找到用户');
          }

          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView.separated(
              itemCount: _controller.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final user = _controller.items[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.username.isEmpty ? '?' : user.username.substring(0, 1).toUpperCase(),
                    ),
                  ),
                  title: Text('${user.username} (${user.account.displayName})'),
                  subtitle: Text(
                    '${user.email} · ${user.roleLabel}'
                    '${user.blocked ? ' · 已封禁' : ''}'
                    '${user.emailVerified ? '' : ' · 邮箱未验证'}',
                  ),
                  trailing: IconButton(
                    onPressed: () => _actions(user),
                    icon: const Icon(Icons.more_vert_rounded),
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

/// Background jobs.
class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('后台任务'),
        actions: <Widget>[
          IconButton(
            tooltip: '暂停队列',
            onPressed: () => _run(() => context.read<PeertubeApi>().pauseJobs()),
            icon: const Icon(Icons.pause_circle_outline_rounded),
          ),
          IconButton(
            tooltip: '恢复队列',
            onPressed: () => _run(() => context.read<PeertubeApi>().resumeJobs()),
            icon: const Icon(Icons.play_circle_outline_rounded),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const TabBar(
          tabs: <Widget>[
            Tab(text: '进行中'),
            Tab(text: '已完成'),
            Tab(text: '失败'),
            Tab(text: '等待'),
          ],
        ),
      ),
      body: TabBarView(
        children: const <Widget>[
          _JobList(state: 'active'),
          _JobList(state: 'completed'),
          _JobList(state: 'failed'),
          _JobList(state: 'waiting'),
        ],
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(const SnackBar(content: Text('已提交')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('操作失败：$error')));
    }
  }
}

class _JobList extends StatefulWidget {
  const _JobList({required this.state});

  final String state;

  @override
  State<_JobList> createState() => _JobListState();
}

class _JobListState extends State<_JobList> with AutomaticKeepAliveClientMixin {
  late final PagedListController<Job> _controller = PagedListController<Job>(
    loader: (int start, int count) => context.read<PeertubeApi>().listJobs(
          state: widget.state,
          start: start,
          count: count,
          sort: '-createdAt',
        ),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        if (_controller.isInitialLoading) return const LoadingView();
        if (_controller.error != null && _controller.isEmpty) {
          return ErrorView(error: _controller.error, onRetry: _controller.refresh);
        }
        if (_controller.isEmpty) {
          return const EmptyView(icon: Icons.inbox_outlined, title: '没有任务');
        }

        return RefreshIndicator(
          onRefresh: _controller.refresh,
          child: ListView.separated(
            itemCount: _controller.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final job = _controller.items[index];
              return ListTile(
                leading: Icon(
                  job.isFailed ? Icons.error_outline_rounded : Icons.settings_suggest_outlined,
                ),
                title: Text(job.type),
                subtitle: Text(
                  '${job.state} · 进度 ${job.progress}%\n'
                  '${formatRelativeTime(job.createdAt)}'
                  '${job.error == null ? '' : '\n${job.error}'}',
                ),
                isThreeLine: job.error != null,
                trailing: job.state == 'active'
                    ? IconButton(
                        tooltip: '取消',
                        onPressed: () async {
                          try {
                            await context.read<PeertubeApi>().cancelJob(job.type, job.id);
                            await _controller.refresh();
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}

/// Plugin administration.
class AdminPluginsScreen extends StatefulWidget {
  const AdminPluginsScreen({super.key});

  @override
  State<AdminPluginsScreen> createState() => _AdminPluginsScreenState();
}

class _AdminPluginsScreenState extends State<AdminPluginsScreen> {
  late final PagedListController<Plugin> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PagedListController<Plugin>(
      loader: (int start, int count) =>
          context.read<PeertubeApi>().listPlugins(start: start, count: count),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _install() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('安装插件'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'npm 包名',
            hintText: '例如 peertube-plugin-livechat',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('安装'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<PeertubeApi>().installPlugin(name);
      await _controller.refresh();
      messenger.showSnackBar(const SnackBar(content: Text('安装任务已提交')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('安装失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('插件')),
      floatingActionButton: FloatingActionButton(
        onPressed: _install,
        child: const Icon(Icons.add_rounded),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          if (_controller.isInitialLoading) return const LoadingView();
          if (_controller.error != null && _controller.isEmpty) {
            return ErrorView(error: _controller.error, onRetry: _controller.refresh);
          }
          if (_controller.isEmpty) {
            return const EmptyView(icon: Icons.extension_outlined, title: '没有安装插件');
          }

          return ListView.separated(
            itemCount: _controller.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final plugin = _controller.items[index];
              return ListTile(
                leading: Icon(plugin.isTheme ? Icons.palette_outlined : Icons.extension_outlined),
                title: Text(plugin.name),
                subtitle: Text(
                  '${plugin.npmName} · v${plugin.version}'
                  '${plugin.latestVersion == null ? '' : ' (最新 ${plugin.latestVersion})'}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (String value) async {
                    final api = context.read<PeertubeApi>();
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      if (value == 'update') await api.updatePlugin(plugin.npmName);
                      if (value == 'uninstall') await api.uninstallPlugin(plugin.npmName);
                      await _controller.refresh();
                    } catch (error) {
                      messenger.showSnackBar(SnackBar(content: Text('操作失败：$error')));
                    }
                  },
                  itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(value: 'update', child: Text('更新')),
                    PopupMenuItem<String>(value: 'uninstall', child: Text('卸载')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Server logs.
class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  List<LogLine> _lines = const <LogLine>[];
  bool _loading = true;
  Object? _error;
  String? _level;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final lines = await context.read<PeertubeApi>().getLogs(level: _level);
      if (!mounted) return;
      setState(() {
        _lines = lines;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志'),
        actions: <Widget>[
          PopupMenuButton<String>(
            tooltip: '级别',
            onSelected: (String value) {
              setState(() => _level = value == 'all' ? null : value);
              _load();
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'all', child: Text('全部')),
              PopupMenuItem<String>(value: 'error', child: Text('错误')),
              PopupMenuItem<String>(value: 'warn', child: Text('警告')),
              PopupMenuItem<String>(value: 'info', child: Text('信息')),
              PopupMenuItem<String>(value: 'debug', child: Text('调试')),
            ],
          ),
          IconButton(
            tooltip: '刷新',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(error: _error, onRetry: _load)
              : _lines.isEmpty
                  ? const EmptyView(icon: Icons.receipt_long_outlined, title: '没有日志')
                  : ListView.separated(
                      itemCount: _lines.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final line = _lines[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            line.level == 'error'
                                ? Icons.error_outline_rounded
                                : line.level == 'warn'
                                    ? Icons.warning_amber_rounded
                                    : Icons.info_outline_rounded,
                            color: line.level == 'error'
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                          title: Text(line.message),
                          subtitle: Text('${line.timestamp} · ${line.level}'),
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: Text(line.level),
                              content: SingleChildScrollView(
                                child: SelectableText(
                                  '${line.timestamp}\n${line.message}\n\n${line.meta ?? ''}',
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('关闭'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

/// Pending registrations.
class AdminRegistrationsScreen extends StatefulWidget {
  const AdminRegistrationsScreen({super.key});

  @override
  State<AdminRegistrationsScreen> createState() => _AdminRegistrationsScreenState();
}

class _AdminRegistrationsScreenState extends State<AdminRegistrationsScreen> {
  late final PagedListController<Map<String, dynamic>> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PagedListController<Map<String, dynamic>>(
      loader: (int start, int count) => context.read<PeertubeApi>().listRegistrations(
            start: start,
            count: count,
            sort: '-createdAt',
          ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handle(Map<String, dynamic> registration, bool accept) async {
    final id = registration['id'];
    if (id is! int) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      if (accept) {
        await context.read<PeertubeApi>().acceptRegistration(id);
      } else {
        await context.read<PeertubeApi>().rejectRegistration(id);
      }
      await _controller.refresh();
      messenger.showSnackBar(SnackBar(content: Text(accept ? '已通过' : '已拒绝')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('操作失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册审核')),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          if (_controller.isInitialLoading) return const LoadingView();
          if (_controller.error != null && _controller.isEmpty) {
            return ErrorView(error: _controller.error, onRetry: _controller.refresh);
          }
          if (_controller.isEmpty) {
            return const EmptyView(icon: Icons.how_to_reg_outlined, title: '没有待审核的注册');
          }

          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView.separated(
              itemCount: _controller.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final registration = _controller.items[index];
                final user = registration['user'];
                final username = user is Map ? '${user['username'] ?? ''}' : '';
                final email = user is Map ? '${user['email'] ?? ''}' : '';
                final createdAt = registration['createdAt'];

                return ListTile(
                  title: Text(username.isEmpty ? '注册 #${registration['id']}' : username),
                  subtitle: Text(
                    '$email\n${formatRelativeTime(DateTime.tryParse('$createdAt'))}'
                    '${registration['moderationResponse'] == null ? '' : '\n${registration['moderationResponse']}'}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        tooltip: '通过',
                        onPressed: () => _handle(registration, true),
                        icon: const Icon(Icons.check_rounded),
                      ),
                      IconButton(
                        tooltip: '拒绝',
                        onPressed: () => _handle(registration, false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
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

/// Server blocklist.
class AdminBlocklistScreen extends StatefulWidget {
  const AdminBlocklistScreen({super.key});

  @override
  State<AdminBlocklistScreen> createState() => _AdminBlocklistScreenState();
}

class _AdminBlocklistScreenState extends State<AdminBlocklistScreen> {
  late final PagedListController<Map<String, dynamic>> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PagedListController<Map<String, dynamic>>(
      loader: (int start, int count) => context.read<PeertubeApi>().listServerBlocklist(
            start: start,
            count: count,
          ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _block() async {
    final controller = TextEditingController();
    final host = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('屏蔽服务器'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '域名',
            hintText: '例如 example.com',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('屏蔽'),
          ),
        ],
      ),
    );

    if (host == null || host.isEmpty || !mounted) return;

    try {
      await context.read<PeertubeApi>().blockServer(host);
      await _controller.refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败：$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('屏蔽名单')),
      floatingActionButton: FloatingActionButton(
        onPressed: _block,
        child: const Icon(Icons.add_rounded),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          if (_controller.isInitialLoading) return const LoadingView();
          if (_controller.error != null && _controller.isEmpty) {
            return ErrorView(error: _controller.error, onRetry: _controller.refresh);
          }
          if (_controller.isEmpty) {
            return const EmptyView(icon: Icons.block_rounded, title: '没有屏蔽任何服务器');
          }

          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView.separated(
              itemCount: _controller.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final entry = _controller.items[index];
                final host = '${entry['host'] ?? ''}';
                return ListTile(
                  leading: const Icon(Icons.block_rounded),
                  title: Text(host),
                  subtitle: Text('${entry['createdAt'] ?? ''}'),
                  trailing: IconButton(
                    tooltip: '解除屏蔽',
                    onPressed: () async {
                      try {
                        await context.read<PeertubeApi>().unblockServer(host);
                        _controller.removeWhere(
                          (Map<String, dynamic> item) => item['host'] == host,
                        );
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('操作失败：$error')));
                        }
                      }
                    },
                    icon: const Icon(Icons.lock_open_rounded),
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

/// Read-only viewer of the instance configuration.
class AdminConfigScreen extends StatelessWidget {
  const AdminConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigController>();
    final pretty = const JsonEncoder.withIndent('  ').convert(config.config.raw);

    return Scaffold(
      appBar: AppBar(title: const Text('实例配置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('概要', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('版本：${config.config.serverVersion}'),
                  Text('注册：${config.config.signup.canRegister ? '开放' : '关闭'}'),
                  Text('审核注册：${config.config.signup.requiresApproval ? '是' : '否'}'),
                  Text('直播：${config.config.liveEnabled ? '已启用' : '未启用'}'),
                  Text('联合：${config.config.federationEnabled ? '已启用' : '未启用'}'),
                  Text('导入（HTTP）：${config.config.importHttpEnabled ? '是' : '否'}'),
                  Text('导入（种子）：${config.config.importTorrentEnabled ? '是' : '否'}'),
                  Text('联系表单：${config.config.contactFormEnabled ? '是' : '否'}'),
                  Text('搜索索引：${config.config.searchIndexEnabled ? '是' : '否'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ExpansionTile(
              title: const Text('原始 JSON'),
              childrenPadding: const EdgeInsets.all(12),
              children: <Widget>[
                SelectableText(
                  pretty,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
