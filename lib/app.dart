import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/theme.dart';
import 'router/app_router.dart';
import 'state/config_controller.dart';
import 'state/notifications_controller.dart';
import 'state/session_controller.dart';
import 'state/settings_controller.dart';

/// Root widget: wires the router, the theme and the startup sequence.
class PeerTubeApp extends StatefulWidget {
  const PeerTubeApp({super.key});

  @override
  State<PeerTubeApp> createState() => _PeerTubeAppState();
}

class _PeerTubeAppState extends State<PeerTubeApp> {
  late final RouterConfig<Object> _router = createRouter();

  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped || !mounted) return;
    _bootstrapped = true;

    final config = context.read<ConfigController>();
    final session = context.read<SessionController>();
    final notifications = context.read<NotificationsController>();

    await config.load();
    await session.bootstrap();

    if (!mounted) return;
    if (session.isLoggedIn) notifications.start();

    // Keep the badge polling in sync with the login state.
    session.addListener(() {
      if (!mounted) return;
      if (session.isLoggedIn) {
        notifications.start();
      } else {
        notifications.stop();
        notifications.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final config = context.watch<ConfigController>();

    final seed = parseHexColor(config.config.theme.primaryColor) ?? kDefaultSeed;
    final title = config.instanceName.trim().isEmpty
        ? AppConfig.appTitle
        : config.instanceName;

    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      themeMode: switch (settings.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      theme: buildAppTheme(brightness: Brightness.light, seedColor: seed),
      darkTheme: buildAppTheme(brightness: Brightness.dark, seedColor: seed),
      locale: const Locale('zh'),
      supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
