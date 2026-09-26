import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'data/api_client.dart';
import 'data/local_store.dart';
import 'data/peertube_api.dart';
import 'state/config_controller.dart';
import 'state/metadata_controller.dart';
import 'state/notifications_controller.dart';
import 'state/session_controller.dart';
import 'state/settings_controller.dart';
import 'state/subscription_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // `media_kit` needs its native bindings initialised before any player is
  // created; doing it here keeps every screen free of platform checks.
  MediaKit.ensureInitialized();

  // The compile-time default instance (tv.bi) is only used until the user
  // changes it in the settings screen.
  LocalStore.setDefaultBaseUrl(AppConfig.defaultBaseUrl);

  final store = await LocalStore.open();
  final client = ApiClient(store: store);
  final api = PeertubeApi(client: client);

  final session = SessionController(api: api, store: store);
  final config = ConfigController(api: api, store: store, client: client);
  final settings = SettingsController(store: store);
  final metadata = MetadataController(api: api);
  final subscriptions = SubscriptionStore(api: api, session: session);
  final notifications = NotificationsController(api: api, store: store, session: session);

  // A rejected refresh token logs the user out everywhere at once.
  client.onSessionExpired = () {
    session.handleSessionExpired();
    subscriptions.clear();
    notifications.clear();
  };

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalStore>.value(value: store),
        Provider<ApiClient>.value(value: client),
        Provider<PeertubeApi>.value(value: api),
        ChangeNotifierProvider<SessionController>.value(value: session),
        ChangeNotifierProvider<ConfigController>.value(value: config),
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<MetadataController>.value(value: metadata),
        ChangeNotifierProvider<SubscriptionStore>.value(value: subscriptions),
        ChangeNotifierProvider<NotificationsController>.value(value: notifications),
      ],
      child: const PeerTubeApp(),
    ),
  );
}
