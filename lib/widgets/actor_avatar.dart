import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/actor.dart';

/// Circular avatar of an account or channel, with a graceful fallback.
class ActorAvatar extends StatelessWidget {
  const ActorAvatar({
    super.key,
    required this.images,
    required this.baseUrl,
    required this.fallbackLabel,
    this.radius = 20,
    this.onTap,
  });

  final List<ActorImage> images;
  final String baseUrl;
  final String fallbackLabel;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final image = pickActorImage(images, preferredWidth: (radius * 4).round());
    final theme = Theme.of(context);

    Widget child;
    if (image == null) {
      child = CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          _initial(fallbackLabel),
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    } else {
      child = CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        foregroundImage: CachedNetworkImageProvider(image.urlOn(baseUrl)),
        child: Text(
          _initial(fallbackLabel),
          style: TextStyle(fontSize: radius * 0.8),
        ),
      );
    }

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: child,
    );
  }

  static String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }
}

/// Rounded rectangle preview image (video thumbnails, banners, playlists).
class PreviewImage extends StatelessWidget {
  const PreviewImage({
    super.key,
    required this.url,
    this.aspectRatio = 16 / 9,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.movie_outlined,
    this.backgroundColor,
  });

  final String? url;
  final double aspectRatio;
  final double borderRadius;
  final BoxFit fit;
  final IconData placeholderIcon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(borderRadius);
    final background = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: radius,
        child: (url == null || url!.isEmpty)
            ? Container(
                color: background,
                alignment: Alignment.center,
                child: Icon(placeholderIcon, color: theme.colorScheme.outline, size: 28),
              )
            : CachedNetworkImage(
                imageUrl: url!,
                fit: fit,
                fadeInDuration: const Duration(milliseconds: 180),
                placeholder: (BuildContext context, String _) => Container(color: background),
                errorWidget: (BuildContext context, String _, Object __) => Container(
                  color: background,
                  alignment: Alignment.center,
                  child: Icon(placeholderIcon, color: theme.colorScheme.outline, size: 28),
                ),
              ),
      ),
    );
  }
}
