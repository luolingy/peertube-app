import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../data/peertube_api.dart';
import 'session_controller.dart';

/// Keeps track of the number of unread notifications.
///
/// Polls the API while a user is logged in so the navigation bar can show a
/// badge. PeerTube has no push channel for third party clients, so polling is
/// the pragmatic option.
class NotificationsController extends ChangeNotifier {
  NotificationsController({
    required this.api,
    required this.store,
    required this.session,
  });

  final PeertubeApi api;
  final LocalStore store;
  final SessionController session;

  static const Duration pollInterval = Duration(seconds: 60);

  Timer? _timer;
  int _unreadCount = 0;
  bool _fetching = false;

  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  /// Starts polling (idempotent).
  void start() {
    _timer ??= Timer.periodic(pollInterval, (_) => refresh());
    refresh();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    if (_fetching) return;

    if (!session.isLoggedIn) {
      if (_unreadCount != 0) {
        _unreadCount = 0;
        notifyListeners();
      }
      return;
    }

    _fetching = true;
    try {
      final page = await api.listNotifications(start: 0, count: 1, unread: true);
      final count = page.total;
      if (count != _unreadCount) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {
      // A transient failure must not break the badge.
    } finally {
      _fetching = false;
    }
  }

  /// Clears the badge immediately after a "mark all as read" action.
  void clear() {
    if (_unreadCount == 0) return;
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
