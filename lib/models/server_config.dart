import 'actor.dart';
import 'json_utils.dart';

/// Instance level metadata (`GET /config`).
class InstanceInfo {
  const InstanceInfo({
    required this.name,
    required this.shortDescription,
    required this.isNSFW,
    required this.defaultNSFWPolicy,
    required this.serverCountry,
    required this.defaultLanguage,
    required this.supportText,
    this.social = const <String, String>{},
    this.customizations = const <String, String>{},
    this.avatars = const <ActorImage>[],
    this.banners = const <ActorImage>[],
    this.logoUrls = const <String>[],
  });

  final String name;
  final String shortDescription;
  final bool isNSFW;
  final String defaultNSFWPolicy;
  final String serverCountry;
  final String defaultLanguage;
  final String supportText;
  final Map<String, String> social;
  final Map<String, String> customizations;
  final List<ActorImage> avatars;
  final List<ActorImage> banners;
  final List<String> logoUrls;

  String? get externalLink => _firstNonEmpty([
        social['externalLink'],
        social['mastodonLink'],
        social['blueskyLink'],
        social['xLink'],
      ]);

  factory InstanceInfo.fromJson(Map<String, dynamic> json) {
    final socialRaw = jsonMap(json['social']);
    final customizationsRaw = jsonMap(json['customizations']);

    final logoUrls = <String>[];
    for (final logo in jsonMapList(json['logo'])) {
      final url = jsonStringOrNull(logo['fileUrl']);
      if (url != null && url.isNotEmpty) logoUrls.add(url);
    }

    return InstanceInfo(
      name: jsonString(json['name']),
      shortDescription: jsonString(json['shortDescription']),
      isNSFW: jsonBool(json['isNSFW']),
      defaultNSFWPolicy: jsonString(json['defaultNSFWPolicy'], 'do_not_list'),
      serverCountry: jsonString(json['serverCountry']),
      defaultLanguage: jsonString(json['defaultLanguage']),
      supportText: jsonString(jsonMap(json['support'])['text']),
      social: socialRaw.map((k, v) => MapEntry(k, jsonString(v))),
      customizations: customizationsRaw.map((k, v) => MapEntry(k, jsonString(v))),
      avatars: parseActorImages(json['avatars']),
      banners: parseActorImages(json['banners']),
      logoUrls: logoUrls,
    );
  }

  static const InstanceInfo empty = InstanceInfo(
    name: '',
    shortDescription: '',
    isNSFW: false,
    defaultNSFWPolicy: 'do_not_list',
    serverCountry: '',
    defaultLanguage: '',
    supportText: '',
  );
}

/// Theme/customisation values (`config.theme`).
class ThemeInfo {
  const ThemeInfo({
    this.defaultTheme = 'default',
    this.primaryColor,
    this.onPrimaryColor,
    this.foregroundColor,
    this.backgroundColor,
    this.backgroundSecondaryColor,
    this.menuForegroundColor,
    this.menuBackgroundColor,
    this.headerForegroundColor,
    this.headerBackgroundColor,
  });

  final String defaultTheme;
  final String? primaryColor;
  final String? onPrimaryColor;
  final String? foregroundColor;
  final String? backgroundColor;
  final String? backgroundSecondaryColor;
  final String? menuForegroundColor;
  final String? menuBackgroundColor;
  final String? headerForegroundColor;
  final String? headerBackgroundColor;

  factory ThemeInfo.fromJson(Map<String, dynamic> json) {
    final customization = jsonMap(json['customization']);
    return ThemeInfo(
      defaultTheme: jsonString(json['default'], 'default'),
      primaryColor: jsonStringOrNull(customization['primaryColor']),
      onPrimaryColor: jsonStringOrNull(customization['onPrimaryColor']),
      foregroundColor: jsonStringOrNull(customization['foregroundColor']),
      backgroundColor: jsonStringOrNull(customization['backgroundColor']),
      backgroundSecondaryColor: jsonStringOrNull(customization['backgroundSecondaryColor']),
      menuForegroundColor: jsonStringOrNull(customization['menuForegroundColor']),
      menuBackgroundColor: jsonStringOrNull(customization['menuBackgroundColor']),
      headerForegroundColor: jsonStringOrNull(customization['headerForegroundColor']),
      headerBackgroundColor: jsonStringOrNull(customization['headerBackgroundColor']),
    );
  }
}

/// Registration rules (`config.signup`).
class SignupInfo {
  const SignupInfo({
    this.allowed = false,
    this.allowedForCurrentIP = false,
    this.requiresApproval = false,
    this.requiresEmailVerification = false,
    this.minimumAge = 16,
  });

  final bool allowed;
  final bool allowedForCurrentIP;
  final bool requiresApproval;
  final bool requiresEmailVerification;
  final int minimumAge;

  bool get canRegister => allowed && allowedForCurrentIP;

  factory SignupInfo.fromJson(Map<String, dynamic> json) {
    return SignupInfo(
      allowed: jsonBool(json['allowed']),
      allowedForCurrentIP: jsonBool(json['allowedForCurrentIP']),
      requiresApproval: jsonBool(json['requiresApproval']),
      requiresEmailVerification: jsonBool(json['requiresEmailVerification']),
      minimumAge: jsonInt(json['minimumAge'], 16),
    );
  }
}

/// The full server configuration.
class ServerConfig {
  const ServerConfig({
    required this.serverVersion,
    required this.serverCommit,
    required this.instance,
    required this.theme,
    required this.signup,
    this.searchIndexUrl = '',
    this.searchIndexEnabled = false,
    this.videoQuota = 0,
    this.videoQuotaDaily = 0,
    this.maxChannelsPerUser = 20,
    this.liveEnabled = false,
    this.federationEnabled = true,
    this.homepageEnabled = false,
    this.storyboardsEnabled = false,
    this.importHttpEnabled = false,
    this.importTorrentEnabled = false,
    this.userImportEnabled = false,
    this.userExportEnabled = false,
    this.emailEnabled = false,
    this.contactFormEnabled = false,
    this.passwordMinLength = 6,
    this.passwordMaxLength = 50,
    this.avatarMaxSize = 8388608,
    this.bannerMaxSize = 8388608,
    this.captionMaxSize = 20971520,
    this.broadcastMessage = '',
    this.broadcastLevel = 'info',
    this.broadcastDismissable = false,
    this.registeredPlugins = const <Map<String, dynamic>>[],
    this.trendingAlgorithms = const <String>[],
    this.defaultTrendingAlgorithm = 'hot',
    this.raw = const <String, dynamic>{},
  });

  final String serverVersion;
  final String serverCommit;
  final InstanceInfo instance;
  final ThemeInfo theme;
  final SignupInfo signup;
  final String searchIndexUrl;
  final bool searchIndexEnabled;
  final int videoQuota;
  final int videoQuotaDaily;
  final int maxChannelsPerUser;
  final bool liveEnabled;
  final bool federationEnabled;
  final bool homepageEnabled;
  final bool storyboardsEnabled;
  final bool importHttpEnabled;
  final bool importTorrentEnabled;
  final bool userImportEnabled;
  final bool userExportEnabled;
  final bool emailEnabled;
  final bool contactFormEnabled;
  final int passwordMinLength;
  final int passwordMaxLength;
  final int avatarMaxSize;
  final int bannerMaxSize;
  final int captionMaxSize;
  final String broadcastMessage;
  final String broadcastLevel;
  final bool broadcastDismissable;
  final List<Map<String, dynamic>> registeredPlugins;
  final List<String> trendingAlgorithms;
  final String defaultTrendingAlgorithm;
  final Map<String, dynamic> raw;

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    final user = jsonMap(json['user']);
    final videoChannels = jsonMap(json['videoChannels']);
    final live = jsonMap(json['live']);
    final search = jsonMap(json['search']);
    final searchIndex = jsonMap(search['searchIndex']);
    final importSection = jsonMap(json['import']);
    final importVideos = jsonMap(importSection['videos']);
    final exportUsers = jsonMap(jsonMap(json['export'])['users']);
    final broadcast = jsonMap(json['broadcastMessage']);
    final constraints = jsonMap(jsonMap(jsonMap(json['fieldsConstraints'])['users'])['password']);
    final trendingVideos = jsonMap(jsonMap(json['trending'])['videos']);
    final algorithms = jsonMap(trendingVideos['algorithms']);

    return ServerConfig(
      serverVersion: jsonString(json['serverVersion']),
      serverCommit: jsonString(json['serverCommit']),
      instance: InstanceInfo.fromJson(jsonMap(json['instance'])),
      theme: ThemeInfo.fromJson(jsonMap(json['theme'])),
      signup: SignupInfo.fromJson(jsonMap(json['signup'])),
      searchIndexUrl: jsonString(searchIndex['url']),
      searchIndexEnabled: jsonBool(searchIndex['enabled']),
      videoQuota: jsonInt(user['videoQuota']),
      videoQuotaDaily: jsonInt(user['videoQuotaDaily']),
      maxChannelsPerUser: jsonInt(videoChannels['maxPerUser'], 20),
      liveEnabled: jsonBool(live['enabled']),
      federationEnabled: jsonBool(jsonMap(json['federation'])['enabled'], true),
      homepageEnabled: jsonBool(jsonMap(json['homepage'])['enabled']),
      storyboardsEnabled: jsonBool(jsonMap(json['storyboards'])['enabled']),
      importHttpEnabled: jsonBool(jsonMap(importVideos['http'])['enabled']),
      importTorrentEnabled: jsonBool(jsonMap(importVideos['torrent'])['enabled']),
      userImportEnabled: jsonBool(jsonMap(importSection['users'])['enabled']),
      userExportEnabled: jsonBool(exportUsers['enabled']),
      emailEnabled: jsonBool(jsonMap(json['email'])['enabled']),
      contactFormEnabled: jsonBool(jsonMap(json['contactForm'])['enabled']),
      passwordMinLength: jsonInt(constraints['minLength'], 6),
      passwordMaxLength: jsonInt(constraints['maxLength'], 50),
      avatarMaxSize: jsonInt(jsonMap(jsonMap(json['avatar'])['file'])['size'], 8388608),
      bannerMaxSize: jsonInt(jsonMap(jsonMap(json['banner'])['file'])['size'], 8388608),
      captionMaxSize: jsonInt(jsonMap(jsonMap(json['videoCaption'])['file'])['size'], 20971520),
      broadcastMessage: jsonString(broadcast['message']),
      broadcastLevel: jsonString(broadcast['level'], 'info'),
      broadcastDismissable: jsonBool(broadcast['dismissable']),
      registeredPlugins: jsonMapList(jsonMap(json['plugin'])['registered']),
      trendingAlgorithms: jsonStringList(algorithms['enabled']),
      defaultTrendingAlgorithm: jsonString(algorithms['default'], 'hot'),
      raw: json,
    );
  }

  static const ServerConfig empty = ServerConfig(
    serverVersion: '',
    serverCommit: '',
    instance: InstanceInfo.empty,
    theme: ThemeInfo(),
    signup: SignupInfo(),
  );
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) return value;
  }
  return null;
}
