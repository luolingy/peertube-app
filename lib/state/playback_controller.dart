import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' show VideoController;

import '../models/video.dart';

/// One selectable playback rendition.
class PlaybackQuality {
  const PlaybackQuality({
    required this.label,
    required this.url,
    this.height = 0,
    this.isAuto = false,
  });

  final String label;
  final String url;
  final int height;
  final bool isAuto;
}

/// Wraps a `media_kit` player for one PeerTube video.
///
/// Handles HLS/progressive source selection, quality switching, captions,
/// playback speed and exposes everything the UI needs as a [ChangeNotifier].
class PlaybackController extends ChangeNotifier {
  PlaybackController({required this.video, this.token, this.password});

  final Video video;

  /// Playback token, required for private videos.
  final String? token;

  /// Video password, required for password protected videos.
  final String? password;

  final Player player = Player();
  late final VideoController videoController = VideoController(player);

  final List<StreamSubscription<dynamic>> _subscriptions = <StreamSubscription<dynamic>>[];

  bool _initialized = false;
  bool _disposed = false;

  bool get isInitialized => _initialized;

  bool playing = false;
  bool buffering = true;
  bool completed = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  Duration buffered = Duration.zero;
  double volume = 1.0;
  double rate = 1.0;
  String? errorMessage;
  bool hasError = false;

  List<PlaybackQuality> qualities = const <PlaybackQuality>[];
  PlaybackQuality? selectedQuality;

  List<VideoCaption> captions = const <VideoCaption>[];
  VideoCaption? selectedCaption;

  /// Position to restore once the first frame is ready.
  Duration startPosition = Duration.zero;
  bool _pendingSeek = false;

  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  bool get hasQualityOptions => qualities.length > 1;
  bool get hasCaptions => captions.isNotEmpty;

  /// Builds the rendition list from the video payload.
  void _buildQualities() {
    final result = <PlaybackQuality>[];

    final master = video.hlsMasterUrl;
    if (master != null) {
      result.add(PlaybackQuality(
        label: '自动',
        url: _withToken(master),
        isAuto: true,
      ));
      for (final file in video.qualityOptions) {
        final url = file.playlistUrl;
        if (url == null || url.isEmpty) continue;
        result.add(PlaybackQuality(
          label: file.qualityLabel,
          url: _withToken(url),
          height: file.height,
        ));
      }
    } else {
      for (final file in video.progressiveVideoFiles) {
        result.add(PlaybackQuality(
          label: file.qualityLabel,
          url: _withToken(file.fileUrl),
          height: file.height,
        ));
      }
      if (result.isEmpty) {
        for (final file in video.audioFiles) {
          result.add(PlaybackQuality(
            label: '仅音频',
            url: _withToken(file.fileUrl),
          ));
        }
      }
    }

    qualities = result;
    if (result.isNotEmpty) {
      selectedQuality = result.firstWhere(
        (PlaybackQuality q) => q.isAuto,
        orElse: () => result.first,
      );
    }
  }

  String _withToken(String url) {
    var result = url;
    final tokenValue = token;
    if (tokenValue != null && tokenValue.isNotEmpty && !result.contains('token=')) {
      final separator = result.contains('?') ? '&' : '?';
      result = '$result${separator}token=$tokenValue';
    }
    final passwordValue = password;
    if (passwordValue != null && passwordValue.isNotEmpty && !result.contains('password=')) {
      final separator = result.contains('?') ? '&' : '?';
      result = '$result${separator}password=${Uri.encodeQueryComponent(passwordValue)}';
    }
    return result;
  }

  /// Applies persisted player preferences and starts buffering the video.
  Future<void> initialize({
    bool autoplay = true,
    double initialVolume = 1.0,
    double initialRate = 1.0,
    Duration initialPosition = Duration.zero,
  }) async {
    if (_initialized) return;
    _initialized = true;

    volume = initialVolume;
    rate = initialRate;
    startPosition = initialPosition;
    _pendingSeek = initialPosition > Duration.zero;

    _subscriptions.add(player.stream.playing.listen((bool value) {
      playing = value;
      _safeNotify();
    }));
    _subscriptions.add(player.stream.position.listen((Duration value) {
      position = value;
      if (_pendingSeek && value > Duration.zero) _pendingSeek = false;
      _safeNotify();
    }));
    _subscriptions.add(player.stream.duration.listen((Duration value) {
      duration = value;
      _safeNotify();
    }));
    _subscriptions.add(player.stream.buffer.listen((Duration value) {
      buffered = value;
      _safeNotify();
    }));
    _subscriptions.add(player.stream.buffering.listen((bool value) {
      buffering = value;
      _safeNotify();
    }));
    _subscriptions.add(player.stream.completed.listen((bool value) {
      completed = value;
      _safeNotify();
    }));
    _subscriptions.add(player.stream.error.listen((String value) {
      if (value.isEmpty) return;
      errorMessage = value;
      hasError = true;
      _safeNotify();
    }));

    await player.setVolume((initialVolume * 100).clamp(0, 100));
    await player.setRate(initialRate);

    _buildQualities();

    final source = selectedQuality?.url ?? video.playbackUrl();
    if (source == null || source.isEmpty) {
      hasError = true;
      errorMessage = '该视频没有可用的播放源';
      _safeNotify();
      return;
    }

    await player.open(Media(source), play: autoplay);

    if (_pendingSeek && startPosition > Duration.zero) {
      // Wait for the demuxer to report a duration before seeking.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await player.seek(startPosition);
      _pendingSeek = false;
    }
  }

  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> playOrPause() => player.playOrPause();
  Future<void> stop() => player.stop();

  Future<void> seek(Duration value) => player.seek(value);

  Future<void> seekToSeconds(int seconds) => player.seek(Duration(seconds: seconds));

  Future<void> setVolume(double value) async {
    volume = value.clamp(0.0, 1.0);
    await player.setVolume(volume * 100);
    _safeNotify();
  }

  Future<void> setRate(double value) async {
    rate = value;
    await player.setRate(value);
    _safeNotify();
  }

  Future<void> toggleMute() async {
    if (volume > 0) {
      await setVolume(0);
    } else {
      await setVolume(1);
    }
  }

  /// Switches rendition, preserving position and play state.
  Future<void> setQuality(PlaybackQuality quality) async {
    if (quality.url == selectedQuality?.url) return;

    final resumeAt = position;
    final wasPlaying = playing;
    selectedQuality = quality;
    _safeNotify();

    await player.open(Media(quality.url), play: wasPlaying);
    if (resumeAt > Duration.zero) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await player.seek(resumeAt);
    }
  }

  /// Loads the caption tracks of the video.
  void setCaptions(List<VideoCaption> tracks) {
    captions = tracks;
    _safeNotify();
  }

  Future<void> selectCaption(VideoCaption? caption) async {
    selectedCaption = caption;
    _safeNotify();

    if (caption == null) {
      await player.setSubtitleTrack(SubtitleTrack.no());
      return;
    }

    final url = caption.urlOn(_baseUrl ?? '');
    await player.setSubtitleTrack(
      SubtitleTrack.uri(url, title: caption.label, language: caption.language),
    );
  }

  String? _baseUrl;

  /// Needed to build absolute caption URLs.
  void attachBaseUrl(String baseUrl) => _baseUrl = baseUrl;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    player.dispose();
    super.dispose();
  }
}
