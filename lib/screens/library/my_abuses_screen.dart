import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/option_lists.dart';
import '../../data/peertube_api.dart';
import '../../models/misc.dart';
import '../../router/routes.dart';
import '../../state/paged_list_controller.dart';
import '../../widgets/state_views.dart';

/// Reports created by the current user.
class MyAbusesScreen extends StatefulWidget {
  const MyAbusesScreen({super.key});

  @override
  State<MyAbusesScreen> createState() => _MyAbusesScreenState();
}

class _MyAbusesScreenState extends State<MyAbusesScreen> {
  late final PagedListController<Abuse> _controller;
  int? _state;

  @override
  void initState() {
    super.initState();
    _controller = PagedListController<Abuse>(loader: _loader());
  }

  PageLoader<Abuse> _loader() {
    return (int start, int count) => context.read<PeertubeApi>().listMyAbuses(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的举报'),
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
            return const EmptyView(
              icon: Icons.flag_outlined,
              title: '还没有提交过举报',
              subtitle: '在视频或账号页面可以发起举报',
            );
          }

          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView.separated(
              itemCount: _controller.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final abuse = _controller.items[index];
                final video = abuse.video;

                return ListTile(
                  leading: Icon(
                    abuse.state.id == 2
                        ? Icons.check_circle_outline_rounded
                        : abuse.state.id == 3
                            ? Icons.cancel_outlined
                            : Icons.hourglass_bottom_rounded,
                  ),
                  title: Text(
                    video?.name.isNotEmpty == true
                        ? video!.name
                        : (abuse.account?.displayName ?? '举报 #${abuse.id}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${abuse.reasonLabel} · ${abuse.state.label} · ${formatRelativeTime(abuse.createdAt)}'
                    '${(abuse.moderationComment ?? '').isEmpty ? '' : '\n处理说明：${abuse.moderationComment}'}',
                  ),
                  isThreeLine: (abuse.moderationComment ?? '').isNotEmpty,
                  trailing: video == null
                      ? null
                      : IconButton(
                          tooltip: '查看视频',
                          onPressed: () => context.push(Routes.watchVideo(video.shortUUID)),
                          icon: const Icon(Icons.play_arrow_rounded),
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
