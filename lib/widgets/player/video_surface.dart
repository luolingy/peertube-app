import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;

import '../../core/formatters.dart';
import '../../models/video.dart';
import '../../state/playback_controller.dart';

/// The video surface plus a complete control overlay.
///
/// Fullscreen is handled by the parent screen (the surface simply fills
/// whatever box it is given), which keeps a single `Video` widget alive and
/// avoids the texture being recreated.
class VideoSurface extends StatefulWidget {
  const VideoSurface({
    super.key,
    required this.playback,
    this.isFullscreen = false,
    this.onToggleFullscreen,
    this.onNext,
    this.onPrevious,
    this.title,
    this.showNext = false,
  });

  final PlaybackController playback;
  final bool isFullscreen;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final String? title;
  final bool showNext;

  @override
  State<VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends State<VideoSurface> {
  Timer? _hideTimer;
  bool _controlsVisible = true;
  bool _dragging = false;
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!widget.playback.playing) return;
    _hideTimer = Timer(const Duration(milliseconds: 3200), () {
      if (!mounted || _dragging) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  Future<void> _seekBy(int seconds) async {
    final playback = widget.playback;
    final target = playback.position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (playback.duration > Duration.zero && target > playback.duration
            ? playback.duration
            : target);
    await playback.seek(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.playback,
      builder: (BuildContext context, Widget? _) {
        final playback = widget.playback;

        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              media_kit_video.Video(
                controller: playback.videoController,
                controls: media_kit_video.NoVideoControls,
                fill: Colors.black,
              ),
              if (playback.hasError)
                _ErrorOverlay(message: playback.errorMessage ?? '播放失败')
              else
                _buildGestures(playback),
              if (playback.buffering && !playback.hasError)
                const Center(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white70,
                    ),
                  ),
                ),
              if (playback.completed) _buildCompleted(playback),
              if (_controlsVisible && !playback.hasError) _buildControls(playback),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGestures(PlaybackController playback) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      onDoubleTapDown: (TapDownDetails details) {
        final width = context.size?.width ?? 0;
        if (width == 0) return;
        if (details.localPosition.dx < width / 3) {
          _seekBy(-10);
        } else if (details.localPosition.dx > width * 2 / 3) {
          _seekBy(10);
        } else {
          playback.playOrPause();
        }
      },
      child: const SizedBox.expand(),
    );
  }

  Widget _buildCompleted(PlaybackController playback) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              '播放结束',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () {
                    playback.seek(Duration.zero);
                    playback.play();
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('重播'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                ),
                if (widget.showNext && widget.onNext != null) ...<Widget>[
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: widget.onNext,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('下一个'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(PlaybackController playback) {
    final total = playback.duration.inMilliseconds;
    final value = _dragValue ?? playback.position.inMilliseconds.toDouble();
    final max = total > 0 ? total.toDouble() : 1.0;

    return Stack(
      children: <Widget>[
        // Top gradient with the title.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: widget.isFullscreen ? 10 : 6,
              bottom: 24,
              left: 12,
              right: 12,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Colors.black87, Colors.transparent],
              ),
            ),
            child: Row(
              children: <Widget>[
                if (widget.title != null)
                  Expanded(
                    child: Text(
                      widget.title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (widget.isFullscreen)
                  IconButton(
                    tooltip: '退出全屏',
                    onPressed: widget.onToggleFullscreen,
                    icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
        // Center play/pause.
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (widget.onPrevious != null)
                IconButton(
                  iconSize: 32,
                  onPressed: widget.onPrevious,
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                ),
              _RoundIconButton(
                icon: playback.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 56,
                onPressed: () {
                  playback.playOrPause();
                  _scheduleHide();
                },
              ),
              if (widget.showNext && widget.onNext != null)
                IconButton(
                  iconSize: 32,
                  onPressed: widget.onNext,
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                ),
            ],
          ),
        ),
        // Bottom bar.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 24, 8, 4),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: <Color>[Colors.black87, Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const SizedBox(width: 8),
                    Text(
                      formatDuration(playback.position.inSeconds),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: Theme.of(context).colorScheme.primary,
                          thumbColor: Theme.of(context).colorScheme.primary,
                          inactiveTrackColor: Colors.white24,
                        ),
                        child: Slider(
                          value: value.clamp(0.0, max),
                          max: max,
                          onChangeStart: (double v) {
                            _dragging = true;
                            _hideTimer?.cancel();
                          },
                          onChanged: (double v) => setState(() => _dragValue = v),
                          onChangeEnd: (double v) async {
                            _dragging = false;
                            setState(() => _dragValue = null);
                            await playback.seek(Duration(milliseconds: v.round()));
                            _scheduleHide();
                          },
                        ),
                      ),
                    ),
                    Text(
                      formatDuration(playback.duration.inSeconds),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                Row(
                  children: <Widget>[
                    IconButton(
                      tooltip: playback.playing ? '暂停' : '播放',
                      onPressed: () {
                        playback.playOrPause();
                        _scheduleHide();
                      },
                      icon: Icon(
                        playback.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.showNext && widget.onNext != null)
                      IconButton(
                        tooltip: '下一个',
                        onPressed: widget.onNext,
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                      ),
                    _buildVolumeButton(playback),
                    const Spacer(),
                    if (playback.hasCaptions) _buildCaptionsMenu(playback),
                    _buildSpeedMenu(playback),
                    if (playback.hasQualityOptions) _buildQualityMenu(playback),
                    IconButton(
                      tooltip: widget.isFullscreen ? '退出全屏' : '全屏',
                      onPressed: widget.onToggleFullscreen,
                      icon: Icon(
                        widget.isFullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeButton(PlaybackController playback) {
    return PopupMenuButton<void>(
      tooltip: '音量',
      icon: Icon(
        playback.volume == 0
            ? Icons.volume_off_rounded
            : (playback.volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
        color: Colors.white,
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          enabled: false,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setMenuState) {
              return SizedBox(
                width: 200,
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.volume_up_rounded, size: 18),
                    Expanded(
                      child: Slider(
                        value: playback.volume,
                        onChanged: (double value) {
                          playback.setVolume(value);
                          setMenuState(() {});
                        },
                      ),
                    ),
                    Text('${(playback.volume * 100).round()}%'),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedMenu(PlaybackController playback) {
    const speeds = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    return PopupMenuButton<double>(
      tooltip: '播放速度',
      icon: const Icon(Icons.speed_rounded, color: Colors.white),
      initialValue: playback.rate,
      onSelected: (double value) {
        playback.setRate(value);
        _scheduleHide();
      },
      itemBuilder: (BuildContext context) => speeds
          .map(
            (double speed) => PopupMenuItem<double>(
              value: speed,
              child: Text('${speed}x'),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildQualityMenu(PlaybackController playback) {
    return PopupMenuButton<PlaybackQuality>(
      tooltip: '清晰度',
      icon: const Icon(Icons.high_quality_rounded, color: Colors.white),
      onSelected: (PlaybackQuality quality) {
        playback.setQuality(quality);
        _scheduleHide();
      },
      itemBuilder: (BuildContext context) => playback.qualities
          .map(
            (PlaybackQuality quality) => PopupMenuItem<PlaybackQuality>(
              value: quality,
              child: Row(
                children: <Widget>[
                  if (playback.selectedQuality?.url == quality.url)
                    const Icon(Icons.check_rounded, size: 16)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Text(quality.label),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildCaptionsMenu(PlaybackController playback) {
    return PopupMenuButton<VideoCaption?>(
      tooltip: '字幕',
      icon: const Icon(Icons.subtitles_outlined, color: Colors.white),
      onSelected: (VideoCaption? caption) {
        playback.selectCaption(caption);
        _scheduleHide();
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<VideoCaption?>>[
        PopupMenuItem<VideoCaption?>(
          value: null,
          child: Row(
            children: <Widget>[
              if (playback.selectedCaption == null)
                const Icon(Icons.check_rounded, size: 16)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              const Text('关闭字幕'),
            ],
          ),
        ),
        ...playback.captions.map(
          (VideoCaption caption) => PopupMenuItem<VideoCaption?>(
            value: caption,
            child: Row(
              children: <Widget>[
                if (playback.selectedCaption?.language == caption.language)
                  const Icon(Icons.check_rounded, size: 16)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(caption.label),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.62),
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 40),
          const SizedBox(height: 12),
          const Text(
            '无法播放该视频',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
