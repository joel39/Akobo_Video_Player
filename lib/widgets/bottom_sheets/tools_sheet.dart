import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/cyber_theme.dart';

enum PlayerAspectRatio {
  original,
  cinema16x9,
  cinema21x9,
  classic4x3,
  fill,
  stretch,
}

class ToolsSheet extends StatefulWidget {
  final double currentZoom;
  final VoidCallback onResetZoom;
  final VoidCallback onCaptureScreenshot;
  final Duration? loopA;
  final Duration? loopB;
  final VoidCallback onSetLoopA;
  final VoidCallback onSetLoopB;
  final VoidCallback onClearLoop;
  final VoidCallback onLoadSubtitles;
  final double subtitleOffset;
  final ValueChanged<double> onSubtitleOffsetChange;
  final PlayerAspectRatio aspectRatio;
  final ValueChanged<PlayerAspectRatio> onAspectRatioChange;
  final double speed;
  final ValueChanged<double> onSpeedChange;
  final bool isBackgroundPlayEnabled;
  final VoidCallback onToggleBackgroundPlay;
  final VoidCallback onOpenFxSheet;
  final VoidCallback onOpenEqSheet;
  final bool isShuffle;
  final VoidCallback onToggleShuffle;
  final bool isRepeat;
  final VoidCallback onToggleRepeat;
  final bool isNightMode;
  final VoidCallback onToggleNightMode;
  final VoidCallback? onToggleMirror;
  final VoidCallback? onShowProperties;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onFeedback;
  final VoidCallback? onTimer;

  const ToolsSheet({
    super.key,
    required this.currentZoom,
    required this.onResetZoom,
    required this.onCaptureScreenshot,
    this.loopA,
    this.loopB,
    required this.onSetLoopA,
    required this.onSetLoopB,
    required this.onClearLoop,
    required this.onLoadSubtitles,
    required this.subtitleOffset,
    required this.onSubtitleOffsetChange,
    required this.aspectRatio,
    required this.onAspectRatioChange,
    required this.speed,
    required this.onSpeedChange,
    this.isBackgroundPlayEnabled = true,
    required this.onToggleBackgroundPlay,
    required this.onOpenFxSheet,
    required this.onOpenEqSheet,
    this.isShuffle = false,
    required this.onToggleShuffle,
    this.isRepeat = false,
    required this.onToggleRepeat,
    this.isNightMode = false,
    required this.onToggleNightMode,
    this.onToggleMirror,
    this.onShowProperties,
    this.onShare,
    this.onDelete,
    this.onFeedback,
    this.onTimer,
  });

  @override
  State<ToolsSheet> createState() => _ToolsSheetState();
}

class _ToolsSheetState extends State<ToolsSheet> {
  late bool _isBackground;
  late bool _isShuffle;
  late bool _isRepeat;
  late bool _isNight;
  bool _isMirror = false;
  bool _isHwDecoder = true;
  String? _statusBanner;

  @override
  void initState() {
    super.initState();
    _isBackground = widget.isBackgroundPlayEnabled;
    _isShuffle = widget.isShuffle;
    _isRepeat = widget.isRepeat;
    _isNight = widget.isNightMode;
  }

  void _respond(String message) {
    HapticFeedback.lightImpact();
    setState(() {
      _statusBanner = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CyberTheme.isDark(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header + Live Response Pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: CyberTheme.primaryBlue, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Player Tools & Options',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  if (_statusBanner != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: CyberTheme.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CyberTheme.primaryBlue.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        _statusBanner!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: CyberTheme.primaryBlue,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // --- Quick Tools 4-Column Grid matching Image 3 ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Row 1: Background Play, Equalizer, Night Mode, Timer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _actionItem(
                              icon: Icons.headphones_rounded,
                              label: 'Background Play',
                              active: _isBackground,
                              onTap: () {
                                setState(() => _isBackground = !_isBackground);
                                widget.onToggleBackgroundPlay();
                                _respond(_isBackground ? 'Background: ON' : 'Background: OFF');
                              },
                              isDark: isDark,
                            ),
                            _actionItem(
                              icon: Icons.tune_rounded,
                              label: 'Equalizer',
                              active: false,
                              onTap: () {
                                _respond('Opening Equalizer...');
                                widget.onOpenEqSheet();
                              },
                              isDark: isDark,
                            ),
                            _actionItem(
                              icon: Icons.nightlight_round,
                              label: 'Night Mode',
                              active: _isNight,
                              onTap: () {
                                setState(() => _isNight = !_isNight);
                                widget.onToggleNightMode();
                                _respond(_isNight ? 'Night Mode: ON' : 'Night Mode: OFF');
                              },
                              isDark: isDark,
                            ),
                            _actionItem(
                              icon: Icons.timer_outlined,
                              label: 'Timer',
                              active: false,
                              onTap: () {
                                _respond('Sleep Timer');
                                widget.onTimer?.call();
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 2: AB Repeat, Mirror, Decoder, Loop
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _actionItem(
                              icon: Icons.repeat_on_rounded,
                              label: 'AB Repeat',
                              active: widget.loopA != null,
                              onTap: () {
                                if (widget.loopA == null) {
                                  widget.onSetLoopA();
                                  _respond('Loop Point A set');
                                } else if (widget.loopB == null) {
                                  widget.onSetLoopB();
                                  _respond('Loop Point B set (Looping)');
                                } else {
                                  widget.onClearLoop();
                                  _respond('Loop Cleared');
                                }
                              },
                              isDark: isDark,
                            ),
                            _actionItem(
                              icon: Icons.flip_rounded,
                              label: 'Mirror',
                              active: _isMirror,
                              onTap: () {
                                setState(() => _isMirror = !_isMirror);
                                widget.onToggleMirror?.call();
                                _respond(_isMirror ? 'Mirror: ON' : 'Mirror: OFF');
                              },
                              isDark: isDark,
                            ),
                            _actionItem(
                              icon: Icons.memory_rounded,
                              label: _isHwDecoder ? 'Decoder HW' : 'Decoder SW',
                              active: _isHwDecoder,
                              onTap: () {
                                setState(() => _isHwDecoder = !_isHwDecoder);
                                _respond(_isHwDecoder ? 'Hardware Decoder (HW)' : 'Software Decoder (SW)');
                              },
                              isDark: isDark,
                            ),
                            _actionItem(
                              icon: Icons.repeat_rounded,
                              label: 'Loop',
                              active: _isRepeat,
                              onTap: () {
                                setState(() => _isRepeat = !_isRepeat);
                                widget.onToggleRepeat();
                                _respond(_isRepeat ? 'Loop Track: ON' : 'Loop: OFF');
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 3: Shuffle, Properties, Share, Delete
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _actionItem(
                              icon: Icons.shuffle_rounded,
                              label: 'Shuffle',
                              active: _isShuffle,
                              onTap: () {
                                setState(() => _isShuffle = !_isShuffle);
                                widget.onToggleShuffle();
                                _respond(_isShuffle ? 'Shuffle: ON' : 'Shuffle: OFF');
                              },
                              isDark: isDark,
                            ),
                            _actionItem(
                              icon: Icons.info_outline_rounded,
                              label: 'Properties',
                              active: false,
                              onTap: () {
                                _respond('Media Properties');
                                widget.onShowProperties?.call();
                              },
                              isDark: isDark,
                            ),
                            _actionItem(
                              icon: Icons.share_rounded,
                              label: 'Share',
                              active: false,
                              onTap: () {
                                _respond('Sharing Media...');
                                widget.onShare?.call();
                              },
                              isDark: isDark,
                            ),
                            _actionItem(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete',
                              active: false,
                              onTap: () {
                                _respond('Delete Media');
                                widget.onDelete?.call();
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 4: Feedback
                        Row(
                          children: [
                            _actionItem(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: 'Feedback',
                              active: false,
                              onTap: () {
                                _respond('Send Feedback');
                                widget.onFeedback?.call();
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Aspect Ratio Selector
                  Text(
                    'ASPECT RATIO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? CyberTheme.darkTextSecondary : CyberTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _aspectPill('Original', PlayerAspectRatio.original, isDark),
                      _aspectPill('16:9 Wide', PlayerAspectRatio.cinema16x9, isDark),
                      _aspectPill('21:9 Cinema', PlayerAspectRatio.cinema21x9, isDark),
                      _aspectPill('4:3 Classic', PlayerAspectRatio.classic4x3, isDark),
                      _aspectPill('Fill Screen', PlayerAspectRatio.fill, isDark),
                      _aspectPill('Stretch', PlayerAspectRatio.stretch, isDark),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Playback Speed Selector
                  Text(
                    'PLAYBACK SPEED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? CyberTheme.darkTextSecondary : CyberTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _speedPill(0.5, '0.5x', isDark),
                      _speedPill(0.75, '0.75x', isDark),
                      _speedPill(1.0, '1.0x Normal', isDark),
                      _speedPill(1.25, '1.25x', isDark),
                      _speedPill(1.5, '1.5x', isDark),
                      _speedPill(2.0, '2.0x', isDark),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Subtitle Sync Offset
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SUBTITLE SYNC OFFSET',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            Text(
                              '${widget.subtitleOffset >= 0 ? '+' : ''}${widget.subtitleOffset.toStringAsFixed(1)}s',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: CyberTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _syncButton('-0.1s', () => widget.onSubtitleOffsetChange(widget.subtitleOffset - 0.1), isDark),
                            const SizedBox(width: 8),
                            _syncButton('Reset', () => widget.onSubtitleOffsetChange(0.0), isDark),
                            const SizedBox(width: 8),
                            _syncButton('+0.1s', () => widget.onSubtitleOffsetChange(widget.subtitleOffset + 0.1), isDark),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return SizedBox(
      width: 72,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: active
                    ? CyberTheme.primaryBlue.withValues(alpha: 0.2)
                    : (isDark ? const Color(0xFF0F172A) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active
                      ? CyberTheme.primaryBlue
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: active ? 1.5 : 1.0,
                ),
              ),
              child: Icon(
                icon,
                size: 22,
                color: active
                    ? CyberTheme.primaryBlue
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active
                    ? CyberTheme.primaryBlue
                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aspectPill(String title, PlayerAspectRatio ratio, bool isDark) {
    final active = widget.aspectRatio == ratio;
    return GestureDetector(
      onTap: () => widget.onAspectRatioChange(ratio),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? CyberTheme.primaryBlue
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? CyberTheme.primaryBlue : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _speedPill(double val, String label, bool isDark) {
    final active = (widget.speed - val).abs() < 0.05;
    return GestureDetector(
      onTap: () => widget.onSpeedChange(val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? CyberTheme.primaryBlue
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? CyberTheme.primaryBlue : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _syncButton(String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: CyberTheme.primaryBlue),
        ),
      ),
    );
  }
}
