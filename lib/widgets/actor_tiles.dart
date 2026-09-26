import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/formatters.dart';
import '../models/actor.dart';
import '../models/misc.dart';
import '../models/playlist.dart';
import '../router/routes.dart';
import 'actor_avatar.dart';
import 'action_buttons.dart';

/// A channel row (search results, subscription list, ...).
class ChannelListTile extends StatelessWidget {
  const ChannelListTile({
    super.key,
    required this.channel,
    required this.baseUrl,
    this.showSubscribe = true,
    this.onTap,
    this.subtitle,
  });

  final VideoChannel channel;
  final String baseUrl;
  final bool showSubscribe;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap ?? () => context.push(Routes.channelByHandle(channel.handle)),
      leading: ActorAvatar(
        images: channel.avatars,
        baseUrl: baseUrl,
        fallbackLabel: channel.displayName,
        radius: 24,
      ),
      title: Text(
        channel.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            subtitle ?? channel.handle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          if (channel.followersCount != null)
            Text(
              '${formatCount(channel.followersCount)} 位订阅者',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
        ],
      ),
      trailing: showSubscribe
          ? SubscribeButton(uri: channel.handle, compact: true)
          : const Icon(Icons.chevron_right_rounded),
    );
  }
}

/// An account row.
class AccountListTile extends StatelessWidget {
  const AccountListTile({
    super.key,
    required this.account,
    required this.baseUrl,
    this.onTap,
    this.subtitle,
  });

  final Account account;
  final String baseUrl;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap ?? () => context.push(Routes.accountByHandle(account.handle)),
      leading: ActorAvatar(
        images: account.avatars,
        baseUrl: baseUrl,
        fallbackLabel: account.displayName,
        radius: 24,
      ),
      title: Text(
        account.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle ?? account.handle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

/// A playlist row.
class PlaylistListTile extends StatelessWidget {
  const PlaylistListTile({
    super.key,
    required this.playlist,
    required this.baseUrl,
    this.onTap,
    this.trailing,
  });

  final VideoPlaylist playlist;
  final String baseUrl;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = playlist.thumbnailUrl(baseUrl);

    return ListTile(
      onTap: onTap ?? () => context.push(Routes.playlistById(playlist.id)),
      leading: SizedBox(
        width: 84,
        child: PreviewImage(
          url: thumbnail,
          aspectRatio: 16 / 9,
          borderRadius: 8,
          placeholderIcon: Icons.playlist_play_rounded,
        ),
      ),
      title: Text(
        playlist.displayName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${playlist.videosLength} 个视频 · ${playlist.ownerAccount.displayName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: trailing,
    );
  }
}

/// A follow relationship row (instance followers/following, channel followers).
class ActorFollowTile extends StatelessWidget {
  const ActorFollowTile({
    super.key,
    required this.follow,
    this.showFollowing = true,
    this.trailing,
  });

  final ActorFollow follow;

  /// When true the "following" actor is shown (outgoing follows), otherwise the
  /// "follower" one (incoming follows).
  final bool showFollowing;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final actor = showFollowing ? follow.following : follow.follower;
    final theme = Theme.of(context);

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.public_rounded, size: 18)),
      title: Text(
        actor.name.isEmpty ? actor.host : actor.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${actor.host} · ${follow.state.label}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: trailing,
    );
  }
}
