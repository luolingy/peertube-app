import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../data/peertube_api.dart';
import '../../models/misc.dart';
import '../../router/routes.dart';
import '../../state/paged_list_controller.dart';
import '../../widgets/state_views.dart';

/// The current user's video import jobs.
class MyImportsScreen extends StatefulWidget {
  const MyImportsScreen({super.key});

  @override
  State<MyImportsScreen> createState() => _MyImportsScreenState();
}

class _MyImportsScreenState extends State<MyImportsScreen> {
  late final PagedListController<VideoImport> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PagedListController<VideoImport>(
      loader: (int start, int count) => context.read<PeertubeApi>().listMyVideoImports(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入任务'),
        actions: <Widget>[
          IconButton(
            tooltip: '刷新',
            onPressed: _controller.refresh,
            icon: const Icon(Icons.refresh_rounded),
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
              icon: Icons.download_done_rounded,
              title: '没有导入任务',
              subtitle: '该实例可能没有启用视频导入功能',
            );
          }

          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView.separated(
              itemCount: _controller.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final job = _controller.items[index];
                final video = job.video;

                return ListTile(
                  leading: Icon(
                    job.state.id == 2
                        ? Icons.check_circle_outline_rounded
                        : job.state.id == 3
                            ? Icons.error_outline_rounded
                            : Icons.hourglass_bottom_rounded,
                  ),
                  title: Text(
                    video?.name.isNotEmpty == true ? video!.name : job.sourceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${job.state.label} · ${formatRelativeTime(job.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: video == null
                      ? null
                      : IconButton(
                          tooltip: '查看',
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
