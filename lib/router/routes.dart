/// Central definition of every route path used by the app.
///
/// Kept separate from the `GoRouter` configuration so widgets can build links
/// without importing the router itself.
class Routes {
  Routes._();

  // Shell tabs.
  static const String home = '/';
  static const String trending = '/trending';
  static const String browse = '/browse';
  static const String search = '/search';
  static const String library = '/library';

  // Content.
  static const String watch = '/watch';
  static String watchVideo(String idOrUuid) => '/watch/$idOrUuid';

  static const String channel = '/c';
  static String channelByHandle(String handle) => '/c/$handle';

  static const String account = '/a';
  static String accountByHandle(String handle) => '/a/$handle';

  static const String playlist = '/playlist';
  static String playlistById(Object id) => '/playlist/$id';

  // Authentication.
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Library.
  static const String myVideos = '/library/videos';
  static const String myHistory = '/library/history';
  static const String mySubscriptions = '/library/subscriptions';
  static const String myPlaylists = '/library/playlists';
  static const String myImports = '/library/imports';
  static const String notifications = '/library/notifications';
  static const String myAbuses = '/library/abuses';
  static const String myAccount = '/library/account';
  static const String notificationSettings = '/library/account/notifications';
  static const String twoFactor = '/library/account/two-factor';
  static const String tokenSessions = '/library/account/sessions';

  // Publishing.
  static const String upload = '/upload';
  static const String goLive = '/go-live';
  static const String videoEdit = '/manage/video';
  static String editVideo(String idOrUuid) => '/manage/video/$idOrUuid';

  static const String channelCreate = '/manage/channel/create';
  static const String channelEdit = '/manage/channel';
  static String editChannel(String handle) => '/manage/channel/$handle';

  static const String playlistEdit = '/manage/playlist';
  static String editPlaylist(Object id) => '/manage/playlist/$id';

  // Instance.
  static const String settings = '/settings';
  static const String about = '/about';
  static const String instanceFollows = '/about/follows';
  static const String plugins = '/about/plugins';
  static const String statistics = '/about/statistics';
  static const String contact = '/about/contact';

  // Administration.
  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminAbuses = '/admin/abuses';
  static const String adminJobs = '/admin/jobs';
  static const String adminPlugins = '/admin/plugins';
  static const String adminLogs = '/admin/logs';
  static const String adminRegistrations = '/admin/registrations';
  static const String adminBlocklist = '/admin/blocklist';
  static const String adminConfig = '/admin/config';
}
