import 'package:flutter/foundation.dart';

import '../data/peertube_api.dart';
import 'session_controller.dart';

/// Caches and toggles subscription state for accounts and channels.
///
/// PeerTube exposes subscriptions as a flat list of `name@host` URIs, so a
/// single store keyed by URI lets every screen (watch page, channel page,
/// account page, ...) share the same state.
class SubscriptionStore extends ChangeNotifier {
  SubscriptionStore({required this.api, required this.session});

  final PeertubeApi api;
  final SessionController session;

  final Map<String, bool> _cache = <String, bool>{};
  final Set<String> _pending = <String>{};

  bool isSubscribed(String uri) => _cache[uri] ?? false;
  bool isKnown(String uri) => _cache.containsKey(uri);
  bool isPending(String uri) => _pending.contains(uri);

  /// Resolves the subscription state of the given URIs (batched).
  Future<void> ensureKnown(Iterable<String> uris) async {
    if (!session.isLoggedIn) return;

    final unknown = uris
        .where((String uri) => uri.isNotEmpty && !_cache.containsKey(uri))
        .toSet();
    if (unknown.isEmpty) return;

    try {
      final result = await api.subscriptionsExist(unknown);
      result.forEach((String uri, bool exists) => _cache[uri] = exists);
      notifyListeners();
    } catch (_) {
      // Offline or unauthenticated: the button simply stays in "not subscribed".
    }
  }

  /// Subscribes or unsubscribes. Returns the new state.
  Future<bool> toggle(String uri) async {
    if (uri.isEmpty) return false;
    if (!session.isLoggedIn) {
      throw StateError('login_required');
    }
    if (_pending.contains(uri)) return isSubscribed(uri);

    final currentlySubscribed = isSubscribed(uri);
    _pending.add(uri);
    notifyListeners();

    try {
      if (currentlySubscribed) {
        await api.unsubscribe(uri);
        _cache[uri] = false;
        return false;
      }

      try {
        await api.subscribe(uri);
      } catch (error) {
        // 409 means the subscription already exists on the server.
        final message = error.toString();
        if (!message.contains('409')) rethrow;
      }
      _cache[uri] = true;
      return true;
    } finally {
      _pending.remove(uri);
      notifyListeners();
    }
  }

  /// Clears everything (used on logout).
  void clear() {
    _cache.clear();
    _pending.clear();
    notifyListeners();
  }
}
