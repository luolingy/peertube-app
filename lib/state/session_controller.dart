import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../data/local_store.dart';
import '../data/peertube_api.dart';
import '../models/actor.dart';

/// Owns the authenticated session: the OAuth tokens (through [LocalStore]) and
/// the currently logged in [User].
class SessionController extends ChangeNotifier {
  SessionController({required this.api, required this.store});

  final PeertubeApi api;
  final LocalStore store;

  User? _me;
  bool _loading = false;
  Object? _error;
  bool _booting = true;

  User? get me => _me;
  bool get isLoggedIn => _me != null;
  bool get isLoading => _loading;
  bool get isBooting => _booting;
  Object? get error => _error;
  bool get isAdmin => _me?.isAdmin ?? false;
  bool get isModerator => _me?.isModerator ?? false;
  List<VideoChannel> get myChannels => _me?.videoChannels ?? const <VideoChannel>[];
  Account? get myAccount => _me?.account;
  int? get myAccountId => _me?.account.id;

  /// Restores the session at startup (silently).
  Future<void> bootstrap() async {
    _booting = true;
    notifyListeners();

    if (store.isLoggedIn) {
      await refreshMe(silent: true);
    }

    _booting = false;
    notifyListeners();
  }

  /// Reloads `GET /users/me`.
  Future<void> refreshMe({bool silent = false}) async {
    if (!store.isLoggedIn) {
      _me = null;
      if (!silent) notifyListeners();
      return;
    }

    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _me = await api.getMe();
      _error = null;
    } catch (error) {
      _error = error;
      if (error is ApiException && error.isUnauthorized) {
        await store.clearTokens();
        _me = null;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Logs in with username/password (plus an optional 2FA code).
  Future<void> login({
    required String username,
    required String password,
    String? otp,
  }) async {
    await api.client.login(username: username, password: password, otp: otp);
    await refreshMe();
  }

  /// Registers a new account. When the instance requires approval the account
  /// is created but not usable until a moderator accepts it.
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    String? displayName,
    String? channelName,
    String? channelDisplayName,
  }) async {
    return api.register(
      username: username,
      password: password,
      email: email,
      displayName: displayName,
      channelName: channelName,
      channelDisplayName: channelDisplayName,
    );
  }

  Future<void> logout() async {
    await api.client.logout();
    _me = null;
    notifyListeners();
  }

  /// Called by the API client when the refresh token is rejected.
  void handleSessionExpired() {
    _me = null;
    notifyListeners();
  }

  /// Applies a profile change and refreshes the cached user.
  Future<void> updateProfile({
    String? email,
    String? currentPassword,
    String? password,
    String? displayName,
    String? description,
    String? nsfwPolicy,
    bool? p2pEnabled,
    bool? autoPlayVideo,
    bool? autoPlayNextVideo,
    bool? autoPlayNextVideoPlaylist,
    bool? videosHistoryEnabled,
    String? theme,
    Map<String, dynamic>? notificationSettings,
  }) async {
    await api.updateMe(
      email: email,
      currentPassword: currentPassword,
      password: password,
      displayName: displayName,
      description: description,
      nsfwPolicy: nsfwPolicy,
      p2pEnabled: p2pEnabled,
      autoPlayVideo: autoPlayVideo,
      autoPlayNextVideo: autoPlayNextVideo,
      autoPlayNextVideoPlaylist: autoPlayNextVideoPlaylist,
      videosHistoryEnabled: videosHistoryEnabled,
      theme: theme,
      notificationSettings: notificationSettings,
    );
    await refreshMe(silent: true);
  }

  Future<void> uploadAvatar({String? path, List<int>? bytes, String? filename}) async {
    await api.uploadMyAvatar(
      path: path,
      bytes: bytes == null ? null : Uint8List.fromList(bytes),
      filename: filename ?? 'avatar.png',
    );
    await refreshMe(silent: true);
  }

  Future<void> deleteAvatar() async {
    await api.deleteMyAvatar();
    await refreshMe(silent: true);
  }

  Future<void> deleteAccount(String password) async {
    await api.deleteMe(password);
    _me = null;
    notifyListeners();
  }
}
