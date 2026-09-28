import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item.dart';
import 'thumbnail_service.dart';

/// Central singleton service managing playback, playlist, lock screen controls, and background play state.
class AkoboPlaybackManager extends ChangeNotifier with WidgetsBindingObserver {
  static final AkoboPlaybackManager instance = AkoboPlaybackManager._internal();

  static const MethodChannel _mediaChannel = MethodChannel('com.akobo.akobo_flutter/media_notification');

  AkoboPlaybackManager._internal() {
    WidgetsBinding.instance.addObserver(this);
    _initMethodChannelListener();
  }

  VideoPlayerController? _controller;
  MediaItem? _currentMedia;
  List<MediaItem> _playlist = [];
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffered = Duration.zero;
  bool _isBackgroundPlayEnabled = true;
  bool _isInitialized = false;

  // Playback modes
  bool _isShuffle = false;
  bool _isRepeat = false;
  bool _isNightMode = false;

  VideoPlayerController? get controller => _controller;
  MediaItem? get currentMedia => _currentMedia;
  List<MediaItem> get playlist => _playlist;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  Duration get buffered => _buffered;
  bool get isBackgroundPlayEnabled => _isBackgroundPlayEnabled;
  bool get isInitialized => _isInitialized;
  bool get hasActiveMedia => _controller != null && _currentMedia != null;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  bool get isNightMode => _isNightMode;

  void _initMethodChannelListener() {
    _mediaChannel.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        final action = call.arguments as String?;
        switch (action) {
          case 'play':
            play();
            break;
          case 'pause':
            pause();
            break;
          case 'next':
            next();
            break;
          case 'previous':
            previous();
            break;
          case 'stop':
            stopAndDispose();
            break;
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_isBackgroundPlayEnabled && _controller != null && _isPlaying) {
        // Continue playback uninterrupted in background and lock screen
        _controller?.play();
      }
    }
  }

  /// Update the active playlist
  void setPlaylist(List<MediaItem> playlist) {
    if (playlist.isNotEmpty) {
      _playlist = List.from(playlist);
    }
  }

  /// Sets or reuses active playback controller
  Future<VideoPlayerController> initMedia(
    MediaItem item,
    List<MediaItem> playlist, {
    double speed = 1.0,
    double volume = 1.0,
  }) async {
    if (playlist.isNotEmpty) {
      _playlist = List.from(playlist);
    }

    // If already playing this exact item and initialized, reuse controller
    if (_controller != null && _currentMedia?.id == item.id && _isInitialized) {
      notifyListeners();
      _syncLockScreenNotification();
      return _controller!;
    }

    // Inform listeners that controller is resetting to detach VideoPlayer widget
    final oldController = _controller;
    _controller = null;
    _isInitialized = false;
    _currentMedia = item;
    notifyListeners();

    if (oldController != null) {
      oldController.removeListener(_onControllerUpdate);
      await oldController.dispose();
    }

    VideoPlayerController ctrl;
    if (item.isLocal && !kIsWeb) {
      ctrl = VideoPlayerController.file(File(item.url));
    } else {
      ctrl = VideoPlayerController.networkUrl(Uri.parse(item.url));
    }

    await ctrl.initialize();
    ctrl.setLooping(_isRepeat);
    ctrl.setPlaybackSpeed(speed);
    ctrl.setVolume(volume.clamp(0.0, 1.0));
    ctrl.addListener(_onControllerUpdate);

    _controller = ctrl;
    _duration = ctrl.value.duration;
    _isInitialized = true;
    _isPlaying = true;
    ctrl.play();

    notifyListeners();
    _syncLockScreenNotification(isNewMedia: true);
    return ctrl;
  }

  void _onControllerUpdate() {
    if (_controller == null) return;
    final val = _controller!.value;

    Duration buf = Duration.zero;
    if (val.buffered.isNotEmpty) {
      buf = val.buffered.last.end;
    }

    // Auto-advance to next track when finished
    if (val.isInitialized &&
        val.position >= val.duration &&
        val.duration > Duration.zero &&
        !_isRepeat &&
        !val.isPlaying) {
      next();
      return;
    }

    final changed = _isPlaying != val.isPlaying ||
        (_position.inSeconds != val.position.inSeconds) ||
        _duration != val.duration;

    _isPlaying = val.isPlaying;
    _position = val.position;
    _duration = val.duration;
    _buffered = buf;

    if (changed) {
      notifyListeners();
      _syncLockScreenNotification();
    }
  }

  void togglePlayPause() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      _isPlaying = false;
    } else {
      _controller!.play();
      _isPlaying = true;
    }
    notifyListeners();
    _syncLockScreenNotification();
  }

  void play() {
    if (_controller == null) return;
    _controller!.play();
    _isPlaying = true;
    notifyListeners();
    _syncLockScreenNotification();
  }

  void pause() {
    if (_controller == null) return;
    _controller!.pause();
    _isPlaying = false;
    notifyListeners();
    _syncLockScreenNotification();
  }

  void seekTo(Duration pos) {
    _controller?.seekTo(pos);
    _syncLockScreenNotification();
  }

  void next() {
    if (_playlist.isEmpty) return;
    if (_isShuffle) {
      final randomIdx = Random().nextInt(_playlist.length);
      initMedia(_playlist[randomIdx], _playlist);
      return;
    }
    final currentIndex = _playlist.indexWhere((i) => i.id == _currentMedia?.id);
    if (currentIndex != -1 && currentIndex < _playlist.length - 1) {
      initMedia(_playlist[currentIndex + 1], _playlist);
    } else if (_playlist.isNotEmpty) {
      initMedia(_playlist.first, _playlist);
    }
  }

  void previous() {
    if (_playlist.isEmpty) return;
    if (_position.inSeconds > 3) {
      seekTo(Duration.zero);
      return;
    }
    final currentIndex = _playlist.indexWhere((i) => i.id == _currentMedia?.id);
    if (currentIndex > 0) {
      initMedia(_playlist[currentIndex - 1], _playlist);
    } else if (_playlist.isNotEmpty) {
      initMedia(_playlist.last, _playlist);
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    _controller?.setLooping(_isRepeat);
    notifyListeners();
  }

  void toggleNightMode() {
    _isNightMode = !_isNightMode;
    notifyListeners();
  }

  void toggleBackgroundPlay() {
    _isBackgroundPlayEnabled = !_isBackgroundPlayEnabled;
    notifyListeners();
  }

  void setBackgroundPlay(bool value) {
    _isBackgroundPlayEnabled = value;
    notifyListeners();
  }

  Future<void> _syncLockScreenNotification({bool isNewMedia = false}) async {
    if (kIsWeb || !Platform.isAndroid || _currentMedia == null) return;
    try {
      Uint8List? artworkBytes;
      if (isNewMedia && _currentMedia!.isLocal) {
        artworkBytes = await ThumbnailService.getThumbnail(_currentMedia!.url);
      }
      await _mediaChannel.invokeMethod(
        isNewMedia ? 'startNotification' : 'updateNotification',
        {
          'title': _currentMedia!.title,
          'artist': _currentMedia!.subtitle,
          'isPlaying': _isPlaying,
          'duration': _duration.inMilliseconds,
          'position': _position.inMilliseconds,
          'artwork': artworkBytes,
        },
      );
    } catch (e) {
      debugPrint('Sync lock screen notification notice: $e');
    }
  }

  void stopAndDispose() {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        _mediaChannel.invokeMethod('stopNotification');
      } catch (_) {}
    }
    _controller?.removeListener(_onControllerUpdate);
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    _currentMedia = null;
    _isInitialized = false;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopAndDispose();
    super.dispose();
  }
}
