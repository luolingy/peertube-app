import 'package:flutter/foundation.dart';

import '../data/local_store.dart';

/// User preferences: theme, player defaults and browse defaults.
///
/// Every value is persisted through [LocalStore] and the controller notifies
/// listeners so the UI can react immediately.
class SettingsController extends ChangeNotifier {
  SettingsController({required this.store});

  final LocalStore store;

  String get baseUrl => store.baseUrl;
  String get instanceHost => store.instanceHost;

  String get themeMode => store.themeMode;
  set themeMode(String value) {
    if (store.themeMode == value) return;
    store.themeMode = value;
    notifyListeners();
  }

  bool get autoplay => store.autoplay;
  set autoplay(bool value) {
    store.autoplay = value;
    notifyListeners();
  }

  bool get autoplayNext => store.autoplayNext;
  set autoplayNext(bool value) {
    store.autoplayNext = value;
    notifyListeners();
  }

  double get playbackRate => store.playbackRate;
  set playbackRate(double value) {
    store.playbackRate = value;
    notifyListeners();
  }

  double get volume => store.volume;
  set volume(double value) {
    store.volume = value;
    notifyListeners();
  }

  bool get muted => store.muted;
  set muted(bool value) {
    store.muted = value;
    notifyListeners();
  }

  bool get historyEnabled => store.historyEnabled;
  set historyEnabled(bool value) {
    store.historyEnabled = value;
    notifyListeners();
  }

  String get defaultScope => store.defaultScope;
  set defaultScope(String value) {
    store.defaultScope = value;
    notifyListeners();
  }

  String get defaultSort => store.defaultSort;
  set defaultSort(String value) {
    store.defaultSort = value;
    notifyListeners();
  }

  String get defaultSearchSort => store.defaultSearchSort;
  set defaultSearchSort(String value) {
    store.defaultSearchSort = value;
    notifyListeners();
  }

  String get defaultChannelSort => store.defaultChannelSort;
  set defaultChannelSort(String value) {
    store.defaultChannelSort = value;
    notifyListeners();
  }

  String get defaultPlaylistSort => store.defaultPlaylistSort;
  set defaultPlaylistSort(String value) {
    store.defaultPlaylistSort = value;
    notifyListeners();
  }

  String get commentsSort => store.commentsSort;
  set commentsSort(String value) {
    store.commentsSort = value;
    notifyListeners();
  }

  int get defaultPrivacy => store.defaultPrivacy;
  set defaultPrivacy(int value) {
    store.defaultPrivacy = value;
    notifyListeners();
  }

  int? get defaultChannelId => store.defaultChannelId;
  set defaultChannelId(int? value) {
    store.defaultChannelId = value;
    notifyListeners();
  }

  /// Resets every preference (but keeps the session).
  void resetPreferences() {
    store
      ..themeMode = 'system'
      ..autoplay = true
      ..autoplayNext = true
      ..playbackRate = 1.0
      ..volume = 1.0
      ..muted = false
      ..historyEnabled = true
      ..defaultScope = 'federated'
      ..defaultSort = '-publishedAt'
      ..defaultSearchSort = '-match'
      ..defaultChannelSort = '-match'
      ..defaultPlaylistSort = '-match'
      ..commentsSort = '-createdAt'
      ..defaultPrivacy = 1
      ..defaultChannelId = null;
    notifyListeners();
  }
}
