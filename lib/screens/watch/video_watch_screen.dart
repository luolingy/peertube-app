import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_exception.dart';
import '../../core/formatters.dart';
import '../../core/option_lists.dart';
import '../../data/peertube_api.dart';
import '../../models/json_utils.dart';
import '../../models/playlist.dart';
import '../../models/video.dart';
import '../../router/routes.dart';
import '../../state/metadata_controller.dart';
import '../../state/paged_list_controller.dart';
import '../../state/playback_controller.dart';
import '../../state/session_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/action_buttons.dart';
import '../../widgets/actor_avatar.dart';
import '../../widgets/markdown_text.dart';
import '../../widgets/paged_list_view.dart';
import '../../widgets/player/video_surface.dart';
import '../../widgets/state_views.dart';
import '../../widgets/video_cards.dart';
import 'comments_section.dart';

/// The video watch page: player, metadata, actions, comments and related
/// videos. Mirrors the feature set of the PeerTube web player page.
class VideoWatchScreen extends StatefulWidget {
  const VideoWatchScreen({
    super.key,
    required this.videoId,
    this.playlistId,
    this.playlistElementId,
  });

  final String videoId;
  final int? playlistId;
  final int? playlistElementId;

  @override
  State<VideoWatchScreen> createState() => _VideoWatchScreenState();
}

class _VideoWatchScreenState extends State<VideoWatchScreen> {
  Video? _video;
  Object? _error;
  bool _loading = true;

  PlaybackController? _playback;
  PagedListController<Video>? _related;

  List<VideoCaption> _captions = const <VideoCaption>[];
  List<VideoChapter> _chapters = const <VideoChapter>[];

  String _rating = 'none';
  int _likes = 0;
  int _dislikes = 0;
  String? _password;
  bool _fullscreen = false;
  bool _descriptionExpanded = false;

  Timer? _viewTimer;
  Duration _lastReported = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant VideoWatchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _disposePlayback();
      _load();
    }
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _disposePlayback();
    _related?.dispose();
    super.dispose();
  }

  void _disposePlayback() {
    _playback?.dispose();
    _playback = null;
  }

  // -------------------------------------------------------------------------
  // Loading
  // -------------------------------------------------------------------------

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final api = context.read<PeertubeApi>();
    final session = context.read<SessionController>();

    try {
      final video = await api.getVideo(widget.videoId, password: _password);

      if (!mounted) return;
      setState(() {
        _video = video;
        _likes = video.likes;
        _dislikes = video.dislikes;
        _loading = false;
      });

      await _afterVideoLoaded(video, session);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _afterVideoLoaded(Video video, SessionController session) async {
    final api = context.read<PeertubeApi>();

    // Related videos: prefer the same channel, then the same tags.
    _related?.dispose();
    _related = PagedListController<Video>(
      loader: (int start, int count) {
        final channel = video.channel;
        if (channel != null) {
          return api.listChannelVideos(
            channel.handle,
            start: start,
            count: count,
            sort: '-publishedAt',
          );
        }
        return api.listVideos(start: start, count: count, sort: '-trending');
      },
    );
    _related!.refresh();

    // Captions and chapters are optional features.
    try {
      final captions = await api.listCaptions(video.shortUUID.isEmpty ? video.uuid : video.shortUUID);
      if (mounted) setState(() => _captions = captions);
    } catch (_) {
      // Ignore.
    }

    try {
      final chapters = await api.listChapters(video.shortUUID.isEmpty ? video.uuid : video.shortUUID);
      if (mounted) setState(() => _chapters = chapters);
    } catch (_) {
      // Ignore.
    }

    // My rating.
    if (session.isLoggedIn) {
      try {
        final rating = await api.getMyRating(video.id.toString());
        if (mounted) setState(() => _rating = rating);
      } catch (_) {
        // Ignore.
      }
    }

    await _startPlayback(video);
  }

  Future<void> _startPlayback(Video video) async {
    final api = context.read<PeertubeApi>();
    final session = context.read<SessionController>();
    final settings = context.read<SettingsController>();

    String? token;
    // Private videos need a signed playback token.
    if ((video.privacy?.id ?? 1) == 3 && session.isLoggedIn) {
      try {
        final result = await api.getVideoToken(video.uuid.isEmpty ? video.shortUUID : video.uuid);
        token = _firstToken(result);
      } catch (_) {
        // Playback will fail with a clear error message instead.
      }
    }

    if (!mounted) return;

    final controller = PlaybackController(
      video: video,
      token: token,
      password: _password,
    );
    controller.attachBaseUrl(api.client.baseUrl);
    controller.setCaptions(_captions);

    setState(() => _playback = controller);

    await controller.initialize(
      autoplay: settings.autoplay,
      initialVolume: settings.volume,
      initialRate: settings.playbackRate,
    );

    _startViewTracking();
  }

  String? _firstToken(Map<String, dynamic> payload) {
    for (final key in <String>['files', 'streamingPlaylists']) {
      final section = jsonMap(payload[key]);
      for (final value in section.values) {
        final token = jsonStringOrNull(value);
        if (token != null && token.isNotEmpty) return token;
      }
    }
    return null;
  }

  void _startViewTracking() {
    _viewTimer?.cancel();
    if (!context.read<SettingsController>().historyEnabled) return;

    _viewTimer = Timer.periodic(const Duration(seconds: 15), (Timer timer) async {
      final playback = _playback;
      final video = _video;
      if (playback == null || video == null) return;

      final position = playback.position;
      if ((position - _lastReported).inSeconds < 10) return;
      _lastReported = position;

      try {
        await context.read<PeertubeApi>().addVideoView(
              video.uuid.isEmpty ? video.shortUUID : video.uuid,
              currentTime: position.inSeconds,
            );
      } catch (_) {
        // View reporting is best effort.
      }
    });
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  Future<void> _rate(String rating) async {
    final video = _video;
    if (video == null) return;

    final session = context.read<SessionController>();
    if (!session.isLoggedIn) {
      context.push(Routes.login);
      return;
    }

    final previous = _rating;
    final previousLikes = _likes;
    final previousDislikes = _dislikes;

    setState(() {
      _rating = rating;
      var likes = previousLikes;
      var dislikes = previousDislikes;

      // Undo the previous vote first.
      if (previous == 'like') likes--;
      if (previous == 'dislike') dislikes--;
      // Apply the new one.
      if (rating == 'like') likes++;
      if (rating == 'dislike') dislikes++;

      _likes = likes < 0 ? 0 : likes;
      _dislikes = dislikes < 0 ? 0 : dislikes;
    });

    try {
      await context.read<PeertubeApi>().rateVideo(video.uuid, rating);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _rating = previous;
        _likes = previousLikes;
        _dislikes = previousDislikes;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败：$error')));
    }
  }

  Future<void> _showPlaylistSheet() async {
    final video = _video;
    if (video == null) return;

    final session = context.read<SessionController>();
    if (!session.isLoggedIn) {
      context.push(Routes.login);
      return;
    }

    final api = context.read<PeertubeApi>();
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return FutureBuilder<List<PlaylistVideoExistence>>(
              future: api.playlistsContainingVideo(<int>[video.id]),
              builder: (BuildContext context, AsyncSnapshot<List<PlaylistVideoExistence>> snapshot) {
                final contains = <int>{
                  for (final entry in snapshot.data ?? const <PlaylistVideoExistence>[])
                    if (entry.exists) entry.playlistId,
                };

                return SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.6,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Row(
                          children: <Widget>[
                            Text('保存到播放列表', style: Theme.of(context).textTheme.titleMedium),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () async {
                                final created = await _createPlaylistDialog();
                                if (created != null && context.mounted) {
                                  setSheetState(() {});
                                }
                              },
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('新建'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: FutureBuilder<PagedResultLike>(
                          future: _loadMyPlaylists(api),
                          builder: (BuildContext context, AsyncSnapshot<PagedResultLike> snapshot) {
                            if (!snapshot.hasData) {
                              return const LoadingView();
                            }
                            final playlists = snapshot.data!.playlists;
                            if (playlists.isEmpty) {
                              return const EmptyView(
                                icon: Icons.playlist_add_rounded,
                                title: '还没有播放列表',
                                subtitle: '点击右上角新建一个',
                              );
                            }

                            return ListView.builder(
                              itemCount: playlists.length,
                              itemBuilder: (BuildContext context, int index) {
                                final playlist = playlists[index];
                                final isIn = contains.contains(playlist.id);
                                return CheckboxListTile(
                                  value: isIn,
                                  title: Text(playlist.displayName),
                                  subtitle: Text('${playlist.videosLength} 个视频'),
                                  onChanged: (bool? value) async {
                                    try {
                                      if (value == true) {
                                        await api.addVideoToPlaylist(playlist.id, video.uuid);
                                      } else {
                                        final elements = await api.listPlaylistVideos(playlist.id, count: 200);
                                        for (final element in elements.data) {
                                          if (element.video?.id == video.id) {
                                            await api.removeVideoFromPlaylist(playlist.id, element.id);
                                          }
                                        }
                                      }
                                      if (context.mounted) setSheetState(() {});
                                    } catch (error) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('操作失败：$error')),
                                      );
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<PagedResultLike> _loadMyPlaylists(PeertubeApi api) async {
    final page = await api.listMyPlaylists(count: 100);
    return PagedResultLike(page.data);
  }

  Future<VideoPlaylist?> _createPlaylistDialog() async {
    final controller = TextEditingController();
    final api = context.read<PeertubeApi>();

    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('新建播放列表'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名称'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return null;

    try {
      return await api.createPlaylist(displayName: name);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败：$error')));
      }
      return null;
    }
  }

  Future<void> _reportAbuse() async {
    final video = _video;
    if (video == null) return;

    final session = context.read<SessionController>();
    if (!session.isLoggedIn) {
      context.push(Routes.login);
      return;
    }

    final api = context.read<PeertubeApi>();
    final messenger = ScaffoldMessenger.of(context);

    String reason = '1';
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: const Text('举报该视频'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: '原因'),
                items: kAbuseReasons
                    .map(
                      (OptionItem option) => DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (String? value) {
                  if (value != null) setDialogState(() => reason = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '补充说明',
                  hintText: '请描述具体问题',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('提交'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    if (messageController.text.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('请填写补充说明')));
      return;
    }

    try {
      await api.reportAbuse(
        reason: reason,
        message: messageController.text.trim(),
        videoId: video.uuid,
      );
      messenger.showSnackBar(const SnackBar(content: Text('举报已提交，感谢你的反馈')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('提交失败：$error')));
    }
  }

  Future<void> _download() async {
    final video = _video;
    if (video == null) return;

    final files = <VideoFile>[
      ...video.progressiveVideoFiles,
      ...video.audioFiles,
      for (final playlist in video.streamingPlaylists) ...playlist.files,
    ];

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该视频没有可下载的文件')),
      );
      return;
    }

    final selected = await showModalBottomSheet<VideoFile>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => ListView(
        shrinkWrap: true,
        children: files
            .map(
              (VideoFile file) => ListTile(
                leading: const Icon(Icons.download_rounded),
                title: Text(file.qualityLabel),
                subtitle: Text(formatBytes(file.size)),
                onTap: () => Navigator.of(context).pop(file),
              ),
            )
            .toList(growable: false),
      ),
    );

    if (selected == null) return;
    final uri = Uri.tryParse(selected.fileDownloadUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _askPassword() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('该视频需要密码'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(labelText: '视频密码'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (value == null) return;
    setState(() => _password = value);
    _disposePlayback();
    await _load();
  }

  void _playNext() {
    final related = _related?.items ?? const <Video>[];
    for (final candidate in related) {
      if (candidate.id != _video?.id) {
        context.pushReplacement(Routes.watchVideo(candidate.shortUUID));
        return;
      }
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_fullscreen && _playback != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop) setState(() => _fullscreen = false);
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: VideoSurface(
              playback: _playback!,
              isFullscreen: true,
              title: _video?.name,
              onToggleFullscreen: () => setState(() => _fullscreen = false),
              showNext: (_related?.items.length ?? 0) > 1,
              onNext: _playNext,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _video?.name ?? '视频',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          if (_video != null) ...<Widget>[
            CopyLinkButton(path: '/videos/watch/${_video!.uuid}'),
            ExternalLinkButton(url: _video!.url),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();

    if (_error != null) {
      final error = _error;
      final needsPassword = _video?.privacy?.id == 5 || _password == null;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ErrorView(error: error, onRetry: _load),
            if (needsPassword)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: _askPassword,
                  icon: const Icon(Icons.password_rounded),
                  label: const Text('输入视频密码'),
                ),
              ),
          ],
        ),
      );
    }

    final video = _video;
    if (video == null) return const LoadingView();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final wide = constraints.maxWidth >= 1080;

        final main = _buildMainColumn(video);

        if (!wide) {
          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              main,
              _buildRelatedSection(video),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[main],
              ),
            ),
            const VerticalDivider(width: 1),
            SizedBox(
              width: 400,
              child: _buildRelatedSection(video),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainColumn(Video video) {
    final api = context.read<PeertubeApi>();
    final baseUrl = api.client.baseUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildPlayer(video),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (video.isLive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formatCount(video.viewers)} 人正在观看',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              Text(
                video.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    formatWatchCount(video.views),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    formatDateTime(video.publishedAt ?? video.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (video.originallyPublishedAt != null)
                    Text(
                      '原发布于 ${formatDate(video.originallyPublishedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (video.isLocal == false)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.public_rounded, size: 14),
                      label: Text(video.account.host),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildChannelRow(video, baseUrl),
              const SizedBox(height: 12),
              _buildActionBar(video),
              const SizedBox(height: 16),
              _buildDescription(video),
              if (_chapters.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                _buildChapters(),
              ],
              const Divider(height: 32),
              if (_playback != null && widget.playlistId != null)
                _buildPlaylistBanner(),
              CommentsSection(
                videoId: video.uuid.isEmpty ? video.shortUUID : video.uuid,
                baseUrl: baseUrl,
                commentsEnabled: (video.commentsPolicy?.id ?? 1) != 2,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayer(Video video) {
    final playback = _playback;

    if (playback == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: video.aspectRatio <= 0 ? 16 / 9 : video.aspectRatio.clamp(0.5, 2.4),
      child: VideoSurface(
        playback: playback,
        title: video.name,
        onToggleFullscreen: () => setState(() => _fullscreen = true),
        showNext: (_related?.items.length ?? 0) > 1,
        onNext: _playNext,
      ),
    );
  }

  Widget _buildChannelRow(Video video, String baseUrl) {
    final channel = video.channel;

    return Row(
      children: <Widget>[
        ActorAvatar(
          images: channel?.avatars ?? video.account.avatars,
          baseUrl: baseUrl,
          fallbackLabel: channel?.displayName ?? video.account.displayName,
          radius: 22,
          onTap: () => context.push(
            channel != null
                ? Routes.channelByHandle(channel.handle)
                : Routes.accountByHandle(video.account.handle),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                channel?.displayName ?? video.account.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                channel != null
                    ? '${formatCount(channel.followersCount)} 位订阅者'
                    : '@${video.account.handle}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (channel != null)
          SubscribeButton(uri: channel.handle)
        else
          SubscribeButton(uri: video.account.handle),
      ],
    );
  }

  Widget _buildActionBar(Video video) {
    final session = context.watch<SessionController>();
    final isOwner = session.myAccount?.id == video.account.id;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        RateButtons(
          rating: _rating,
          likes: _likes,
          dislikes: _dislikes,
          onRate: _rate,
        ),
        ActionChip(
          avatar: const Icon(Icons.playlist_add_rounded, size: 18),
          label: const Text('保存'),
          onPressed: _showPlaylistSheet,
        ),
        if (video.downloadEnabled)
          ActionChip(
            avatar: const Icon(Icons.download_rounded, size: 18),
            label: const Text('下载'),
            onPressed: _download,
          ),
        ActionChip(
          avatar: const Icon(Icons.share_rounded, size: 18),
          label: Text('${formatCount(video.views)}'),
          onPressed: () async {
            final url = context.read<PeertubeApi>().client.webUrl('/videos/watch/${video.uuid}');
            await showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (BuildContext context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.link_rounded),
                      title: const Text('复制视频链接'),
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: url));
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.open_in_new_rounded),
                      title: const Text('在浏览器中打开'),
                      onTap: () async {
                        final uri = Uri.tryParse(url);
                        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.flag_outlined, size: 18),
          label: const Text('举报'),
          onPressed: _reportAbuse,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (String value) {
            switch (value) {
              case 'edit':
                context.push(Routes.editVideo(video.shortUUID));
                break;
              case 'delete':
                _deleteVideo(video);
                break;
              case 'embed':
                _showEmbed(video);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            if (isOwner) ...<PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'edit', child: Text('编辑视频')),
              const PopupMenuItem<String>(value: 'delete', child: Text('删除视频')),
            ],
            const PopupMenuItem<String>(value: 'embed', child: Text('嵌入代码')),
          ],
        ),
      ],
    );
  }

  Future<void> _deleteVideo(Video video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除视频'),
        content: const Text('删除后无法恢复，确定继续吗？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<PeertubeApi>().deleteVideo(video.uuid);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败：$error')));
      }
    }
  }

  void _showEmbed(Video video) {
    final api = context.read<PeertubeApi>();
    final embedUrl = api.client.webUrl('/videos/embed/${video.uuid}');
    final code = '<iframe src="$embedUrl" width="560" height="315" '
        'frameborder="0" allowfullscreen sandbox="allow-same-origin allow-scripts allow-popups"></iframe>';

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('嵌入代码'),
        content: SelectableText(code),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Video video) {
    final metadata = context.watch<MetadataController>();
    final description = (video.description ?? '').trim();
    final hasDescription = description.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (hasDescription)
              _descriptionExpanded
                  ? MarkdownText(data: description)
                  : MarkdownText(data: description, maxLines: 3)
            else
              Text(
                '该视频没有简介。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (hasDescription)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
                  child: Text(_descriptionExpanded ? '收起' : '展开'),
                ),
              ),
            if (video.tags.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: video.tags
                    .map(
                      (String tag) => ActionChip(
                        label: Text(tag),
                        avatar: const Icon(Icons.tag_rounded, size: 14),
                        onPressed: () => context.go('${Routes.search}?q=$tag'),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: <Widget>[
                _metaItem('分类', video.category?.label ?? '未分类'),
                _metaItem('许可', video.licence?.label ?? '未知'),
                _metaItem('语言', video.language?.label ?? '未知'),
                _metaItem('隐私', metadata.privacyLabel(video.privacy?.id)),
              ],
            ),
            if ((video.support ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              MarkdownText(data: video.support!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metaItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$label：',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildChapters() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Text('章节', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ..._chapters.map(
            (VideoChapter chapter) => ListTile(
              dense: true,
              leading: Text(formatDuration(chapter.timecode)),
              title: Text(chapter.title),
              onTap: () => _playback?.seekToSeconds(chapter.timecode),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildPlaylistBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.playlist_play_rounded),
          title: const Text('来自播放列表'),
          subtitle: const Text('返回播放列表查看全部内容'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push(Routes.playlistById(widget.playlistId!)),
        ),
      ),
    );
  }

  Widget _buildRelatedSection(Video video) {
    final api = context.read<PeertubeApi>();
    final controller = _related;

    if (controller == null) return const SizedBox.shrink();

    return PagedListView<Video>(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      emptyTitle: '没有相关视频',
      emptyIcon: Icons.videocam_off_outlined,
      header: const Padding(
        padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Text('相关视频', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ),
      itemBuilder: (BuildContext context, Video item, int index) {
        if (item.id == video.id) return const SizedBox.shrink();
        return VideoListTile(video: item, baseUrl: api.client.baseUrl, thumbnailWidth: 150);
      },
    );
  }
}

/// Small holder used by the playlist sheet.
class PagedResultLike {
  PagedResultLike(this.playlists);

  final List<VideoPlaylist> playlists;
}
