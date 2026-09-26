import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/option_lists.dart';
import '../../data/peertube_api.dart';
import '../../models/video.dart';
import '../../router/routes.dart';
import '../../state/paged_list_controller.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/video_cards.dart';

/// The watch history of the current user.
class MyHistoryScreen extends StatefulWidget {
  const MyHistoryScreen({super.key});

  @override
  State<MyHistoryScreen> createState() => _MyHistoryScreenState();
}

class _MyHistoryScreenState extends State<MyHistoryScreen> {
  late final PagedListController<Video> _controller;
  String _sort = '-createdAt';

  @override
  void initState() {
    super.initState();
    _controller = PagedListController<Video>(loader: _loader());
  }

  PageLoader<Video> _loader() {
    return (int start, int count) => context.read<PeertubeApi>().listMyHistory(
          start: start,
          count: count,
          sort: _sort,
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('清空观看历史'),
        content: const Text('将删除全部观看记录，此操作无法撤销。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<PeertubeApi>().removeHistoryEntries();
      await _controller.refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败：$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<PeertubeApi>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('观看历史'),
        actions: <Widget>[
          PopupMenuButton<String>(
            tooltip: '排序',
            initialValue: _sort,
            onSelected: (String value) {
              setState(() => _sort = value);
              _controller.setLoader(_loader());
            },
            itemBuilder: (BuildContext context) => kHistorySorts
                .map(
                  (OptionItem option) => PopupMenuItem<String>(
                    value: option.value,
                    child: Text(option.label),
                  ),
                )
                .toList(growable: false),
          ),
          IconButton(
            tooltip: '清空',
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PagedListView<Video>(
        controller: _controller,
        padding: const EdgeInsets.symmetric(vertical: 8),
        emptyTitle: '还没有观看记录',
        emptyIcon: Icons.history_toggle_off_rounded,
        itemBuilder: (BuildContext context, Video video, int index) => VideoListTile(
          video: video,
          baseUrl: api.client.baseUrl,
          onTap: () => context.push(Routes.watchVideo(video.shortUUID)),
          trailing: IconButton(
            tooltip: '从历史中移除',
            onPressed: () async {
              try {
                await api.deleteHistoryEntry(video.uuid);
                _controller.removeWhere((Video item) => item.id == video.id);
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('移除失败：$error')));
                }
              }
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ),
    );
  }
}
