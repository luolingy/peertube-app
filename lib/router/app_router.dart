import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/about/about_screen.dart';
import '../screens/actors/account_screen.dart';
import '../screens/actors/channel_screen.dart';
import '../screens/admin/admin_screens.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/browse/browse_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/library/my_abuses_screen.dart';
import '../screens/library/my_account_screen.dart';
import '../screens/library/my_history_screen.dart';
import '../screens/library/my_imports_screen.dart';
import '../screens/library/my_playlists_screen.dart';
import '../screens/library/my_subscriptions_screen.dart';
import '../screens/library/my_videos_screen.dart';
import '../screens/library/notifications_screen.dart';
import '../screens/playlist/playlist_screen.dart';
import '../screens/publish/go_live_screen.dart';
import '../screens/publish/playlist_edit_screen.dart';
import '../screens/publish/upload_screen.dart';
import '../screens/publish/video_edit_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/watch/video_watch_screen.dart';
import 'routes.dart';

/// Builds the application router.
///
/// The four primary destinations live inside a [MainShell] (bottom navigation
/// bar or navigation rail), while every secondary page is pushed on top of it.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: Routes.home,
    routes: <RouteBase>[
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) => MainShell(
          location: state.uri.toString(),
          child: child,
        ),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.home,
            builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
          ),
          GoRoute(
            path: Routes.browse,
            builder: (BuildContext context, GoRouterState state) => const BrowseScreen(),
          ),
          GoRoute(
            path: Routes.search,
            builder: (BuildContext context, GoRouterState state) => SearchScreen(
              initialQuery: state.uri.queryParameters['q'],
            ),
          ),
          GoRoute(
            path: Routes.library,
            builder: (BuildContext context, GoRouterState state) => const LibraryScreen(),
          ),
        ],
      ),

      // --- content ---------------------------------------------------------
      GoRoute(
        path: '${Routes.watch}/:id',
        builder: (BuildContext context, GoRouterState state) => VideoWatchScreen(
          videoId: state.pathParameters['id'] ?? '',
          playlistId: int.tryParse(state.uri.queryParameters['playlist'] ?? ''),
          playlistElementId: int.tryParse(state.uri.queryParameters['element'] ?? ''),
        ),
      ),
      GoRoute(
        path: '${Routes.channel}/:handle',
        builder: (BuildContext context, GoRouterState state) =>
            ChannelScreen(handle: state.pathParameters['handle'] ?? ''),
      ),
      GoRoute(
        path: '${Routes.account}/:handle',
        builder: (BuildContext context, GoRouterState state) =>
            AccountScreen(handle: state.pathParameters['handle'] ?? ''),
      ),
      GoRoute(
        path: '${Routes.playlist}/:id',
        builder: (BuildContext context, GoRouterState state) =>
            PlaylistScreen(playlistId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
      ),

      // --- authentication ---------------------------------------------------
      GoRoute(
        path: Routes.login,
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.signup,
        builder: (BuildContext context, GoRouterState state) => const SignupScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (BuildContext context, GoRouterState state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.resetPassword,
        builder: (BuildContext context, GoRouterState state) => const ForgotPasswordScreen(),
      ),

      // --- library ----------------------------------------------------------
      GoRoute(
        path: Routes.myVideos,
        builder: (BuildContext context, GoRouterState state) => const MyVideosScreen(),
      ),
      GoRoute(
        path: Routes.myHistory,
        builder: (BuildContext context, GoRouterState state) => const MyHistoryScreen(),
      ),
      GoRoute(
        path: Routes.mySubscriptions,
        builder: (BuildContext context, GoRouterState state) => const MySubscriptionsScreen(),
      ),
      GoRoute(
        path: Routes.myPlaylists,
        builder: (BuildContext context, GoRouterState state) => const MyPlaylistsScreen(),
      ),
      GoRoute(
        path: Routes.myImports,
        builder: (BuildContext context, GoRouterState state) => const MyImportsScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (BuildContext context, GoRouterState state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.myAbuses,
        builder: (BuildContext context, GoRouterState state) => const MyAbusesScreen(),
      ),
      GoRoute(
        path: Routes.myAccount,
        builder: (BuildContext context, GoRouterState state) => const MyAccountScreen(),
      ),
      GoRoute(
        path: Routes.notificationSettings,
        builder: (BuildContext context, GoRouterState state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: Routes.twoFactor,
        builder: (BuildContext context, GoRouterState state) => const TwoFactorScreen(),
      ),
      GoRoute(
        path: Routes.tokenSessions,
        builder: (BuildContext context, GoRouterState state) => const TokenSessionsScreen(),
      ),

      // --- publishing -------------------------------------------------------
      GoRoute(
        path: Routes.upload,
        builder: (BuildContext context, GoRouterState state) => const UploadScreen(),
      ),
      GoRoute(
        path: Routes.goLive,
        builder: (BuildContext context, GoRouterState state) => const GoLiveScreen(),
      ),
      GoRoute(
        path: '${Routes.videoEdit}/:id',
        builder: (BuildContext context, GoRouterState state) =>
            VideoEditScreen(videoId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: Routes.channelCreate,
        builder: (BuildContext context, GoRouterState state) => const ChannelEditScreen(),
      ),
      GoRoute(
        path: '${Routes.channelEdit}/:handle',
        builder: (BuildContext context, GoRouterState state) =>
            ChannelEditScreen(handle: state.pathParameters['handle']),
      ),
      GoRoute(
        path: '${Routes.playlistEdit}/:id',
        builder: (BuildContext context, GoRouterState state) => PlaylistEditScreen(
          playlistId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),

      // --- instance ---------------------------------------------------------
      GoRoute(
        path: Routes.settings,
        builder: (BuildContext context, GoRouterState state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.about,
        builder: (BuildContext context, GoRouterState state) => const AboutScreen(),
      ),
      GoRoute(
        path: Routes.instanceFollows,
        builder: (BuildContext context, GoRouterState state) => const InstanceFollowsScreen(),
      ),
      GoRoute(
        path: Routes.plugins,
        builder: (BuildContext context, GoRouterState state) => const PluginsScreen(),
      ),
      GoRoute(
        path: Routes.statistics,
        builder: (BuildContext context, GoRouterState state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: Routes.contact,
        builder: (BuildContext context, GoRouterState state) => const ContactScreen(),
      ),

      // --- administration ---------------------------------------------------
      GoRoute(
        path: Routes.admin,
        builder: (BuildContext context, GoRouterState state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: Routes.adminAbuses,
        builder: (BuildContext context, GoRouterState state) => const AdminAbusesScreen(),
      ),
      GoRoute(
        path: Routes.adminUsers,
        builder: (BuildContext context, GoRouterState state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: Routes.adminRegistrations,
        builder: (BuildContext context, GoRouterState state) => const AdminRegistrationsScreen(),
      ),
      GoRoute(
        path: Routes.adminJobs,
        builder: (BuildContext context, GoRouterState state) => const AdminJobsScreen(),
      ),
      GoRoute(
        path: Routes.adminPlugins,
        builder: (BuildContext context, GoRouterState state) => const AdminPluginsScreen(),
      ),
      GoRoute(
        path: Routes.adminLogs,
        builder: (BuildContext context, GoRouterState state) => const AdminLogsScreen(),
      ),
      GoRoute(
        path: Routes.adminBlocklist,
        builder: (BuildContext context, GoRouterState state) => const AdminBlocklistScreen(),
      ),
      GoRoute(
        path: Routes.adminConfig,
        builder: (BuildContext context, GoRouterState state) => const AdminConfigScreen(),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      appBar: AppBar(title: const Text('页面不存在')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.explore_off_rounded, size: 56),
            const SizedBox(height: 12),
            Text('找不到路径 ${state.uri}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
}
