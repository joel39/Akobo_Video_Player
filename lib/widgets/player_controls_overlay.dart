import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../theme/cyber_theme.dart';
import 'scrubber_bar.dart';

class PlayerControlsOverlay extends StatelessWidget {
  final bool visible;
  final MediaItem currentMedia;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final Duration? loopA;
  final Duration? loopB;
  final bool ambientGlowEnabled;
  final bool isAudioMode;
  final String currentAspectRatioLabel;
  final double currentSpeed;
  final VoidCallback onTogglePlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onToggleGlow;
  final VoidCallback onToggleAudioMode;
  final VoidCallback onOpenFilePicker;
  final VoidCallback onCaptureScreenshot;
  final VoidCallback onCycleAspectRatio;
  final VoidCallback onToggleFullscreen;
  final double bottomInset;
  final bool isBackgroundPlayEnabled;
  final VoidCallback onToggleBackgroundPlay;

  // New requested features
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isLocked;
  final VoidCallback onToggleLock;
  final bool isShuffle;
  final VoidCallback onToggleShuffle;
  final bool isRepeat;
  final VoidCallback onToggleRepeat;
  final VoidCallback onOpenTools;

  const PlayerControlsOverlay({
    super.key,
    required this.visible,
    required this.currentMedia,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.buffered,
    this.loopA,
    this.loopB,
    required this.ambientGlowEnabled,
    required this.isAudioMode,
    required this.currentAspectRatioLabel,
    required this.currentSpeed,
    required this.onTogglePlayPause,
    required this.onSeek,
    required this.onToggleGlow,
    required this.onToggleAudioMode,
    required this.onOpenFilePicker,
    required this.onCaptureScreenshot,
    required this.onCycleAspectRatio,
    required this.onToggleFullscreen,
    this.bottomInset = 0.0,
    this.isBackgroundPlayEnabled = true,
    required this.onToggleBackgroundPlay,
    required this.onPrevious,
    required this.onNext,
    this.isLocked = false,
    required this.onToggleLock,
    this.isShuffle = false,
    required this.onToggleShuffle,
    this.isRepeat = false,
    required this.onToggleRepeat,
    required this.onOpenTools,
  });

  String _formatTime(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // If locked, only display the unlock button
    if (isLocked) {
      return SafeArea(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: GestureDetector(
              onTap: onToggleLock,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.6),
                  border: Border.all(color: CyberTheme.primaryBlue, width: 1.5),
                ),
                child: const Icon(Icons.lock_rounded, color: CyberTheme.primaryBlue, size: 28),
              ),
            ),
          ),
        ),
      );
    }

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: Stack(
          children: [
            // Dark Gradient Vignette for Readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.22, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // Top HUD Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentMedia.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentMedia.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),



                      // Settings / Tools Button
                      IconButton(
                        tooltip: 'Player tools',
                        icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                        onPressed: onOpenTools,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Center Playback Group: Previous, Play/Pause, Next
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Center Previous
                  IconButton(
                    tooltip: 'Previous',
                    icon: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      child: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
                    ),
                    onPressed: onPrevious,
                  ),
                  const SizedBox(width: 20),

                  // Center Play / Pause Floating Centerpiece
                  GestureDetector(
                    onTap: onTogglePlayPause,
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CyberTheme.primaryBlue.withValues(alpha: 0.9),
                        boxShadow: [
                          BoxShadow(
                            color: CyberTheme.primaryBlue.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Center Next
                  IconButton(
                    tooltip: 'Next',
                    icon: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                    ),
                    onPressed: onNext,
                  ),
                ],
              ),
            ),

            // Bottom Section: Quick Row + Scrubber + Image 3 Bottom Controls
            Positioned(
              bottom: 12 + (bottomInset > 0 ? bottomInset : 0),
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick Action Row above Scrubber matching Image 3:
                    // Shuffle, Music/Video mode, CC subtitles, Headphone background, PIP, Speed, Settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _iconButton(
                          icon: Icons.shuffle_rounded,
                          active: isShuffle,
                          tooltip: 'Shuffle',
                          onTap: onToggleShuffle,
                        ),
                        _iconButton(
                          icon: isAudioMode ? Icons.videocam_rounded : Icons.music_note_rounded,
                          active: isAudioMode,
                          tooltip: isAudioMode ? 'Video mode' : 'Audio studio mode',
                          onTap: onToggleAudioMode,
                        ),
                        _iconButton(
                          icon: Icons.closed_caption_rounded,
                          active: false,
                          tooltip: 'Subtitles',
                          onTap: onOpenTools,
                        ),
                        _iconButton(
                          icon: Icons.headphones_rounded,
                          active: isBackgroundPlayEnabled,
                          tooltip: 'Background Play',
                          onTap: onToggleBackgroundPlay,
                        ),
                        _iconButton(
                          icon: Icons.picture_in_picture_alt_rounded,
                          active: false,
                          tooltip: 'Picture-in-Picture',
                          onTap: onToggleFullscreen,
                        ),
                        _iconButton(
                          icon: Icons.speed_rounded,
                          active: currentSpeed != 1.0,
                          tooltip: 'Speed (${currentSpeed}x)',
                          onTap: onOpenTools,
                        ),
                        _iconButton(
                          icon: Icons.settings_rounded,
                          active: false,
                          tooltip: 'Settings',
                          onTap: onOpenTools,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Scrubber Bar
                    ScrubberBar(
                      position: position,
                      duration: duration,
                      buffered: buffered,
                      loopA: loopA,
                      loopB: loopB,
                      onSeek: onSeek,
                    ),

                    // Time display
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(position),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          Text(
                            _formatTime(duration),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Bottom Bar Controls matching Image 3:
                    // [Lock Icon] - [Previous |<] - [Play/Pause] - [Next >|] - [Resize/Fit]
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Screen Lock button
                        IconButton(
                          tooltip: 'Lock screen controls',
                          icon: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 24),
                          onPressed: onToggleLock,
                        ),

                        // Center playback group: Previous, Play/Pause, Next
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Previous button
                            IconButton(
                              tooltip: 'Previous',
                              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 32),
                              onPressed: onPrevious,
                            ),
                            const SizedBox(width: 8),

                            // Play / Pause button
                            IconButton(
                              tooltip: isPlaying ? 'Pause' : 'Play',
                              icon: Icon(
                                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                                color: CyberTheme.primaryBlue,
                                size: 44,
                              ),
                              onPressed: onTogglePlayPause,
                            ),
                            const SizedBox(width: 8),

                            // Next button
                            IconButton(
                              tooltip: 'Next',
                              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 32),
                              onPressed: onNext,
                            ),
                          ],
                        ),

                        // Aspect Ratio / Fit button
                        IconButton(
                          tooltip: 'Aspect Ratio: $currentAspectRatioLabel',
                          icon: const Icon(Icons.crop_free_rounded, color: Colors.white, size: 24),
                          onPressed: onCycleAspectRatio,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required bool active,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? CyberTheme.primaryBlue.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.35),
            border: Border.all(
              color: active ? CyberTheme.primaryBlue : Colors.white24,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? CyberTheme.primaryBlue : Colors.white,
          ),
        ),
      ),
    );
  }
}
