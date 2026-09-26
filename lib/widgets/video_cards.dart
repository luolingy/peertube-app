import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/formatters.dart';
import '../models/video.dart';
import '../router/routes.dart';
import '../state/paged_list_controller.dart';
import 'actor_avatar.dart';
import 'paged_list_view.dart';

/// Grid card used by every video listing.
class VideoCard extends StatelessWidget {
  const VideoCard({
    super.key,
    required this.video,
    required this.baseUrl,
    this.showChannel = true,
    this.onTap,
    this.trailing,
  });

  final Video video;
  final String baseUrl;
  final bool showChannel;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channelName = video.channel?.displayName ?? video.account.displayName;

    return InkWell(
      onTap: onTap ?? () => context.push(Routes.watchVideo(video.shortUUID)),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            children: <Widget>[
              PreviewImage(
                url: video.thumbnailUrl(baseUrl, width: 480),
                aspectRatio: 16 / 9,
              ),
              if (video.duration > 0 || video.isLive)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _Badge(
                    label: video.isLive ? '直播' : video.durationLabel,
                    color: video.isLive ? Colors.red.shade600 : Colors.black87,
                  ),
                ),
              if (video.privacy != null && (video.privacy!.id ?? 1) != 1)
                Positioned(
                  left: 6,
                  top: 6,
                  child: _Badge(
                    label: video.privacy!.label,
                    color: Colors.black87,
                    icon: Icons.lock_outline_rounded,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        video.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (showChannel)
                        InkWell(
                          onTap: () {
                            final channel = video.channel;
                            if (channel != null) {
                              context.push(Routes.channelByHandle(channel.handle));
                            } else {
                              context.push(Routes.accountByHandle(video.account.handle));
                            }
                          },
                          child: Text(
                            channelName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.outline),
                          ),
                        ),
                      Text(
                        '${formatCount(video.views)} 次观看 · ${formatRelativeTime(video.publishedAt ?? video.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal list row (search results, playlists, related videos).
class VideoListTile extends StatelessWidget {
  const VideoListTile({
    super.key,
    required this.video,
    required this.baseUrl,
    this.onTap,
    this.trailing,
    this.thumbnailWidth = 168,
    this.showDescription = false,
    this.subtitle,
  });

  final Video video;
  final String baseUrl;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double thumbnailWidth;
  final bool showDescription;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channelName = video.channel?.displayName ?? video.account.displayName;

    return InkWell(
      onTap: onTap ?? () => context.push(Routes.watchVideo(video.shortUUID)),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: thumbnailWidth,
              child: Stack(
                children: <Widget>[
                  PreviewImage(
                    url: video.thumbnailUrl(baseUrl, width: 480),
                    aspectRatio: 16 / 9,
                  ),
                  if (video.duration > 0 || video.isLive)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: _Badge(
                        label: video.isLive ? '直播' : video.durationLabel,
                        color: video.isLive ? Colors.red.shade600 : Colors.black87,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    video.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle ??
                        '${formatCount(video.views)} 次观看 · ${formatRelativeTime(video.publishedAt ?? video.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    channelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  if (showDescription && (video.truncatedDescription ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      video.truncatedDescription!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Small rounded label used for durations and privacy.
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience wrapper rendering a [PagedListController] of videos as a
/// responsive grid.
class VideoGrid extends StatelessWidget {
  const VideoGrid({
    super.key,
    required this.controller,
    required this.baseUrl,
    this.header,
    this.emptyTitle = '暂无视频',
    this.emptySubtitle,
    this.emptyAction,
    this.onRefresh,
  });

  final PagedListController<Video> controller;
  final String baseUrl;
  final Widget? header;
  final String emptyTitle;
  final String? emptySubtitle;
  final Widget? emptyAction;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return PagedListView<Video>(
      controller: controller,
      header: header,
      emptyTitle: emptyTitle,
      emptySubtitle: emptySubtitle,
      emptyAction: emptyAction,
      emptyIcon: Icons.videocam_off_outlined,
      onRefresh: onRefresh,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisSpacing: 18,
        crossAxisSpacing: 14,
        childAspectRatio: 1.42,
      ),
      itemBuilder: (BuildContext context, Video video, int index) => VideoCard(
        video: video,
        baseUrl: baseUrl,
      ),
    );
  }
}
