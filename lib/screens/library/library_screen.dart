import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../data/peertube_api.dart';
import '../../router/routes.dart';
import '../../state/config_controller.dart';
import '../../state/notifications_controller.dart';
import '../../state/session_controller.dart';
import '../../widgets/actor_avatar.dart';
import '../../widgets/state_views.dart';

/// "My library" hub: everything tied to the logged in user.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final api = context.read<PeertubeApi>();
    final baseUrl = api.client.baseUrl;
    final unread = context.watch<NotificationsController>().unreadCount;

    if (session.isBooting) {
      return const Scaffold(body: LoadingView());
    }

    if (!session.isLoggedIn) {
      return _buildLoggedOut(context);
    }

    final me = session.me!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: <Widget>[
          IconButton(
            tooltip: '设置',
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: <Widget>[
                ActorAvatar(
                  images: me.account.avatars,
                  baseUrl: baseUrl,
                  fallbackLabel: me.account.displayName,
                  radius: 32,
                  onTap: () => context.push(Routes.myAccount),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        me.account.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${me.account.handle}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatBytes(me.videoQuotaUsed ?? 0)} / ${me.videoQuota < 0 ? '无限制' : formatBytes(me.videoQuota)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '编辑资料',
                  onPressed: () => context.push(Routes.myAccount),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _Tile(
            icon: Icons.history_rounded,
            title: '观看历史',
            subtitle: '继续观看之前的内容',
            onTap: () => context.push(Routes.myHistory),
          ),
          _Tile(
            icon: Icons.subscriptions_outlined,
            title: '我的订阅',
            subtitle: '${session.myChannels.length} 个自己的频道',
            onTap: () => context.push(Routes.mySubscriptions),
          ),
          _Tile(
            icon: Icons.video_library_outlined,
            title: '我的视频',
            subtitle: '管理、编辑与删除已上传的视频',
            onTap: () => context.push(Routes.myVideos),
          ),
          _Tile(
            icon: Icons.playlist_play_rounded,
            title: '我的播放列表',
            subtitle: '创建与管理播放列表',
            onTap: () => context.push(Routes.myPlaylists),
          ),
          _Tile(
            icon: Icons.download_rounded,
            title: '导入任务',
            subtitle: '查看视频导入进度',
            onTap: () => context.push(Routes.myImports),
          ),
          _Tile(
            icon: Icons.notifications_none_rounded,
            title: '通知',
            subtitle: unread > 0 ? '$unread 条未读' : '暂无未读通知',
            trailing: unread > 0 ? Badge.count(count: unread) : null,
            onTap: () => context.push(Routes.notifications),
          ),
          _Tile(
            icon: Icons.flag_outlined,
            title: '我的举报',
            onTap: () => context.push(Routes.myAbuses),
          ),
          const Divider(height: 1),
          _Tile(
            icon: Icons.cloud_upload_outlined,
            title: '上传视频',
            onTap: () => context.push(Routes.upload),
          ),
          _Tile(
            icon: Icons.sensors_rounded,
            title: '开始直播',
            onTap: () => context.push(Routes.goLive),
          ),
          _Tile(
            icon: Icons.add_box_outlined,
            title: '创建频道',
            onTap: () => context.push(Routes.channelCreate),
          ),
          const Divider(height: 1),
          _Tile(
            icon: Icons.info_outline_rounded,
            title: '关于本站',
            subtitle: context.watch<ConfigController>().instanceName,
            onTap: () => context.push(Routes.about),
          ),
          _Tile(
            icon: Icons.settings_outlined,
            title: '应用设置',
            onTap: () => context.push(Routes.settings),
          ),
          if (session.isModerator)
            _Tile(
              icon: Icons.shield_outlined,
              title: '管理后台',
              subtitle: session.isAdmin ? '管理员' : '版主',
              onTap: () => context.push(Routes.admin),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('退出登录'),
                    content: const Text('确定要退出当前账号吗？'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('退出'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<SessionController>().logout();
                  if (context.mounted) context.read<NotificationsController>().clear();
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('退出登录'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedOut(BuildContext context) {
    final config = context.watch<ConfigController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: <Widget>[
          IconButton(
            tooltip: '设置',
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          const SizedBox(height: 32),
          const Icon(Icons.account_circle_outlined, size: 72),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '还没有登录',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '登录后可以订阅频道、上传视频、同步观看历史',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: FilledButton(
              onPressed: () => context.push(Routes.login),
              child: const Text('登录'),
            ),
          ),
          if (config.config.signup.canRegister) ...<Widget>[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: OutlinedButton(
                onPressed: () => context.push(Routes.signup),
                child: const Text('注册新账号'),
              ),
            ),
          ],
          const SizedBox(height: 28),
          const Divider(height: 1),
          _Tile(
            icon: Icons.history_rounded,
            title: '观看历史',
            subtitle: '登录后同步',
            onTap: () => context.push(Routes.login),
          ),
          _Tile(
            icon: Icons.subscriptions_outlined,
            title: '我的订阅',
            onTap: () => context.push(Routes.login),
          ),
          _Tile(
            icon: Icons.playlist_play_rounded,
            title: '我的播放列表',
            onTap: () => context.push(Routes.login),
          ),
          const Divider(height: 1),
          _Tile(
            icon: Icons.info_outline_rounded,
            title: '关于本站',
            subtitle: config.instanceName,
            onTap: () => context.push(Routes.about),
          ),
          _Tile(
            icon: Icons.settings_outlined,
            title: '应用设置',
            onTap: () => context.push(Routes.settings),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
