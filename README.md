# 哔TV 客户端 (peertube_app)

一个功能完整的 PeerTube 客户端（Flutter），默认连接 `https://tv.bi`（哔TV），
对标 PeerTube 网页端的全部功能。端点参考 PeerTube 8.3 源码
（`docs/api-endpoints.txt` / `docs/api-routes.txt`）。

## 运行

```bash
flutter pub get
flutter run
```

- 默认实例：`https://tv.bi`（可在「设置 → 实例」中切换，会清除本地会话）
- 支持 Android / iOS / Web / Windows / macOS / Linux（播放基于 `media_kit`）

## 功能对照（网页端 → 本客户端）

| 网页端 | 客户端 |
| --- | --- |
| 首页（推荐 / 最新 / 直播 / 订阅） | 首页四个 Tab，分页加载 |
| 发现（分类 / 标签 / 筛选） | 发现页 + 筛选面板（分类、语言、许可、NSFW、时长、日期、直播） |
| 搜索（视频 / 频道 / 播放列表） | 搜索页三个 Tab，各带排序与筛选，可切换搜索索引 |
| 观看页（播放器 / 简介 / 章节 / 字幕 / 相关视频 / 评论） | 观看页完整实现：清晰度切换、倍速、字幕、章节、循环、举报、下载、内嵌链接、密码保护、私密视频 token 播放、自动播放下一集、播放位置上报 |
| 登录 / 注册 / 忘记密码 / 2FA | 全部支持（含注册需要审核时的提示） |
| 我的频道 / 我的账号 | 资料编辑、头像、密码、通知设置、两步验证、会话/Token 管理、配额展示、删除账号 |
| 我的视频 / 历史 / 订阅 / 播放列表 / 导入 / 通知 / 举报 | 全部实现（含历史清理、导入进度） |
| 上传 / 导入 / 直播 | 上传（multipart + 进度 + 取消）、直播创建（RTMP 地址/密钥复制、延迟模式、回放）、频道增删改（头像/横幅） |
| 播放列表 | 创建/编辑/删除、增删视频、拖拽排序、封面 |
| 关于（实例介绍 / 条款 / 插件 / 统计 / 关注关系 / 联系管理员） | 全部实现 |
| 管理后台（举报 / 用户 / 注册审核 / 任务 / 插件 / 日志 / 屏蔽名单 / 配置） | 主持人/管理员角色可见，全部实现 |

## 架构

```
lib/
  main.dart            启动：MediaKit、LocalStore、Provider 装配
  app.dart             MaterialApp.router、主题（实例品牌色种子）
  core/                配置、异常、格式化、主题、枚举选项、文件选择
  data/
    api_client.dart    dio 封装：token 注入、401 刷新、RFC7807 错误、上传
    api/               按域拆分的端点 mixin（videos/actors/comments/…）
    peertube_api.dart  组合后的完整 API
    local_store.dart   shared_preferences 持久化（会话 + 偏好）
  models/              JSON 容错模型（json_utils）
  state/               ChangeNotifier 控制器（会话/配置/设置/通知/订阅/元数据/播放/分页）
  widgets/             通用组件（卡片、头像、分页列表、Markdown、操作按钮、播放器面板）
  router/              go_router 路由表（Routes 常量 + createRouter）
  screens/             页面（home/browse/search/library/watch/actors/playlist/
                       auth/publish/settings/about/admin/shell）
```

要点：

- **API 层**：`ApiSection` + mixin 组合；数组查询参数以逗号连接（`csv()`）；
  分页统一返回 `PagedResult<T>{total, data}`。
- **语言标识**：`/videos/languages` 返回字符串 id，`VideoConstant` 同时保留
  `rawId`/`key` 兼容数值枚举。
- **播放**：HLS master m3u8 优先，渐进式兜底；私密视频先 `POST /videos/:id/token`
  拿播放 token；密码保护视频用 `?password=` 查询参数。
- **全屏**：在观看页内做组件树交换（单 `Video` 实例），不另推路由。

## 测试

```bash
flutter test      # 单元测试（json/formatters/模型解析）
flutter analyze   # 零问题
```
