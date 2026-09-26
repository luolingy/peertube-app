import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/formatters.dart';
import '../data/peertube_api.dart';
import '../router/routes.dart';
import '../state/session_controller.dart';
import '../state/subscription_store.dart';

/// Subscribe / unsubscribe button for a channel or account URI.
class SubscribeButton extends StatefulWidget {
  const SubscribeButton({
    super.key,
    required this.uri,
    this.label,
    this.compact = false,
    this.onChanged,
  });

  /// `name` for local actors, `name@host` for remote ones.
  final String uri;
  final String? label;
  final bool compact;
  final ValueChanged<bool>? onChanged;

  @override
  State<SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends State<SubscribeButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureKnown());
  }

  @override
  void didUpdateWidget(covariant SubscribeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) _ensureKnown();
  }

  void _ensureKnown() {
    if (!mounted) return;
    context.read<SubscriptionStore>().ensureKnown(<String>[widget.uri]);
  }

  Future<void> _toggle() async {
    final session = context.read<SessionController>();
    final store = context.read<SubscriptionStore>();
    final messenger = ScaffoldMessenger.of(context);

    if (!session.isLoggedIn) {
      context.push(Routes.login);
      return;
    }

    try {
      final subscribed = await store.toggle(widget.uri);
      widget.onChanged?.call(subscribed);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('操作失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SubscriptionStore>();
    final subscribed = store.isSubscribed(widget.uri);
    final pending = store.isPending(widget.uri);
    final label = widget.label ?? (subscribed ? '已订阅' : '订阅');

    if (widget.compact) {
      return TextButton.icon(
        onPressed: pending ? null : _toggle,
        icon: pending
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(subscribed ? Icons.notifications_active : Icons.notifications_none, size: 18),
        label: Text(label),
      );
    }

    if (subscribed) {
      return OutlinedButton.icon(
        onPressed: pending ? null : _toggle,
        icon: pending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.notifications_active_outlined, size: 18),
        label: Text(label),
      );
    }

    return FilledButton.icon(
      onPressed: pending ? null : _toggle,
      icon: pending
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.notifications_none_rounded, size: 18),
      label: Text(label),
    );
  }
}

/// Like / dislike buttons with counters.
class RateButtons extends StatelessWidget {
  const RateButtons({
    super.key,
    required this.rating,
    required this.likes,
    required this.dislikes,
    required this.onRate,
    this.compact = false,
  });

  /// `like`, `dislike` or `none`.
  final String rating;
  final int likes;
  final int dislikes;
  final ValueChanged<String> onRate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildButton({
      required IconData icon,
      required String value,
      required int count,
      required String tooltip,
    }) {
      final selected = rating == value;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onRate(selected ? 'none' : value),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: compact ? 18 : 20,
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                if (count > 0) ...<Widget>[
                  const SizedBox(width: 6),
                  Text(
                    formatCount(count),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildButton(
            icon: Icons.thumb_up_outlined,
            value: 'like',
            count: likes,
            tooltip: '喜欢',
          ),
          Container(width: 1, height: 18, color: theme.colorScheme.outlineVariant),
          buildButton(
            icon: Icons.thumb_down_outlined,
            value: 'dislike',
            count: dislikes,
            tooltip: '不喜欢',
          ),
        ],
      ),
    );
  }
}

/// Small icon button that opens a URL in the system browser.
class ExternalLinkButton extends StatelessWidget {
  const ExternalLinkButton({
    super.key,
    required this.url,
    this.icon = Icons.open_in_new_rounded,
    this.tooltip = '在浏览器中打开',
  });

  final String url;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: () async {
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }
}

/// Copies the canonical web URL of a resource to the clipboard.
class CopyLinkButton extends StatelessWidget {
  const CopyLinkButton({
    super.key,
    required this.path,
    this.tooltip = '复制链接',
  });

  /// Instance relative path, e.g. `/videos/watch/:uuid`.
  final String path;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final api = context.read<PeertubeApi>();
    return IconButton(
      tooltip: tooltip,
      icon: const Icon(Icons.link_rounded),
      onPressed: () async {
        final url = api.client.webUrl(path);
        await Clipboard.setData(ClipboardData(text: url));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('链接已复制到剪贴板')),
        );
      },
    );
  }
}
