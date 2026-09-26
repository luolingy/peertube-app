import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/option_lists.dart';
import '../../data/peertube_api.dart';
import '../../models/video.dart';
import '../../state/metadata_controller.dart';
import '../../state/paged_list_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/state_views.dart';
import '../../widgets/video_cards.dart';
import '../../widgets/video_filters.dart';

/// Full video browser with the complete PeerTube filter set.
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  PagedListController<Video>? _controller;
  VideoFilterState? _filters;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _build());
  }

  void _build() {
    if (!mounted || _controller != null) return;

    final settings = context.read<SettingsController>();
    final filters = VideoFilterState(
      sort: settings.defaultSort,
      scope: settings.defaultScope,
    );
    _filters = filters;
    setState(() {
      _controller = PagedListController<Video>(loader: _loaderFor(filters));
    });
    context.read<MetadataController>().load();
  }

  PageLoader<Video> _loaderFor(VideoFilterState filters) {
    final api = context.read<PeertubeApi>();
    final tags = _splitTags(filters.tags);

    return (int start, int count) => api.listVideos(
          start: start,
          count: count,
          sort: filters.sort,
          isLocal: filters.isLocal,
          nsfw: filters.nsfw,
          categoryOneOf: filters.categories.isEmpty ? null : filters.categories,
          licenceOneOf: filters.licences.isEmpty ? null : filters.licences,
          languageOneOf: filters.languages.isEmpty ? null : filters.languages,
          tagsOneOf: tags.isEmpty ? null : tags,
          isLive: filters.liveOnly ? true : null,
        );
  }

  List<String> _splitTags(String raw) => raw
      .split(RegExp(r'[,\s]+'))
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList(growable: false);

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final metadata = context.read<MetadataController>();
    final filters = _filters;
    if (filters == null) return;

    final result = await showVideoFilterSheet(
      context,
      current: filters,
      categories: metadata.categories,
      licences: metadata.licences,
      languages: metadata.languages,
      sorts: kBrowseSorts,
    );

    if (result == null || !mounted) return;
    setState(() {
      _filters = result;
      _controller?.setLoader(_loaderFor(result));
    });
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<PeertubeApi>();
    final baseUrl = api.client.baseUrl;
    final filters = _filters;
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        actions: <Widget>[
          IconButton(
            tooltip: '刷新',
            onPressed: () => controller?.refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: '筛选',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: (filters?.activeFilterCount ?? 0) > 0,
              label: Text('${filters?.activeFilterCount ?? 0}'),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: controller == null
          ? const LoadingView()
          : VideoGrid(
              controller: controller,
              baseUrl: baseUrl,
              emptyTitle: '没有符合条件的视频',
              emptySubtitle: '试着放宽筛选条件',
              header: filters == null ? null : _buildHeader(filters),
            ),
    );
  }

  Widget _buildHeader(VideoFilterState filters) {
    final sortLabel = kBrowseSorts
        .firstWhere(
          (OptionItem option) => option.value == filters.sort,
          orElse: () => kBrowseSorts.first,
        )
        .label;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Chip(
            avatar: const Icon(Icons.sort_rounded, size: 16),
            label: Text(sortLabel),
            onDeleted: null,
          ),
          Chip(
            avatar: Icon(
              filters.isLocal ? Icons.home_work_outlined : Icons.public_rounded,
              size: 16,
            ),
            label: Text(filters.isLocal ? '本站' : '联合'),
          ),
          if (filters.liveOnly)
            const Chip(avatar: Icon(Icons.sensors_rounded, size: 16), label: Text('仅直播')),
          if (filters.categories.isNotEmpty)
            Chip(label: Text('分类 ${filters.categories.length}')),
          if (filters.licences.isNotEmpty)
            Chip(label: Text('许可 ${filters.licences.length}')),
          if (filters.languages.isNotEmpty)
            Chip(label: Text('语言 ${filters.languages.length}')),
          if (filters.tags.trim().isNotEmpty)
            Chip(label: Text('标签: ${filters.tags}')),
          if (filters.nsfw == true)
            const Chip(label: Text('包含 NSFW')),
        ],
      ),
    );
  }
}
