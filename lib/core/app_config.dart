/// Compile-time configuration of the client.
///
/// The whole app targets a single PeerTube instance, but the base URL is kept
/// configurable at runtime (see `SettingsController`) so that the same binary
/// can be pointed at a mirror or a local development server.
class AppConfig {
  AppConfig._();

  /// Default instance host this client was built for.
  static const String defaultHost = 'tv.bi';
  static const String defaultScheme = 'https';

  /// Absolute default base URL, without a trailing slash.
  static const String defaultBaseUrl = '$defaultScheme://$defaultHost';

  /// Path prefix of the PeerTube REST API.
  static const String apiPrefix = '/api/v1';

  static const String appTitle = '哔TV';
  static const String appVersion = '1.0.0';

  /// PeerTube asks clients to identify themselves with a meaningful UA.
  static const String userAgent = 'PeerTubeFlutterClient/1.0.0 (+https://$defaultHost)';

  /// Default page size used by every paginated list.
  static const int pageSize = 20;

  /// Base URL of the "official" web client, used to open pages we do not
  /// reimplement natively (plugin pages, admin plugin settings, ...).
  static String webUrlFor(String baseUrl) => baseUrl;
}
