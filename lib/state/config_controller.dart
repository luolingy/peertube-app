import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/local_store.dart';
import '../data/peertube_api.dart';
import '../models/server_config.dart';

/// Loads and caches `GET /config` for the configured instance.
class ConfigController extends ChangeNotifier {
  ConfigController({required this.api, required this.store, required this.client});

  final PeertubeApi api;
  final LocalStore store;
  final ApiClient client;

  ServerConfig? _config;
  bool _loading = false;
  Object? _error;

  ServerConfig get config => _config ?? ServerConfig.empty;
  bool get isReady => _config != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  String get baseUrl => client.baseUrl;
  String get instanceHost => store.instanceHost;

  /// Display name of the instance, falling back to the host.
  String get instanceName {
    final name = config.instance.name;
    if (name.trim().isNotEmpty) return name;
    return store.cachedInstanceName ?? instanceHost;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _config = await api.getConfig();
      store.cachedInstanceName = _config?.instance.name;
      _error = null;
    } catch (error) {
      _error = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => load();

  /// Points the client at another instance and reloads its configuration.
  Future<void> changeInstance(String baseUrl) async {
    await client.setBaseUrl(baseUrl);
    await store.clearTokens();
    _config = null;
    notifyListeners();
    await load();
  }

  /// True when the instance is reachable (used by the connection banner).
  bool get isReachable => _config != null;

  /// Instance logo URL, if the server advertises one.
  String? get logoUrl {
    final logos = config.instance.logoUrls;
    if (logos.isEmpty) return null;
    return logos.first;
  }
}
