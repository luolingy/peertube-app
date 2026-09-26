import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/option_lists.dart';
import '../../data/peertube_api.dart';
import '../../models/video.dart';
import '../../router/routes.dart';
import '../../state/paged_list_controller.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/video_cards.dart';

/// Management list of the current user's videos.
class MyVideosScreen extends StatefulWidget {
  const MyVideosScreen({super.key});

  @override
  State<MyVideosScreen> createState() => _MyVideosScreenState();
}

class _MyVideosScreenState extends State<MyVideosScreen> {
  PagedListController<Video>? _controller;
  String _sort = '-publishedAt';
  String _search = '';
  int? _state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _controller = PagedListController<Video>(loader: _loader()));
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  PageLoader<Video> _loader() {
    return (int start, int count) => context.read<PeertubeApi>().listMyVideos(
          start: start,
          count: count,
          sort: _sort,
          search: _search.isEmpty ? null : _search,
          stateOneOf: _state == null ? null : <int>[_state!],
        );
  }

  Future<void> _pickSort() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: kMyVideoSorts
              .map(
                (OptionItem option) => ListTile(
                  title: Text(option.label),
                  trailing: option.value == _sort ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.of(context).pop(option.value),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (selected != null && selected != _sort) {
      setState(() => _sort = selected);
      _controller?.setLoader(_loader());
    }
  }

  Future<void> _delete(Video video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除视频'),
        content: Text('确定要删除《${video.name}》吗？此操作无法撤销。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<PeertubeApi>().deleteVideo(video.uuid);
      _controller?.removeWhere((Video item) => item.id == video.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败：$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<PeertubeApi>();
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的视频'),
        actions: <Widget>[
          IconButton(
            tooltip: '排序',
            onPressed: _pickSort,
            icon: const Icon(Icons.sort_rounded),
          ),
          IconButton(
            tooltip: '筛选状态',
            onPressed: _pickState,
            icon: Badge(
              isLabelVisible: _state != null,
              child: const Icon(Icons.filter_alt_outlined),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索我的视频',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
              onSubmitted: (String value) {
                setState(() => _search = value.trim());
                _controller?.setLoader(_loader());
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.upload),
        icon: const Icon(Icons.add_rounded),
        label: const Text('上传'),
      ),
      body: controller == null
          ? const SizedBox.shrink()
          : PagedListView<Video>(
              controller: controller,
              padding: const EdgeInsets.only(bottom: 96),
              emptyTitle: '还没有上传过视频',
              emptySubtitle: '点击右下角上传你的第一个视频',
              emptyIcon: Icons.video_library_outlined,
              itemBuilder: (BuildContext context, Video video, int index) => VideoListTile(
                video: video,
                baseUrl: api.client.baseUrl,
                subtitle: _subtitleFor(video),
                trailing: PopupMenuButton<String>(
                  onSelected: (String value) {
                    switch (value) {
                      case 'edit':
                        context.push(Routes.editVideo(video.shortUUID));
                        break;
                      case 'watch':
                        context.push(Routes.watchVideo(video.shortUUID));
                        break;
                      case 'delete':
                        _delete(video);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(value: 'watch', child: Text('查看')),
                    const PopupMenuItem<String>(value: 'edit', child: Text('编辑')),
                    const PopupMenuItem<String>(value: 'delete', child: Text('删除')),
                  ],
                ),
              ),
            ),
    );
  }

  String _subtitleFor(Video video) {
    final state = video.state?.label ?? '';
    final privacy = video.privacy?.label ?? '';
    final views = formatWatchCount(video.views);
    final parts = <String>[
      if (state.isNotEmpty) state,
      if (privacy.isNotEmpty) privacy,
      views,
      '${video.likes} 赞',
    ];
    return parts.join(' · ');
  }

  Future<void> _pickState() async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            ListTile(
              title: const Text('全部状态'),
              trailing: _state == null ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.of(context).pop(-1),
            ),
            ...kVideoStates.map(
              (IdOption option) => ListTile(
                title: Text(option.label),
                trailing: option.id == _state ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.of(context).pop(option.id),
              ),
            ),
          ],
        ),
      ),
    );

    setState(() => _state = selected == -1 ? null : selected);
    _controller?.setLoader(_loader());
  }
}
