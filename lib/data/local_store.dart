import 'package:shared_preferences/shared_preferences.dart';

/// Persisted client state: instance URL, OAuth tokens and user preferences.
///
/// Everything is stored through `shared_preferences`, which is available on
/// every platform the app supports (including web, where it maps to
/// localStorage).
class LocalStore {
  LocalStore(this._prefs);

  static Future<LocalStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore(prefs);
  }

  final SharedPreferences _prefs;

  // --- keys ---------------------------------------------------------------
  static const String _kBaseUrl = 'instance.base_url';
  static const String _kAccessToken = 'auth.access_token';
  static const String _kRefreshToken = 'auth.refresh_token';
  static const String _kTokenExpiry = 'auth.token_expiry';
  static const String _kClientId = 'auth.client_id';
  static const String _kClientSecret = 'auth.client_secret';
  static const String _kThemeMode = 'ui.theme_mode';
  static const String _kLocale = 'ui.locale';
  static const String _kAutoplay = 'player.autoplay';
  static const String _kAutoplayNext = 'player.autoplay_next';
  static const String _kPlaybackRate = 'player.rate';
  static const String _kVolume = 'player.volume';
  static const String _kMuted = 'player.muted';
  static const String _kDefaultScope = 'browse.scope';
  static const String _kDefaultSort = 'browse.sort';
  static const String _kDefaultSearchSort = 'search.sort';
  static const String _kDefaultChannelSort = 'search.channel_sort';
  static const String _kDefaultPlaylistSort = 'search.playlist_sort';
  static const String _kCommentsSort = 'comments.sort';
  static const String _kDefaultPrivacy = 'upload.privacy';
  static const String _kDefaultChannel = 'upload.channel';
  static const String _kLatestInstanceName = 'cache.instance_name';
  static const String _kBroadcastDismissed = 'cache.broadcast_dismissed';
  static const String _kLastNotificationId = 'cache.last_notification_id';
  static const String _kHistoryEnabled = 'history.enabled';
  static const String _kLastRoute = 'ui.last_route';

  SharedPreferences get prefs => _prefs;

  // --- instance -----------------------------------------------------------

  /// Base URL of the instance, without a trailing slash.
  String get baseUrl {
    final raw = _prefs.getString(_kBaseUrl);
    if (raw == null || raw.trim().isEmpty) return _defaultBaseUrl;
    return normalizeBaseUrl(raw);
  }

  set baseUrl(String value) => _prefs.setString(_kBaseUrl, normalizeBaseUrl(value));

  static String _defaultBaseUrl = 'https://tv.bi';

  /// Allows the app to inject its compile-time default (see `AppConfig`).
  static void setDefaultBaseUrl(String value) {
    _defaultBaseUrl = normalizeBaseUrl(value);
  }

  /// Accepts `tv.bi`, `https://tv.bi/`, `http://localhost:9000` ...
  static String normalizeBaseUrl(String input) {
    var value = input.trim();
    if (value.isEmpty) return _defaultBaseUrl;

    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      final isLocal = value.startsWith('localhost') || value.startsWith('127.0.0.1');
      value = '${isLocal ? 'http' : 'https'}://$value';
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  String get instanceHost => Uri.tryParse(baseUrl)?.host ?? baseUrl;

  // --- authentication -----------------------------------------------------

  String? get accessToken => _prefs.getString(_kAccessToken);
  String? get refreshToken => _prefs.getString(_kRefreshToken);
  String? get oauthClientId => _prefs.getString(_kClientId);
  String? get oauthClientSecret => _prefs.getString(_kClientSecret);

  bool get isLoggedIn => (accessToken ?? '').isNotEmpty;
  bool get hasRefreshToken => (refreshToken ?? '').isNotEmpty;

  DateTime? get tokenExpiry {
    final millis = _prefs.getInt(_kTokenExpiry);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  bool get isAccessTokenExpired {
    final expiry = tokenExpiry;
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 2)));
  }

  Future<void> saveTokens({
    required String accessToken,
    required String? refreshToken,
    int? expiresInSeconds,
    int? refreshExpiresInSeconds,
  }) async {
    await _prefs.setString(_kAccessToken, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _prefs.setString(_kRefreshToken, refreshToken);
    }
    if (expiresInSeconds != null) {
      await _prefs.setInt(
        _kTokenExpiry,
        DateTime.now().add(Duration(seconds: expiresInSeconds)).millisecondsSinceEpoch,
      );
    }
  }

  Future<void> saveOAuthClient({required String clientId, required String clientSecret}) async {
    await _prefs.setString(_kClientId, clientId);
    await _prefs.setString(_kClientSecret, clientSecret);
  }

  Future<void> clearTokens() async {
    await _prefs.remove(_kAccessToken);
    await _prefs.remove(_kRefreshToken);
    await _prefs.remove(_kTokenExpiry);
  }

  // --- preferences --------------------------------------------------------

  String get themeMode => _prefs.getString(_kThemeMode) ?? 'system';
  set themeMode(String value) => _prefs.setString(_kThemeMode, value);

  String get locale => _prefs.getString(_kLocale) ?? 'zh';
  set locale(String value) => _prefs.setString(_kLocale, value);

  bool get autoplay => _prefs.getBool(_kAutoplay) ?? true;
  set autoplay(bool value) => _prefs.setBool(_kAutoplay, value);

  bool get autoplayNext => _prefs.getBool(_kAutoplayNext) ?? true;
  set autoplayNext(bool value) => _prefs.setBool(_kAutoplayNext, value);

  double get playbackRate => _prefs.getDouble(_kPlaybackRate) ?? 1.0;
  set playbackRate(double value) => _prefs.setDouble(_kPlaybackRate, value);

  double get volume => _prefs.getDouble(_kVolume) ?? 1.0;
  set volume(double value) => _prefs.setDouble(_kVolume, value);

  bool get muted => _prefs.getBool(_kMuted) ?? false;
  set muted(bool value) => _prefs.setBool(_kMuted, value);

  bool get historyEnabled => _prefs.getBool(_kHistoryEnabled) ?? true;
  set historyEnabled(bool value) => _prefs.setBool(_kHistoryEnabled, value);

  String get defaultScope => _prefs.getString(_kDefaultScope) ?? 'federated';
  set defaultScope(String value) => _prefs.setString(_kDefaultScope, value);

  String get defaultSort => _prefs.getString(_kDefaultSort) ?? '-publishedAt';
  set defaultSort(String value) => _prefs.setString(_kDefaultSort, value);

  String get defaultSearchSort => _prefs.getString(_kDefaultSearchSort) ?? '-match';
  set defaultSearchSort(String value) => _prefs.setString(_kDefaultSearchSort, value);

  String get defaultChannelSort => _prefs.getString(_kDefaultChannelSort) ?? '-match';
  set defaultChannelSort(String value) => _prefs.setString(_kDefaultChannelSort, value);

  String get defaultPlaylistSort => _prefs.getString(_kDefaultPlaylistSort) ?? '-match';
  set defaultPlaylistSort(String value) => _prefs.setString(_kDefaultPlaylistSort, value);

  String get commentsSort => _prefs.getString(_kCommentsSort) ?? '-createdAt';
  set commentsSort(String value) => _prefs.setString(_kCommentsSort, value);

  int get defaultPrivacy => _prefs.getInt(_kDefaultPrivacy) ?? 1;
  set defaultPrivacy(int value) => _prefs.setInt(_kDefaultPrivacy, value);

  int? get defaultChannelId => _prefs.getInt(_kDefaultChannel);
  set defaultChannelId(int? value) {
    if (value == null) {
      _prefs.remove(_kDefaultChannel);
    } else {
      _prefs.setInt(_kDefaultChannel, value);
    }
  }

  String? get cachedInstanceName => _prefs.getString(_kLatestInstanceName);
  set cachedInstanceName(String? value) {
    if (value == null) {
      _prefs.remove(_kLatestInstanceName);
    } else {
      _prefs.setString(_kLatestInstanceName, value);
    }
  }

  String? get dismissedBroadcast => _prefs.getString(_kBroadcastDismissed);
  set dismissedBroadcast(String? value) {
    if (value == null) {
      _prefs.remove(_kBroadcastDismissed);
    } else {
      _prefs.setString(_kBroadcastDismissed, value);
    }
  }

  int get lastNotificationId => _prefs.getInt(_kLastNotificationId) ?? 0;
  set lastNotificationId(int value) => _prefs.setInt(_kLastNotificationId, value);

  String? get lastRoute => _prefs.getString(_kLastRoute);
  set lastRoute(String? value) {
    if (value == null) {
      _prefs.remove(_kLastRoute);
    } else {
      _prefs.setString(_kLastRoute, value);
    }
  }

  /// Wipes every persisted value (used by "reset application").
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
