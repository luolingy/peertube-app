import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/formatters.dart';
import '../../data/peertube_api.dart';
import '../../models/json_utils.dart';
import '../../models/misc.dart';
import '../../state/config_controller.dart';
import '../../widgets/actor_tiles.dart';
import '../../widgets/actor_avatar.dart';
import '../../widgets/markdown_text.dart';
import '../../widgets/state_views.dart';

/// Instance "about" page built from `GET /config` and `GET /config/about`.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  Map<String, dynamic>? _about;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final about = await context.read<PeertubeApi>().getAbout();
      if (!mounted) return;
      setState(() {
        _about = about;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigController>();
    final info = config.config.instance;
    final about = _about ?? <String, dynamic>{};
    final serverVersion = config.config.serverVersion;

    return Scaffold(
      appBar: AppBar(title: const Text('关于本站')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: <Widget>[
          Row(
            children: <Widget>[
              if (config.logoUrl != null)
                SizedBox(
                  width: 64,
                  height: 64,
                  child: PreviewImage(
                    url: config.logoUrl,
                    aspectRatio: 1,
                    borderRadius: 12,
                    placeholderIcon: Icons.play_circle_outline_rounded,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      config.instanceName,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.shortDescription.isEmpty
                          ? AppConfig.defaultHost
                          : info.shortDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (serverVersion.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'PeerTube $serverVersion',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: LoadingView(),
            )
          else ...<Widget>[
            if ((about['description'] ?? '').toString().isNotEmpty)
              _card('实例介绍', child: MarkdownText(data: '${about['description']}')),
            if ((about['terms'] ?? '').toString().isNotEmpty)
              _card('使用条款', child: MarkdownText(data: '${about['terms']}')),
            if ((about['codeOfConduct'] ?? '').toString().isNotEmpty)
              _card('行为准则', child: MarkdownText(data: '${about['codeOfConduct']}')),
            if ((about['moderationInformation'] ?? '').toString().isNotEmpty)
              _card('审核政策', child: MarkdownText(data: '${about['moderationInformation']}')),
            if ((about['creationReason'] ?? '').toString().isNotEmpty)
              _card('创建原因', child: MarkdownText(data: '${about['creationReason']}')),
            if ((about['administrator'] ?? '').toString().isNotEmpty)
              _card('管理员', child: Text('${about['administrator']}')),
            if ((about['maintenanceLifetime'] ?? '').toString().isNotEmpty)
              _card('维护计划', child: Text('${about['maintenanceLifetime']}')),
            if ((about['businessModel'] ?? '').toString().isNotEmpty)
              _card('商业模式', child: Text('${about['businessModel']}')),
            if ((about['hardwareInformation'] ?? '').toString().isNotEmpty)
              _card('服务器硬件', child: Text('${about['hardwareInformation']}')),
            if ((about['contact'] ?? '').toString().isNotEmpty)
              _card('联系方式', child: SelectableText('${about['contact']}')),
            if ((info.supportText).isNotEmpty)
              _card('支持本站', child: MarkdownText(data: info.supportText)),
          ],
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.public_rounded),
                  title: const Text('实例关注关系'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const InstanceFollowsScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.extension_outlined),
                  title: const Text('已安装插件'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PluginsScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart_rounded),
                  title: const Text('实例统计'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const StatisticsScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded),
                  title: const Text('联系管理员'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ContactScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, {required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// Instance followers / following.
class InstanceFollowsScreen extends StatefulWidget {
  const InstanceFollowsScreen({super.key});

  @override
  State<InstanceFollowsScreen> createState() => _InstanceFollowsScreenState();
}

class _InstanceFollowsScreenState extends State<InstanceFollowsScreen> {
  List<ActorFollow> _following = const <ActorFollow>[];
  List<ActorFollow> _followers = const <ActorFollow>[];
  bool _loading = true;
  Object? _error;

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
      final api = context.read<PeertubeApi>();
      final following = await api.listInstanceFollowing(count: 50);
      final followers = await api.listInstanceFollowers(count: 50);
      if (!mounted) return;
      setState(() {
        _following = following.data;
        _followers = followers.data;
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
    if (_loading) return Scaffold(appBar: AppBar(), body: const LoadingView());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('实例关注关系')),
        body: ErrorView(error: _error, onRetry: _load),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('实例关注关系'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: '本实例关注'),
              Tab(text: '关注本实例'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _list(_following, showFollowing: true),
            _list(_followers, showFollowing: false),
          ],
        ),
      ),
    );
  }

  Widget _list(List<ActorFollow> follows, {required bool showFollowing}) {
    if (follows.isEmpty) {
      return const EmptyView(
        icon: Icons.public_off_rounded,
        title: '暂无记录',
      );
    }

    return ListView.separated(
      itemCount: follows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) =>
          ActorFollowTile(follow: follows[index], showFollowing: showFollowing),
    );
  }
}

/// Public plugin list.
class PluginsScreen extends StatefulWidget {
  const PluginsScreen({super.key});

  @override
  State<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends State<PluginsScreen> {
  List<Plugin> _plugins = const <Plugin>[];
  bool _loading = true;
  Object? _error;

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
      final page = await context.read<PeertubeApi>().listPlugins(count: 100);
      if (!mounted) return;
      setState(() {
        _plugins = page.data;
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
      appBar: AppBar(title: const Text('插件与主题')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(error: _error, onRetry: _load)
              : _plugins.isEmpty
                  ? const EmptyView(icon: Icons.extension_outlined, title: '该实例没有安装插件')
                  : ListView.separated(
                      itemCount: _plugins.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final plugin = _plugins[index];
                        return ListTile(
                          leading: Icon(
                            plugin.isTheme ? Icons.palette_outlined : Icons.extension_outlined,
                          ),
                          title: Text(plugin.name),
                          subtitle: Text(
                            '${plugin.isTheme ? '主题' : '插件'} · v${plugin.version}\n${plugin.description}',
                          ),
                          isThreeLine: plugin.description.isNotEmpty,
                          trailing: plugin.enabled
                              ? const Icon(Icons.check_circle_outline_rounded, color: Colors.green)
                              : const Icon(Icons.remove_circle_outline_rounded),
                        );
                      },
                    ),
    );
  }
}

/// Instance statistics and discovery overviews.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  ServerStats? _stats;
  Map<String, dynamic>? _overview;
  bool _loading = true;
  Object? _error;

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
      final api = context.read<PeertubeApi>();
      final stats = await api.getServerStats();
      Map<String, dynamic>? overview;
      try {
        overview = await api.getVideosOverview();
      } catch (_) {
        overview = null;
      }
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _overview = overview;
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
    if (_loading) return Scaffold(appBar: AppBar(), body: const LoadingView());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('实例统计')),
        body: ErrorView(error: _error, onRetry: _load),
      );
    }

    final stats = _stats!;
    final api = context.read<PeertubeApi>();

    return Scaffold(
      appBar: AppBar(title: const Text('实例统计')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _statCard('用户', formatCount(stats.totalUsers)),
              _statCard('视频', formatCount(stats.totalVideos)),
              _statCard('本实例视频', formatCount(stats.totalLocalVideos)),
              _statCard('评论', formatCount(stats.totalVideoComments)),
              _statCard('观看次数', formatCount(stats.totalLocalVideoViews)),
              _statCard('存储用量', formatBytes(stats.totalVideosSize)),
              _statCard('关注本实例', formatCount(stats.totalInstanceFollowers)),
              _statCard('本实例关注', formatCount(stats.totalInstanceFollowing)),
            ],
          ),
          const SizedBox(height: 24),
          ..._buildOverviews(api.client.baseUrl),
        ],
      ),
    );
  }

  List<Widget> _buildOverviews(String baseUrl) {
    final overview = _overview;
    if (overview == null) return const <Widget>[];

    final widgets = <Widget>[];

    void addSection(String title, String key) {
      final entries = jsonMapList(overview[key]);
      if (entries.isEmpty) return;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      );
      widgets.add(
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              final entry = entries[index];
              final videos = jsonMapList(entry['videos']);
              return SizedBox(
                width: 240,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _entryLabel(entry, key),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Column(
                            children: videos
                                .take(3)
                                .map(
                                  (Map<String, dynamic> video) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '${video['name'] ?? ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    addSection('热门分类', 'categories');
    addSection('热门频道', 'channels');
    addSection('热门标签', 'tags');

    return widgets;
  }

  String _entryLabel(Map<String, dynamic> entry, String key) {
    switch (key) {
      case 'categories':
        return jsonMap(entry['category'])['label']?.toString() ?? '未分类';
      case 'channels':
        return jsonMap(entry['channel'])['displayName']?.toString() ?? '';
      case 'tags':
        return jsonMap(entry['tag'])['name']?.toString() ?? '';
      default:
        return '';
    }
  }

  Widget _statCard(String label, String value) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contact form (`POST /server/contact`).
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _body = TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_email.text.trim().isEmpty || _subject.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写全部字段')),
      );
      return;
    }

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<PeertubeApi>().contactAdministrator(
            fromEmail: _email.text.trim(),
            subject: _subject.text.trim(),
            body: _body.text.trim(),
          );
      messenger.showSnackBar(const SnackBar(content: Text('消息已发送')));
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('发送失败：$error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigController>();
    final enabled = config.config.contactFormEnabled && config.config.emailEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text('联系管理员')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (!enabled)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  '该实例没有启用联系表单。你可以在“关于本站”页面找到管理员的联系方式。',
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '你的邮箱',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _subject,
            decoration: const InputDecoration(
              labelText: '主题',
              prefixIcon: Icon(Icons.subject_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _body,
            minLines: 5,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: '内容',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.message_outlined),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _sending || !enabled ? null : _send,
            icon: const Icon(Icons.send_rounded),
            label: const Text('发送'),
          ),
          const SizedBox(height: 24),
          const MarkdownText(
            data: '**注意**\n\n'
                '请勿在消息中发送密码等敏感信息。管理员会在方便时回复你。',
          ),
        ],
      ),
    );
  }
}
