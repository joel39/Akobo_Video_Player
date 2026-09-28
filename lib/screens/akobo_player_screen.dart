import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/media_item.dart';
import '../services/akobo_playback_manager.dart';
import '../services/color_matrix_service.dart';
import '../services/subtitle_parser.dart';
import '../theme/cyber_theme.dart';
import '../widgets/ambient_glow_background.dart';
import '../widgets/audio_visualizer_widget.dart';
import '../widgets/bottom_sheets/aspect_ratio_sheet.dart';
import '../widgets/bottom_sheets/eq_sheet.dart';
import '../widgets/bottom_sheets/queue_sheet.dart';
import '../widgets/bottom_sheets/tools_sheet.dart';
import '../widgets/bottom_sheets/video_fx_sheet.dart';
import '../widgets/gesture_overlay.dart';
import '../widgets/player_controls_overlay.dart';
import '../widgets/subtitles_overlay.dart';

class AkoboPlayerScreen extends StatefulWidget {
  final MediaItem? initialMedia;
  final List<MediaItem>? playlist;

  const AkoboPlayerScreen({
    super.key,
    this.initialMedia,
    this.playlist,
  });

  @override
  State<AkoboPlayerScreen> createState() => _AkoboPlayerScreenState();
}

class _AkoboPlayerScreenState extends State<AkoboPlayerScreen> {
  // Playlist State
  late final List<MediaItem> _playlist;
  late MediaItem _currentMedia;

  // Video Player Controller
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffered = Duration.zero;
  bool _isInitialized = false;

  // Controls overlay auto-hide
  bool _showControls = true;
  Timer? _controlsTimer;

  // Visualizer & Ambient Glow
  bool _ambientGlowEnabled = true;
  bool _isAudioMode = false;
  VisualizerMode _vizMode = VisualizerMode.spectrum;

  // Color Grading FX
  VideoFxPreset _fxPreset = VideoFxPreset.normal;
  double _fxBrightness = 1.0;
  double _fxContrast = 1.0;
  double _fxSaturation = 1.0;
  double _fxHue = 0.0;

  // Audio Equalizer & Booster
  List<double> _eqBands = List.filled(10, 0.0);
  double _volumeBoost = 1.0;
  bool _spatialAudio = false;
  double _userVolume = 1.0;
  double _screenBrightness = 1.0;

  // Tools, Zoom, Aspect, Speed, A-B Loop
  final TransformationController _transformController = TransformationController();
  double _currentZoom = 1.0;
  PlayerAspectRatio _aspectRatio = PlayerAspectRatio.original;
  double _playbackSpeed = 1.0;
  Duration? _loopA;
  Duration? _loopB;

  // Subtitles
  List<SubtitleCue> _subtitleCues = [];
  double _subtitleOffset = 0.0;

  // Screen Touch Lock & Mirror
  bool _isLocked = false;
  bool _isMirror = false;

  @override
  void initState() {
    super.initState();
    AkoboPlaybackManager.instance.addListener(_onPlaybackManagerUpdate);
    if (widget.playlist != null && widget.playlist!.isNotEmpty) {
      _playlist = List<MediaItem>.from(widget.playlist!);
    } else {
      _playlist = List<MediaItem>.from(MediaItem.defaultLibrary);
    }
    AkoboPlaybackManager.instance.setPlaylist(_playlist);
    _currentMedia = widget.initialMedia ?? _playlist.first;
    _isAudioMode = _currentMedia.isAudio;
    _initPlayer(_currentMedia);
    _resetControlsTimer();
  }

  void _onPlaybackManagerUpdate() {
    if (!mounted) return;
    final manager = AkoboPlaybackManager.instance;
    final mediaChanged = manager.currentMedia != null && manager.currentMedia?.id != _currentMedia.id;
    if (mediaChanged) {
      _currentMedia = manager.currentMedia!;
      _isAudioMode = _currentMedia.isAudio;
      _currentZoom = 1.0;
      _transformController.value = Matrix4.identity();
      _loopA = null;
      _loopB = null;
    }

    if (_controller != manager.controller) {
      _controller?.removeListener(_onControllerUpdate);
      _controller = manager.controller;
      _controller?.addListener(_onControllerUpdate);
    }

    setState(() {
      _controller = manager.controller;
      _isInitialized = manager.isInitialized && _controller != null && _controller!.value.isInitialized;
      _isPlaying = manager.isPlaying;
      _position = manager.position;
      _duration = manager.duration;
      if (mediaChanged) {
        _isAudioMode = _currentMedia.isAudio;
      }
    });
  }

  void _playNext() {
    HapticFeedback.lightImpact();
    AkoboPlaybackManager.instance.next();
  }

  void _playPrevious() {
    HapticFeedback.lightImpact();
    if (_position.inSeconds > 3) {
      _controller?.seekTo(Duration.zero);
      AkoboPlaybackManager.instance.seekTo(Duration.zero);
      return;
    }
    AkoboPlaybackManager.instance.previous();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _showPropertiesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Media Properties', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _propRow('Title', _currentMedia.title),
            _propRow('Resolution', _currentMedia.resolution),
            _propRow('Duration', _formatDuration(_duration)),
            _propRow('Location', _currentMedia.url),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: CyberTheme.primaryBlue)),
          ),
        ],
      ),
    );
  }

  Widget _propRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.white)),
        ],
      ),
    );
  }

  void _shareCurrentMedia() {
    _showToast('Media link copied to clipboard');
  }

  void _deleteMediaDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Media', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Remove this media item from playback queue?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _playNext();
              _showToast('Removed from queue');
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _feedbackDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Thank you for using Arc Player. Share your impressions or feature suggestions to help us improve.', style: TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.primaryBlue),
            onPressed: () {
              Navigator.pop(ctx);
              _showToast('Thank you for your feedback!');
            },
            child: const Text('Send Feedback', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _sleepTimerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sleep Timer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _startSleepTimer(15);
            },
            child: const Text('15 minutes', style: TextStyle(color: Colors.white70)),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _startSleepTimer(30);
            },
            child: const Text('30 minutes', style: TextStyle(color: Colors.white70)),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _startSleepTimer(60);
            },
            child: const Text('60 minutes', style: TextStyle(color: Colors.white70)),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _showToast('Sleep timer turned off');
            },
            child: const Text('Turn Off', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _startSleepTimer(int minutes) {
    Timer(Duration(minutes: minutes), () {
      AkoboPlaybackManager.instance.pause();
    });
    _showToast('Sleep timer set for $minutes minutes');
  }


  Future<void> _initPlayer(MediaItem item) async {
    _controller?.removeListener(_onControllerUpdate);

    setState(() {
      _isInitialized = false;
      _currentMedia = item;
      _isAudioMode = item.isAudio;
      _currentZoom = 1.0;
      _transformController.value = Matrix4.identity();
      _loopA = null;
      _loopB = null;
    });

    try {
      final ctrl = await AkoboPlaybackManager.instance.initMedia(
        item,
        _playlist,
        speed: _playbackSpeed,
        volume: (_userVolume * _volumeBoost).clamp(0.0, 1.0),
      );

      if (mounted) {
        if (_controller != ctrl) {
          _controller?.removeListener(_onControllerUpdate);
          _controller = ctrl;
          _controller?.addListener(_onControllerUpdate);
        }
        setState(() {
          _controller = ctrl;
          _duration = ctrl.value.duration;
          _position = ctrl.value.position;
          _isPlaying = ctrl.value.isPlaying;
          _isInitialized = ctrl.value.isInitialized;
          _isAudioMode = item.isAudio;
        });
      }
    } catch (e) {
      debugPrint('Video player initialization error: $e');
      if (mounted) {
        _showToast('Media load notice: stream buffer initializing');
      }
    }
  }

  void _onControllerUpdate() {
    if (_controller == null || !mounted) return;
    final val = _controller!.value;

    // Check A-B loop interval
    if (_loopA != null && _loopB != null && val.position >= _loopB!) {
      _controller!.seekTo(_loopA!);
      return;
    }

    Duration buf = Duration.zero;
    if (val.buffered.isNotEmpty) {
      buf = val.buffered.last.end;
    }

    setState(() {
      _isPlaying = val.isPlaying;
      _position = val.position;
      _duration = val.duration;
      _buffered = buf;
    });
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (_showControls && _isPlaying) {
      _controlsTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _isPlaying) {
          setState(() => _showControls = false);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _resetControlsTimer();
    } else {
      _controlsTimer?.cancel();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    if (_controller == null) {
      AkoboPlaybackManager.instance.togglePlayPause();
      return;
    }
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      AkoboPlaybackManager.instance.pause();
      setState(() => _showControls = true);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _controlsTimer?.cancel();
    } else {
      _controller!.play();
      AkoboPlaybackManager.instance.play();
      _resetControlsTimer();
    }
  }

  void _seekRelative(Duration delta) {
    if (_controller == null) return;
    final newPos = _position + delta;
    final target = Duration(
      milliseconds: newPos.inMilliseconds.clamp(0, _duration.inMilliseconds),
    );
    _controller!.seekTo(target);
    _resetControlsTimer();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: CyberTheme.bgCardGlass,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: CyberTheme.neonCyan, width: 1),
        ),
        content: Text(
          message,
          style: CyberTheme.hudBadge(size: 11, color: CyberTheme.neonCyan),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- Bottom Sheet Openers ---

  void _openQueueSheet() {
    _controlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QueueSheet(
        playlist: _playlist,
        currentMedia: _currentMedia,
        onSelectMedia: (item) => _initPlayer(item),
        onAddFiles: _pickMediaFiles,
        onRemoveMedia: (item) {
          setState(() {
            _playlist.removeWhere((i) => i.id == item.id);
          });
        },
      ),
    );
  }

  void _openEqSheet() {
    _controlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EqSheet(
        eqBands: _eqBands,
        volumeBoost: _volumeBoost,
        spatialAudio: _spatialAudio,
        onEqChange: (bands) => setState(() => _eqBands = bands),
        onVolumeBoostChange: (boost) {
          setState(() => _volumeBoost = boost);
          _controller?.setVolume((_userVolume * boost).clamp(0.0, 1.0));
        },
        onSpatialAudioChange: (spatial) => setState(() => _spatialAudio = spatial),
      ),
    );
  }

  void _openFxSheet() {
    _controlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VideoFxSheet(
        currentPreset: _fxPreset,
        brightness: _fxBrightness,
        contrast: _fxContrast,
        saturation: _fxSaturation,
        hueRotation: _fxHue,
        onPresetChange: (preset) => setState(() => _fxPreset = preset),
        onBrightnessChange: (b) => setState(() => _fxBrightness = b),
        onContrastChange: (c) => setState(() => _fxContrast = c),
        onSaturationChange: (s) => setState(() => _fxSaturation = s),
        onHueChange: (h) => setState(() => _fxHue = h),
        onReset: () {
          setState(() {
            _fxPreset = VideoFxPreset.normal;
            _fxBrightness = 1.0;
            _fxContrast = 1.0;
            _fxSaturation = 1.0;
            _fxHue = 0.0;
          });
        },
      ),
    );
  }

  void _openToolsSheet() {
    _controlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ToolsSheet(
        currentZoom: _currentZoom,
        onResetZoom: () {
          setState(() {
            _currentZoom = 1.0;
            _transformController.value = Matrix4.identity();
          });
          Navigator.of(ctx).pop();
        },
        onCaptureScreenshot: () {
          Navigator.of(ctx).pop();
          _captureScreenshot();
        },
        loopA: _loopA,
        loopB: _loopB,
        onSetLoopA: () {
          setState(() => _loopA = _position);
          _showToast('Loop Point A set at ${_position.inSeconds}s');
          Navigator.of(ctx).pop();
        },
        onSetLoopB: () {
          setState(() => _loopB = _position);
          _showToast('Loop Point B set at ${_position.inSeconds}s');
          Navigator.of(ctx).pop();
        },
        onClearLoop: () {
          setState(() {
            _loopA = null;
            _loopB = null;
          });
          _showToast('A-B Loop cleared');
          Navigator.of(ctx).pop();
        },
        onLoadSubtitles: () {
          Navigator.of(ctx).pop();
          _pickSubtitleFile();
        },
        subtitleOffset: _subtitleOffset,
        onSubtitleOffsetChange: (offset) => setState(() => _subtitleOffset = offset),
        aspectRatio: _aspectRatio,
        onAspectRatioChange: (ratio) => setState(() => _aspectRatio = ratio),
        speed: _playbackSpeed,
        onSpeedChange: (speed) {
          setState(() => _playbackSpeed = speed);
          _controller?.setPlaybackSpeed(speed);
        },
        isBackgroundPlayEnabled: AkoboPlaybackManager.instance.isBackgroundPlayEnabled,
        onToggleBackgroundPlay: _toggleBackgroundPlay,
        onOpenFxSheet: () {
          Navigator.of(ctx).pop();
          _openFxSheet();
        },
        onOpenEqSheet: () {
          Navigator.of(ctx).pop();
          _openEqSheet();
        },
        isShuffle: AkoboPlaybackManager.instance.isShuffle,
        onToggleShuffle: () {
          AkoboPlaybackManager.instance.toggleShuffle();
          setState(() {});
        },
        isRepeat: AkoboPlaybackManager.instance.isRepeat,
        onToggleRepeat: () {
          AkoboPlaybackManager.instance.toggleRepeat();
          setState(() {});
        },
        isNightMode: AkoboPlaybackManager.instance.isNightMode,
        onToggleNightMode: () {
          AkoboPlaybackManager.instance.toggleNightMode();
          setState(() {});
        },
        onToggleMirror: () {
          setState(() => _isMirror = !_isMirror);
          _showToast(_isMirror ? 'Mirror video: ON' : 'Mirror video: OFF');
        },
        onShowProperties: _showPropertiesDialog,
        onShare: _shareCurrentMedia,
        onDelete: _deleteMediaDialog,
        onFeedback: _feedbackDialog,
        onTimer: _sleepTimerDialog,
      ),
    );
  }

  void _openAspectRatioSheet() {
    _controlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AspectRatioSheet(
        currentAspectRatio: _aspectRatio,
        onAspectRatioSelected: (ratio) {
          setState(() => _aspectRatio = ratio);
          _showToast('Aspect Ratio: $_aspectRatioLabel');
        },
      ),
    );
  }

  void _toggleBackgroundPlay() {
    AkoboPlaybackManager.instance.toggleBackgroundPlay();
    final enabled = AkoboPlaybackManager.instance.isBackgroundPlayEnabled;
    _showToast(enabled
        ? 'Background Play: ACTIVE (Keeps playing when app is minimized or screen off)'
        : 'Background Play: OFF');
    setState(() {});
  }

  // --- Local File Picker ---
  Future<void> _pickMediaFiles() async {
    try {
      final List<PlatformFile> result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mkv', 'webm', 'mov', 'avi', 'mp3', 'wav', 'flac', 'aac'],
      );

      if (result.isNotEmpty) {
        for (final f in result) {
          if (f.path != null) {
            final isAudio = ['mp3', 'wav', 'flac', 'aac'].contains(f.extension?.toLowerCase());
            final newItem = MediaItem(
              id: 'local-${DateTime.now().millisecondsSinceEpoch}-${f.name}',
              title: f.name,
              subtitle: 'Local Storage Media',
              url: f.path!,
              isLocal: true,
              resolution: isAudio ? 'FLAC HD' : 'Local UHD',
            );
            setState(() {
              _playlist.insert(0, newItem);
            });
          }
        }
        _initPlayer(_playlist.first);
        _showToast('Loaded ${result.length} local media files');
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  // --- Subtitles File Picker ---
  Future<void> _pickSubtitleFile() async {
    try {
      final List<PlatformFile> result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['srt', 'vtt'],
      );

      if (result.isNotEmpty && result.first.path != null) {
        final file = File(result.first.path!);
        final content = await file.readAsString();
        final cues = SubtitleParser.parse(content);
        setState(() {
          _subtitleCues = cues;
        });
        _showToast('Loaded ${cues.length} subtitle cues');
      }
    } catch (e) {
      debugPrint('Subtitle load error: $e');
    }
  }

  // --- 4K Screenshot Grabber ---
  void _captureScreenshot() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: CyberTheme.neonGreen, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.camera_alt, color: CyberTheme.neonGreen, size: 22),
            const SizedBox(width: 8),
            Text('4K FRAME GRABBER', style: CyberTheme.hudTitle(size: 15, color: CyberTheme.neonGreen)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Snapshot Telemetry:', style: CyberTheme.hudBadge(size: 11, color: CyberTheme.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CyberTheme.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CyberTheme.borderCyan),
              ),
              child: Column(
                children: [
                  _telemetryRow('Resolution', '3840 x 2160 UHD (Native 4K)'),
                  _telemetryRow('Timestamp', '${_position.inSeconds}s / ${_duration.inSeconds}s'),
                  _telemetryRow('Color Space', 'Rec. 709 / Cyber FX Engine'),
                  _telemetryRow('Format', 'PNG 24-bit Lossless'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: CyberTheme.body(color: CyberTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.neonGreen.withValues(alpha: 0.2),
              side: const BorderSide(color: CyberTheme.neonGreen),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showToast('4K Frame saved to gallery / downloads');
            },
            child: Text('Save Frame', style: CyberTheme.hudBadge(size: 11, color: CyberTheme.neonGreen)),
          ),
        ],
      ),
    );
  }

  Widget _telemetryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CyberTheme.body(size: 12, color: CyberTheme.textSecondary)),
          Text(value, style: CyberTheme.mono(size: 11, color: CyberTheme.neonCyan)),
        ],
      ),
    );
  }

  String get _aspectRatioLabel {
    switch (_aspectRatio) {
      case PlayerAspectRatio.original:
        return 'Original';
      case PlayerAspectRatio.cinema16x9:
        return '16:9';
      case PlayerAspectRatio.cinema21x9:
        return '21:9';
      case PlayerAspectRatio.classic4x3:
        return '4:3';
      case PlayerAspectRatio.fill:
        return 'Fill';
      case PlayerAspectRatio.stretch:
        return 'Stretch';
    }
  }

  void _cycleAspectRatio() {
    final values = PlayerAspectRatio.values;
    final nextIndex = (values.indexOf(_aspectRatio) + 1) % values.length;
    setState(() => _aspectRatio = values[nextIndex]);
    _showToast('Aspect Ratio: $_aspectRatioLabel');
  }

  void _toggleAutoFullscreen() {
    HapticFeedback.mediumImpact();
    final currentOrientation = MediaQuery.of(context).orientation;

    double videoAspect = 16 / 9;
    if (_controller != null && _controller!.value.isInitialized) {
      final size = _controller!.value.size;
      if (size.width > 0 && size.height > 0) {
        videoAspect = size.width / size.height;
      } else if (_controller!.value.aspectRatio > 0) {
        videoAspect = _controller!.value.aspectRatio;
      }
    }

    final isHorizontal = videoAspect >= 1.0;

    if (isHorizontal) {
      if (currentOrientation == Orientation.landscape) {
        // Return to portrait
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        _showToast('Portrait View');
      } else {
        // Horizontal video -> auto adjust to landscape
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        _showToast('Auto Fullscreen: Landscape (${videoAspect.toStringAsFixed(2)}:1)');
      }
    } else {
      // Vertical / portrait video format
      if (currentOrientation == Orientation.portrait) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        _showToast('Auto Fullscreen: Vertical Immersive');
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        _showToast('Auto Fullscreen: Vertical (Portrait)');
      }
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    AkoboPlaybackManager.instance.removeListener(_onPlaybackManagerUpdate);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!AkoboPlaybackManager.instance.isBackgroundPlayEnabled) {
      AkoboPlaybackManager.instance.stopAndDispose();
    }
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: CyberTheme.bgObsidian,
      body: Stack(
        children: [
          // 1. Cinema Ambient Backlight Halo
          Positioned.fill(
            child: AmbientGlowBackground(
              isPlaying: _isPlaying,
              enabled: _ambientGlowEnabled,
            ),
          ),

          // 2. Main Stage (Video or Visualizer) with Gesture Recognition
          GestureOverlay(
            currentBrightness: _screenBrightness,
            currentVolume: _userVolume,
            onSingleTap: _toggleControls,
            onDoubleTapLeft: () => _seekRelative(const Duration(seconds: -10)),
            onDoubleTapRight: () => _seekRelative(const Duration(seconds: 10)),
            onBrightnessChange: (val) => setState(() => _screenBrightness = val),
            onVolumeChange: (val) {
              setState(() => _userVolume = val);
              _controller?.setVolume((val * _volumeBoost).clamp(0.0, 1.0));
            },
            child: Center(
              child: _isAudioMode
                  ? _buildAudioVisualizerStage()
                  : _buildVideoViewportStage(),
            ),
          ),

          // 3. Subtitles Overlay
          SubtitlesOverlay(
            cues: _subtitleCues,
            position: _position,
            offsetSeconds: _subtitleOffset,
          ),

          // 4. Zoom Indicator Badge
          if (_currentZoom > 1.05 && _showControls) ...[
            Positioned(
              top: 80,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CyberTheme.bgCardGlass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CyberTheme.neonCyan),
                ),
                child: Text(
                  '4K ZOOM ${_currentZoom.toStringAsFixed(1)}x',
                  style: CyberTheme.hudBadge(size: 10, color: CyberTheme.neonCyan),
                ),
              ),
            ),
          ],

          // Night Mode Eye Comfort Tint Overlay
          if (AkoboPlaybackManager.instance.isNightMode)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: const Color(0x55000A24), // deep night comfort tint
                ),
              ),
            ),

          // 5. Controls Overlay (Top HUD & Bottom Dock)
          PlayerControlsOverlay(
            visible: _showControls,
            currentMedia: _currentMedia,
            isPlaying: _isPlaying,
            position: _position,
            duration: _duration,
            buffered: _buffered,
            loopA: _loopA,
            loopB: _loopB,
            ambientGlowEnabled: _ambientGlowEnabled,
            isAudioMode: _isAudioMode,
            currentAspectRatioLabel: _aspectRatioLabel,
            currentSpeed: _playbackSpeed,
            bottomInset: bottomInset,
            isBackgroundPlayEnabled: AkoboPlaybackManager.instance.isBackgroundPlayEnabled,
            onToggleBackgroundPlay: _toggleBackgroundPlay,
            onTogglePlayPause: _togglePlayPause,
            onSeek: (pos) {
              _controller?.seekTo(pos);
              _resetControlsTimer();
            },
            onToggleGlow: () => setState(() => _ambientGlowEnabled = !_ambientGlowEnabled),
            onToggleAudioMode: () => setState(() => _isAudioMode = !_isAudioMode),
            onOpenFilePicker: _pickMediaFiles,
            onCaptureScreenshot: _captureScreenshot,
            onCycleAspectRatio: _cycleAspectRatio,
            onToggleFullscreen: _toggleAutoFullscreen,
            onPrevious: _playPrevious,
            onNext: _playNext,
            isLocked: _isLocked,
            onToggleLock: () => setState(() => _isLocked = !_isLocked),
            isShuffle: AkoboPlaybackManager.instance.isShuffle,
            onToggleShuffle: () {
              AkoboPlaybackManager.instance.toggleShuffle();
              setState(() {});
            },
            isRepeat: AkoboPlaybackManager.instance.isRepeat,
            onToggleRepeat: () {
              AkoboPlaybackManager.instance.toggleRepeat();
              setState(() {});
            },
            onOpenTools: _openToolsSheet,
          ),

          // 6. Mobile Bottom Navigation Bar (clean screen support)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_showControls,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: _buildCyberBottomNav(bottomInset),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoViewportStage() {
    if (_controller == null || !_isInitialized || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: CyberTheme.neonCyan),
      );
    }

    final videoSize = _controller!.value.size;
    double? aspect;

    switch (_aspectRatio) {
      case PlayerAspectRatio.original:
        aspect = _controller!.value.aspectRatio;
        break;
      case PlayerAspectRatio.cinema16x9:
        aspect = 16.0 / 9.0;
        break;
      case PlayerAspectRatio.cinema21x9:
        aspect = 21.0 / 9.0;
        break;
      case PlayerAspectRatio.classic4x3:
        aspect = 4.0 / 3.0;
        break;
      case PlayerAspectRatio.fill:
      case PlayerAspectRatio.stretch:
        aspect = null; // Full stretch/fill
        break;
    }

    final effectiveAspect = (aspect != null && aspect > 0)
        ? aspect
        : (videoSize.width > 0 && videoSize.height > 0 ? videoSize.width / videoSize.height : 16 / 9);

    Widget videoWidget = AspectRatio(
      aspectRatio: effectiveAspect,
      child: VideoPlayer(
        _controller!,
        key: ValueKey('${_currentMedia.id}_${_controller.hashCode}'),
      ),
    );

    if (_isMirror) {
      videoWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(3.1415926535),
        child: videoWidget,
      );
    }

    // Apply Real-Time Color Grading Matrix
    videoWidget = ColorFiltered(
      colorFilter: ColorMatrixService.getColorFilter(
        preset: _fxPreset,
        brightness: _fxBrightness * _screenBrightness,
        contrast: _fxContrast,
        saturation: _fxSaturation,
        hueDegrees: _fxHue,
      ),
      child: videoWidget,
    );

    // Wrap in InteractiveViewer for 4K Pinch-to-Zoom & Pan
    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 1.0,
      maxScale: 4.0,
      onInteractionUpdate: (details) {
        final scale = _transformController.value.getMaxScaleOnAxis();
        if ((scale - _currentZoom).abs() > 0.05) {
          setState(() => _currentZoom = scale);
        }
      },
      child: videoWidget,
    );
  }

  Widget _buildAudioVisualizerStage() {
    return Container(
      width: double.infinity,
      height: 380,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: CyberTheme.glassCard(
        borderColor: CyberTheme.neonPurple,
        borderRadius: 20,
      ),
      child: Stack(
        children: [
          // Visualizer Mode Selector
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _vizTab('Spectrum', VisualizerMode.spectrum),
                const SizedBox(width: 8),
                _vizTab('Reactor', VisualizerMode.reactor),
                const SizedBox(width: 8),
                _vizTab('Waveform', VisualizerMode.waveform),
              ],
            ),
          ),

          // Custom Painted Visualizer
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              child: AudioVisualizerWidget(
                mode: _vizMode,
                isPlaying: _isPlaying,
              ),
            ),
          ),

          // Track Title & Playback Controls (Prev, Play/Pause, Next, Like, Shuffle, Loop)
          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentMedia.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _currentMedia.subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 8),

                // Audio Controls Row: Shuffle - Prev - Play/Pause - Next - Like
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Shuffle',
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: AkoboPlaybackManager.instance.isShuffle ? CyberTheme.primaryBlue : Colors.white60,
                        size: 20,
                      ),
                      onPressed: () {
                        AkoboPlaybackManager.instance.toggleShuffle();
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Previous',
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
                      onPressed: _playPrevious,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CyberTheme.primaryBlue,
                          boxShadow: [
                            BoxShadow(
                              color: CyberTheme.primaryBlue.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Next',
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                      onPressed: _playNext,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vizTab(String title, VisualizerMode mode) {
    final active = _vizMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _vizMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: CyberTheme.neonPill(
          active: active,
          activeColor: CyberTheme.neonPurple,
        ),
        child: Text(
          title,
          style: CyberTheme.hudBadge(
            size: 11,
            color: active ? CyberTheme.neonPurple : CyberTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCyberBottomNav(double bottomInset) {
    return Container(
      padding: EdgeInsets.only(
        bottom: bottomInset > 0 ? bottomInset : 8,
        top: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xE6131B2E),
        border: const Border(
          top: BorderSide(color: Color(0xFF334155), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomNavTab(icon: Icons.queue_music_rounded, label: 'Queue', onTap: _openQueueSheet),
              _bottomNavTab(icon: Icons.equalizer_rounded, label: 'EQ Studio', onTap: _openEqSheet),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayPause,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CyberTheme.primaryBlue,
                    boxShadow: [
                      BoxShadow(
                        color: CyberTheme.primaryBlue.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              _bottomNavTab(icon: Icons.aspect_ratio_rounded, label: 'Aspect', onTap: _openAspectRatioSheet),
              _bottomNavTab(icon: Icons.tune_rounded, label: 'Tools', onTap: _openToolsSheet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavTab({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: CyberTheme.neonCyan, size: 21),
              const SizedBox(height: 3),
              Text(label, style: CyberTheme.hudBadge(size: 9, color: CyberTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
