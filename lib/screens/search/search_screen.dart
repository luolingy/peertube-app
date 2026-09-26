import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/option_lists.dart';
import '../../data/peertube_api.dart';
import '../../models/actor.dart';
import '../../models/playlist.dart';
import '../../models/video.dart';
import '../../state/metadata_controller.dart';
import '../../state/paged_list_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/actor_tiles.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/state_views.dart';
import '../../widgets/video_cards.dart';
import '../../widgets/video_filters.dart';

/// Federated search across videos, channels and playlists.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);
  late final TextEditingController _queryController =
      TextEditingController(text: widget.initialQuery ?? '');

  PagedListController<Video>? _videos;
  PagedListController<VideoChannel>? _channels;
  PagedListController<VideoPlaylist>? _playlists;

  String _query = '';
  String _videoSort = '-match';
  String _channelSort = '-match';
  String _playlistSort = '-match';
  VideoFilterState _filters = const VideoFilterState();

  @override
  void initState() {
    super.initState();
    _videoSort = context.read<SettingsController>().defaultSearchSort;
    _channelSort = context.read<SettingsController>().defaultChannelSort;
    _playlistSort = context.read<SettingsController>().defaultPlaylistSort;

    final initial = widget.initialQuery;
    if (initial != null && initial.trim().isNotEmpty) {
      _query = initial.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<MetadataController>().load();
        _createControllers();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryController.dispose();
    _videos?.dispose();
    _channels?.dispose();
    _playlists?.dispose();
    super.dispose();
  }

  void _createControllers() {
    final api = context.read<PeertubeApi>();
    final query = _query;

    _videos?.dispose();
    _channels?.dispose();
    _playlists?.dispose();

    setState(() {
      _videos = PagedListController<Video>(
        loader: (int start, int count) => api.searchVideos(
          search: query,
          start: start,
          count: count,
          sort: _videoSort,
          isLocal: _filters.isLocal,
          nsfw: _filters.nsfw,
          searchTarget: _filters.searchTarget,
          categoryOneOf: _filters.categories.isEmpty ? null : _filters.categories,
          licenceOneOf: _filters.licences.isEmpty ? null : _filters.licences,
          languageOneOf: _filters.languages.isEmpty ? null : _filters.languages,
        ),
      );
      _channels = PagedListController<VideoChannel>(
        loader: (int start, int count) => api.searchChannels(
          search: query,
          start: start,
          count: count,
          sort: _channelSort,
          searchTarget: _filters.searchTarget,
        ),
      );
      _playlists = PagedListController<VideoPlaylist>(
        loader: (int start, int count) => api.searchPlaylists(
          search: query,
          start: start,
          count: count,
          sort: _playlistSort,
          searchTarget: _filters.searchTarget,
        ),
      );
    });
  }

  void _submit(String value) {
    final query = value.trim();
    if (query.isEmpty) return;

    setState(() => _query = query);
    _createControllers();
  }

  Future<void> _openFilters() async {
    final metadata = context.read<MetadataController>();
    final result = await showVideoFilterSheet(
      context,
      current: _filters,
      categories: metadata.categories,
      licences: metadata.licences,
      languages: metadata.languages,
      sorts: kSearchVideoSorts,
      showSearchOptions: true,
    );
    if (result == null || !mounted) return;

    setState(() => _filters = result);
    _createControllers();
  }

  Future<void> _pickSort(String current, List<OptionItem> options, ValueChanged<String> onPick) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: options
              .map(
                (OptionItem option) => RadioListTile<String>(
                  value: option.value,
                  groupValue: current,
                  title: Text(option.label),
                  onChanged: (String? value) => Navigator.of(context).pop(value),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (selected != null && selected != current) onPick(selected);
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<PeertubeApi>();
    final baseUrl = api.client.baseUrl;
    final hasQuery = _query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          textInputAction: TextInputAction.search,
          autofocus: !hasQuery,
          decoration: const InputDecoration(
            hintText: '搜索视频、频道、播放列表',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onSubmitted: _submit,
        ),
        actions: <Widget>[
          if (hasQuery)
            IconButton(
              tooltip: '筛选',
              onPressed: _openFilters,
              icon: Badge(
                isLabelVisible: _filters.activeFilterCount > 0,
                label: Text('${_filters.activeFilterCount}'),
                child: const Icon(Icons.tune_rounded),
              ),
            ),
          IconButton(
            tooltip: '搜索',
            onPressed: () => _submit(_queryController.text),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          const SizedBox(width: 4),
        ],
        bottom: hasQuery
            ? TabBar(
                controller: _tabController,
                tabs: const <Widget>[
                  Tab(text: '视频'),
                  Tab(text: '频道'),
                  Tab(text: '播放列表'),
                ],
              )
            : null,
      ),
      body: !hasQuery
          ? const EmptyView(
              icon: Icons.search_rounded,
              title: '搜索这个实例',
              subtitle: '输入关键词后回车，可搜索视频、频道和播放列表',
            )
          : TabBarView(
              controller: _tabController,
              children: <Widget>[
                _videos == null
                    ? const LoadingView()
                    : VideoGrid(
                        controller: _videos!,
                        baseUrl: baseUrl,
                        emptyTitle: '没有找到相关视频',
                        header: _buildVideoHeader(),
                      ),
                _channels == null
                    ? const LoadingView()
                    : PagedListView<VideoChannel>(
                        controller: _channels!,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        emptyTitle: '没有找到相关频道',
                        emptyIcon: Icons.person_search_rounded,
                        header: _sortBar(
                          '排序：${_label(kSearchChannelSorts, _channelSort)}',
                          () => _pickSort(_channelSort, kSearchChannelSorts, (String value) {
                            setState(() => _channelSort = value);
                            _createControllers();
                          }),
                        ),
                        itemBuilder: (BuildContext context, VideoChannel channel, int index) =>
                            ChannelListTile(channel: channel, baseUrl: baseUrl),
                      ),
                _playlists == null
                    ? const LoadingView()
                    : PagedListView<VideoPlaylist>(
                        controller: _playlists!,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        emptyTitle: '没有找到相关播放列表',
                        emptyIcon: Icons.playlist_play_rounded,
                        header: _sortBar(
                          '排序：${_label(kSearchPlaylistSorts, _playlistSort)}',
                          () => _pickSort(_playlistSort, kSearchPlaylistSorts, (String value) {
                            setState(() => _playlistSort = value);
                            _createControllers();
                          }),
                        ),
                        itemBuilder: (BuildContext context, VideoPlaylist playlist, int index) =>
                            PlaylistListTile(playlist: playlist, baseUrl: baseUrl),
                      ),
              ],
            ),
    );
  }

  String _label(List<OptionItem> options, String value) {
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return value;
  }

  Widget _sortBar(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          avatar: const Icon(Icons.sort_rounded, size: 16),
          label: Text(label),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _buildVideoHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          ActionChip(
            avatar: const Icon(Icons.sort_rounded, size: 16),
            label: Text('排序：${_label(kSearchVideoSorts, _videoSort)}'),
            onPressed: () => _pickSort(_videoSort, kSearchVideoSorts, (String value) {
              setState(() => _videoSort = value);
              _createControllers();
            }),
          ),
          ActionChip(
            avatar: Icon(
              _filters.isLocal ? Icons.home_work_outlined : Icons.public_rounded,
              size: 16,
            ),
            label: Text(_filters.isLocal ? '本站' : '联合'),
            onPressed: () {
              setState(() {
                _filters = _filters.copyWith(scope: _filters.isLocal ? 'federated' : 'local');
              });
              _createControllers();
            },
          ),
        ],
      ),
    );
  }
}
