import 'package:flutter/material.dart';

import '../core/option_lists.dart';
import '../models/video.dart';

/// Immutable description of the browse/search filters.
class VideoFilterState {
  const VideoFilterState({
    this.sort = '-publishedAt',
    this.scope = 'federated',
    this.categories = const <int>{},
    this.licences = const <int>{},
    this.languages = const <String>{},
    this.tags = '',
    this.liveOnly = false,
    this.nsfw,
    this.searchTarget = 'local',
    this.startDate,
    this.endDate,
    this.durationMin,
    this.durationMax,
  });

  final String sort;

  /// `local` or `federated`.
  final String scope;
  final Set<int> categories;
  final Set<int> licences;
  final Set<String> languages;
  final String tags;
  final bool liveOnly;

  /// `null` means "include both".
  final bool? nsfw;

  /// `local` or `search-index` (federated search through the index).
  final String searchTarget;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? durationMin;
  final int? durationMax;

  bool get isLocal => scope == 'local';

  int get activeFilterCount {
    var count = 0;
    if (categories.isNotEmpty) count++;
    if (licences.isNotEmpty) count++;
    if (languages.isNotEmpty) count++;
    if (tags.trim().isNotEmpty) count++;
    if (liveOnly) count++;
    if (nsfw != null) count++;
    return count;
  }

  VideoFilterState copyWith({
    String? sort,
    String? scope,
    Set<int>? categories,
    Set<int>? licences,
    Set<String>? languages,
    String? tags,
    bool? liveOnly,
    bool? nsfw,
    bool clearNsfw = false,
    String? searchTarget,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
    int? durationMin,
    int? durationMax,
  }) {
    return VideoFilterState(
      sort: sort ?? this.sort,
      scope: scope ?? this.scope,
      categories: categories ?? this.categories,
      licences: licences ?? this.licences,
      languages: languages ?? this.languages,
      tags: tags ?? this.tags,
      liveOnly: liveOnly ?? this.liveOnly,
      nsfw: clearNsfw ? null : (nsfw ?? this.nsfw),
      searchTarget: searchTarget ?? this.searchTarget,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      durationMin: durationMin ?? this.durationMin,
      durationMax: durationMax ?? this.durationMax,
    );
  }
}

/// Shows the filter sheet. Returns the updated filters, or `null` when the user
/// cancelled.
Future<VideoFilterState?> showVideoFilterSheet(
  BuildContext context, {
  required VideoFilterState current,
  required List<IdOption> categories,
  required List<IdOption> licences,
  required List<OptionItem> languages,
  required List<OptionItem> sorts,
  bool showSearchOptions = false,
}) {
  return showModalBottomSheet<VideoFilterState>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _VideoFilterSheet(
      initial: current,
      categories: categories,
      licences: licences,
      languages: languages,
      sorts: sorts,
      showSearchOptions: showSearchOptions,
    ),
  );
}

class _VideoFilterSheet extends StatefulWidget {
  const _VideoFilterSheet({
    required this.initial,
    required this.categories,
    required this.licences,
    required this.languages,
    required this.sorts,
    required this.showSearchOptions,
  });

  final VideoFilterState initial;
  final List<IdOption> categories;
  final List<IdOption> licences;
  final List<OptionItem> languages;
  final List<OptionItem> sorts;
  final bool showSearchOptions;

  @override
  State<_VideoFilterSheet> createState() => _VideoFilterSheetState();
}

class _VideoFilterSheetState extends State<_VideoFilterSheet> {
  late VideoFilterState _state = widget.initial;
  late final TextEditingController _tagsController =
      TextEditingController(text: widget.initial.tags);

  @override
  void dispose() {
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController scrollController) {
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
              child: Row(
                children: <Widget>[
                  Text('筛选', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _state = VideoFilterState(sort: _state.sort);
                      _tagsController.clear();
                    }),
                    child: const Text('重置'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_state),
                    child: const Text('应用'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: <Widget>[
                  _label('排序'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.sorts
                        .map(
                          (OptionItem option) => ChoiceChip(
                            label: Text(option.label),
                            selected: _state.sort == option.value,
                            onSelected: (_) =>
                                setState(() => _state = _state.copyWith(sort: option.value)),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 20),
                  _label('范围'),
                  Wrap(
                    spacing: 8,
                    children: kVideoScopes
                        .map(
                          (OptionItem option) => ChoiceChip(
                            label: Text(option.label),
                            selected: _state.scope == option.value,
                            onSelected: (_) =>
                                setState(() => _state = _state.copyWith(scope: option.value)),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  if (widget.showSearchOptions) ...<Widget>[
                    const SizedBox(height: 20),
                    _label('搜索范围'),
                    Wrap(
                      spacing: 8,
                      children: const <OptionItem>[
                        OptionItem('local', '本站'),
                        OptionItem('search-index', '全网索引'),
                      ]
                          .map(
                            (OptionItem option) => ChoiceChip(
                              label: Text(option.label),
                              selected: _state.searchTarget == option.value,
                              onSelected: (_) => setState(
                                () => _state = _state.copyWith(searchTarget: option.value),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _label('内容类型'),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      FilterChip(
                        label: const Text('仅直播'),
                        selected: _state.liveOnly,
                        onSelected: (bool value) =>
                            setState(() => _state = _state.copyWith(liveOnly: value)),
                      ),
                      FilterChip(
                        label: const Text('包含 NSFW'),
                        selected: _state.nsfw == true,
                        onSelected: (bool value) => setState(
                          () => _state = value
                              ? _state.copyWith(nsfw: true)
                              : _state.copyWith(clearNsfw: true),
                        ),
                      ),
                    ],
                  ),
                  if (widget.categories.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 20),
                    _label('分类'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.categories
                          .map(
                            (IdOption option) => FilterChip(
                              label: Text(option.label),
                              selected: _state.categories.contains(option.id),
                              onSelected: (bool value) => setState(() {
                                final next = Set<int>.from(_state.categories);
                                if (value) {
                                  next.add(option.id);
                                } else {
                                  next.remove(option.id);
                                }
                                _state = _state.copyWith(categories: next);
                              }),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  if (widget.licences.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 20),
                    _label('许可协议'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.licences
                          .map(
                            (IdOption option) => FilterChip(
                              label: Text(option.label),
                              selected: _state.licences.contains(option.id),
                              onSelected: (bool value) => setState(() {
                                final next = Set<int>.from(_state.licences);
                                if (value) {
                                  next.add(option.id);
                                } else {
                                  next.remove(option.id);
                                }
                                _state = _state.copyWith(licences: next);
                              }),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  if (widget.languages.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 20),
                    _label('语言'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.languages
                          .take(40)
                          .map(
                            (OptionItem option) => FilterChip(
                              label: Text(option.label),
                              selected: _state.languages.contains(option.value),
                              onSelected: (bool value) => setState(() {
                                final next = Set<String>.from(_state.languages);
                                if (value) {
                                  next.add(option.value);
                                } else {
                                  next.remove(option.value);
                                }
                                _state = _state.copyWith(languages: next);
                              }),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _label('标签'),
                  TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      hintText: '多个标签用逗号分隔',
                      prefixIcon: Icon(Icons.tag_rounded),
                    ),
                    onChanged: (String value) =>
                        setState(() => _state = _state.copyWith(tags: value)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_state),
                      child: const Text('应用筛选'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      );
}

/// Converts a filter state into the query parameters shared by `/videos` and
/// `/search/videos`.
Map<String, dynamic> buildVideoQuery(VideoFilterState filters) {
  final tags = filters.tags
      .split(RegExp(r'[,\s]+'))
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList(growable: false);

  return <String, dynamic>{
    'sort': filters.sort,
    'isLocal': filters.isLocal,
    'nsfw': filters.nsfw == null ? 'both' : (filters.nsfw! ? 'true' : 'false'),
    'categoryOneOf': filters.categories.isEmpty ? null : filters.categories.toList(),
    'licenceOneOf': filters.licences.isEmpty ? null : filters.licences.toList(),
    'languageOneOf': filters.languages.isEmpty ? null : filters.languages.toList(),
    'tagsOneOf': tags.isEmpty ? null : tags,
    'isLive': filters.liveOnly ? true : null,
  };
}

/// Small helper used by the channel/account screens to describe a video count.
String videoCountLabel(int? count) {
  if (count == null) return '';
  if (count <= 0) return '暂无视频';
  return '$count 个视频';
}

/// Describes a [VideoConstant] list as chips (used in the about panels).
List<Widget> constantChips(List<VideoConstant> values) {
  return values
      .map((VideoConstant value) => Chip(label: Text(value.label)))
      .toList(growable: false);
}
