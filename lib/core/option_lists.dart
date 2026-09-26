/// Static option lists used by filters and forms.
///
/// PeerTube exposes categories / licences / languages / privacies through the
/// API and the app prefers those dynamic values, but these fallbacks keep the
/// UI usable while the configuration is still loading or when the instance
/// restricts an endpoint.
library;

/// A single entry of a `<select>`.
class OptionItem {
  const OptionItem(this.value, this.label);

  final String value;
  final String label;

  @override
  String toString() => '$label ($value)';
}

/// An entry whose API value is a number (privacy, category, ...).
class IdOption {
  const IdOption(this.id, this.label);

  final int id;
  final String label;

  @override
  String toString() => label;
}

// ---------------------------------------------------------------------------
// Sort fields
// ---------------------------------------------------------------------------

/// Values come from `VideoSortField` in the PeerTube model package.
const List<OptionItem> kBrowseSorts = [
  OptionItem('-publishedAt', '最新发布'),
  OptionItem('-trending', '近期热门'),
  OptionItem('-hot', '当下最热'),
  OptionItem('-views', '观看最多'),
  OptionItem('-likes', '点赞最多'),
  OptionItem('-comments', '评论最多'),
  OptionItem('-duration', '时长最长'),
  OptionItem('name', '标题 A-Z'),
];

const List<OptionItem> kSearchVideoSorts = [
  OptionItem('-match', '匹配度'),
  OptionItem('-publishedAt', '最新发布'),
  OptionItem('-views', '观看最多'),
  OptionItem('-likes', '点赞最多'),
  OptionItem('-trending', '近期热门'),
  OptionItem('-duration', '时长最长'),
];

const List<OptionItem> kSearchChannelSorts = [
  OptionItem('-match', '匹配度'),
  OptionItem('-followers', '订阅最多'),
  OptionItem('-views', '观看最多'),
  OptionItem('-createdAt', '最新创建'),
];

const List<OptionItem> kSearchPlaylistSorts = [
  OptionItem('-match', '匹配度'),
  OptionItem('-createdAt', '最新创建'),
  OptionItem('-updatedAt', '最近更新'),
];

const List<OptionItem> kHistorySorts = [
  OptionItem('-createdAt', '最近观看'),
  OptionItem('-publishedAt', '最新发布'),
  OptionItem('-views', '观看最多'),
];

const List<OptionItem> kSubscriptionsSorts = [
  OptionItem('-publishedAt', '最新发布'),
  OptionItem('-views', '观看最多'),
  OptionItem('-trending', '近期热门'),
];

const List<OptionItem> kCommentSorts = [
  OptionItem('-createdAt', '最新'),
  OptionItem('createdAt', '最早'),
  OptionItem('-totalReplies', '回复最多'),
];

const List<OptionItem> kNotificationSorts = [
  OptionItem('-createdAt', '最新'),
  OptionItem('createdAt', '最早'),
];

const List<OptionItem> kUserSorts = [
  OptionItem('-createdAt', '最新注册'),
  OptionItem('createdAt', '最早注册'),
  OptionItem('username', '用户名'),
  OptionItem('-username', '用户名倒序'),
];

const List<OptionItem> kAbuseSorts = [
  OptionItem('-createdAt', '最新'),
  OptionItem('createdAt', '最早'),
];

const List<OptionItem> kJobSorts = [
  OptionItem('-createdAt', '最新'),
  OptionItem('createdAt', '最早'),
];

const List<OptionItem> kMyVideoSorts = [
  OptionItem('-publishedAt', '最新发布'),
  OptionItem('-createdAt', '最新创建'),
  OptionItem('-views', '观看最多'),
  OptionItem('-likes', '点赞最多'),
];

// ---------------------------------------------------------------------------
// Enumerations
// ---------------------------------------------------------------------------

/// `VideoPrivacy` enum.
const List<IdOption> kVideoPrivacies = [
  IdOption(1, '公开'),
  IdOption(2, '不公开列出'),
  IdOption(3, '私有'),
  IdOption(4, '内部'),
  IdOption(5, '密码保护'),
];

/// `VideoPlaylistPrivacy` enum.
const List<IdOption> kPlaylistPrivacies = [
  IdOption(1, '公开'),
  IdOption(2, '不公开列出'),
  IdOption(3, '私有'),
];

/// `VideoState` enum.
const List<IdOption> kVideoStates = [
  IdOption(1, '已发布'),
  IdOption(2, '转码中'),
  IdOption(3, '导入中'),
  IdOption(4, '等待直播'),
  IdOption(5, '待编辑'),
  IdOption(6, '迁移中'),
  IdOption(7, '转码失败'),
];

/// `UserRole` enum.
const List<IdOption> kUserRoles = [
  IdOption(0, '用户'),
  IdOption(1, '版主'),
  IdOption(2, '管理员'),
];

/// `AbuseState` enum.
const List<IdOption> kAbuseStates = [
  IdOption(1, '待审核'),
  IdOption(2, '已确认'),
  IdOption(3, '已驳回'),
];

/// `UserNotificationSetting` keys used by the notification settings form.
///
/// Values are `UserNotificationSettingValue`: `NONE = 0`, `WEB = 1`,
/// `EMAIL = 2`.
const List<OptionItem> kNotificationTypes = [
  OptionItem('newVideoFromSubscription', '订阅的频道发布了新视频'),
  OptionItem('newCommentOnMyVideo', '我的视频有了新评论'),
  OptionItem('myVideoImportFinished', '视频导入完成'),
  OptionItem('newFollow', '我有新关注者'),
  OptionItem('commentMention', '评论中提到了我'),
  OptionItem('myVideoPublished', '我的视频发布成功'),
  OptionItem('blacklistOnMyVideo', '我的视频被屏蔽'),
  OptionItem('abuseStateChange', '举报状态发生变化'),
  OptionItem('abuseNewMessage', '举报收到新消息'),
  OptionItem('newUserRegistration', '有新用户注册（管理员）'),
  OptionItem('abuseAsModerator', '有新的举报（版主）'),
  OptionItem('videoAutoBlacklistAsModerator', '视频被自动屏蔽（版主）'),
  OptionItem('newInstanceFollower', '实例有新关注者（管理员）'),
  OptionItem('autoInstanceFollowing', '自动关注了实例（管理员）'),
  OptionItem('newPeerTubeVersion', 'PeerTube 有新版本'),
  OptionItem('newPluginVersion', '插件有新版本'),
  OptionItem('myVideoStudioEditionFinished', '视频剪辑处理完成'),
  OptionItem('myVideoTranscriptionGenerated', '视频字幕生成完成'),
  OptionItem('automaticBlocklist', '自动屏蔽了服务器'),
];

/// Values of a single notification setting.
const List<IdOption> kNotificationSettingValues = [
  IdOption(0, '关闭'),
  IdOption(1, '站内'),
  IdOption(2, '站内 + 邮件'),
];

/// PeerTube jobs states (`/jobs`).
const List<OptionItem> kJobStates = [
  OptionItem('active', '进行中'),
  OptionItem('completed', '已完成'),
  OptionItem('failed', '失败'),
  OptionItem('delayed', '延迟'),
  OptionItem('waiting', '等待'),
];

/// Scopes available when browsing videos.
const List<OptionItem> kVideoScopes = [
  OptionItem('federated', '联合'),
  OptionItem('local', '本站'),
];

/// Report reasons accepted by `POST /abuses`.
const List<OptionItem> kAbuseReasons = [
  OptionItem('1', '色情内容'),
  OptionItem('2', '暴力内容'),
  OptionItem('3', '仇恨言论'),
  OptionItem('4', '侵犯版权'),
  OptionItem('5', '垃圾内容'),
  OptionItem('6', '其他'),
];
