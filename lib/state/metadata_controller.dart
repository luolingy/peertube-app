import 'package:flutter/foundation.dart';

import '../core/option_lists.dart';
import '../data/peertube_api.dart';
import '../models/video.dart';

/// Loads the instance's category / licence / language / privacy dictionaries
/// once and keeps them available to every filter and edit form.
class MetadataController extends ChangeNotifier {
  MetadataController({required this.api});

  final PeertubeApi api;

  List<IdOption> categories = const <IdOption>[];
  List<IdOption> licences = const <IdOption>[];
  List<OptionItem> languages = const <OptionItem>[];
  List<IdOption> privacies = kVideoPrivacies;
  List<IdOption> playlistPrivacies = kPlaylistPrivacies;

  bool _loading = false;
  bool _loaded = false;

  bool get isLoading => _loading;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loading || _loaded) return;
    _loading = true;
    notifyListeners();

    try {
      final results = await Future.wait(<Future<List<VideoConstant>>>[
        api.getVideoConstants('categories'),
        api.getVideoConstants('licences'),
        api.getVideoConstants('languages'),
        api.getVideoConstants('privacies'),
      ]);

      categories = _toIdOptions(results[0], const <IdOption>[]);
      licences = _toIdOptions(results[1], const <IdOption>[]);
      languages = results[2]
          .map((VideoConstant c) => OptionItem(c.key, c.label))
          .where((OptionItem option) => option.value.isNotEmpty)
          .toList(growable: false);
      if (results[3].isNotEmpty) {
        privacies = results[3]
            .map((VideoConstant c) => IdOption(c.id ?? 0, c.label))
            .where((IdOption o) => o.id > 0)
            .toList(growable: false);
      }

      try {
        final playlistPrivaciesResult = await api.listPlaylistPrivacies();
        if (playlistPrivaciesResult.isNotEmpty) {
          playlistPrivacies = playlistPrivaciesResult
              .map((VideoConstant c) => IdOption(c.id ?? 0, c.label))
              .where((IdOption o) => o.id > 0)
              .toList(growable: false);
        }
      } catch (_) {
        // Keep the built-in fallback.
      }

      _loaded = true;
    } catch (_) {
      // The dictionaries are a nicety: forms fall back to their defaults.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<IdOption> _toIdOptions(List<VideoConstant> values, List<IdOption> fallback) {
    final options = values
        .where((VideoConstant c) => c.id != null && c.id! > 0)
        .map((VideoConstant c) => IdOption(c.id!, c.label))
        .toList(growable: false);
    return options.isEmpty ? fallback : options;
  }

  String categoryLabel(int? id) {
    if (id == null) return '未分类';
    for (final option in categories) {
      if (option.id == id) return option.label;
    }
    return '未分类';
  }

  String licenceLabel(int? id) {
    if (id == null) return '未知许可';
    for (final option in licences) {
      if (option.id == id) return option.label;
    }
    return '未知许可';
  }

  String privacyLabel(int? id) {
    for (final option in privacies) {
      if (option.id == id) return option.label;
    }
    return '公开';
  }

  String languageLabel(String? code) {
    if (code == null || code.isEmpty) return '未知语言';
    for (final option in languages) {
      if (option.value == code) return option.label;
    }
    return code;
  }
}
