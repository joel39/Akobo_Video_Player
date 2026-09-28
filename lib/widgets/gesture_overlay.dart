import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/cyber_theme.dart';

class GestureOverlay extends StatefulWidget {
  final Widget child;
  final VoidCallback onSingleTap;
  final VoidCallback onDoubleTapLeft;
  final VoidCallback onDoubleTapRight;
  final ValueChanged<double> onBrightnessChange;
  final ValueChanged<double> onVolumeChange;
  final double currentBrightness;
  final double currentVolume;

  const GestureOverlay({
    super.key,
    required this.child,
    required this.onSingleTap,
    required this.onDoubleTapLeft,
    required this.onDoubleTapRight,
    required this.onBrightnessChange,
    required this.onVolumeChange,
    required this.currentBrightness,
    required this.currentVolume,
  });

  @override
  State<GestureOverlay> createState() => _GestureOverlayState();
}

class _GestureOverlayState extends State<GestureOverlay> {
  // Ripple animation state
  bool _showLeftRipple = false;
  bool _showRightRipple = false;
  Timer? _leftRippleTimer;
  Timer? _rightRippleTimer;

  // HUD meter indicators
  bool _showHudMeter = false;
  String _hudMeterTitle = '';
  double _hudMeterPercent = 1.0;
  IconData _hudMeterIcon = Icons.brightness_6;
  Timer? _hudMeterTimer;

  Timer? _singleTapTimer;

  void _triggerLeftRipple() {
    HapticFeedback.lightImpact();
    setState(() {
      _showLeftRipple = true;
    });
    _leftRippleTimer?.cancel();
    _leftRippleTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _showLeftRipple = false;
        });
      }
    });
    widget.onDoubleTapLeft();
  }

  void _triggerRightRipple() {
    HapticFeedback.lightImpact();
    setState(() {
      _showRightRipple = true;
    });
    _rightRippleTimer?.cancel();
    _rightRippleTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _showRightRipple = false;
        });
      }
    });
    widget.onDoubleTapRight();
  }

  void _showHud({
    required String title,
    required double percent,
    required IconData icon,
  }) {
    setState(() {
      _showHudMeter = true;
      _hudMeterTitle = title;
      _hudMeterPercent = percent.clamp(0.0, 2.0);
      _hudMeterIcon = icon;
    });
    _hudMeterTimer?.cancel();
    _hudMeterTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _showHudMeter = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _leftRippleTimer?.cancel();
    _rightRippleTimer?.cancel();
    _hudMeterTimer?.cancel();
    _singleTapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;

        return Stack(
          children: [
            // Base child (Video Player)
            widget.child,

            // Gesture Detector Layer
            Positioned.fill(
              child: Row(
                children: [
                  // Left Half (Rewind Double Tap & Brightness Swipe)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (_singleTapTimer != null && _singleTapTimer!.isActive) {
                          _singleTapTimer!.cancel();
                          _triggerLeftRipple();
                        } else {
                          _singleTapTimer = Timer(const Duration(milliseconds: 250), () {
                            widget.onSingleTap();
                          });
                        }
                      },
                      onVerticalDragUpdate: (details) {
                        final delta = -details.primaryDelta! / screenHeight;
                        final newBrightness = (widget.currentBrightness + delta * 2.0).clamp(0.5, 2.0);
                        widget.onBrightnessChange(newBrightness);
                        _showHud(
                          title: 'BRIGHTNESS',
                          percent: newBrightness,
                          icon: Icons.brightness_6,
                        );
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                  // Right Half (Forward Double Tap & Volume Swipe)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (_singleTapTimer != null && _singleTapTimer!.isActive) {
                          _singleTapTimer!.cancel();
                          _triggerRightRipple();
                        } else {
                          _singleTapTimer = Timer(const Duration(milliseconds: 250), () {
                            widget.onSingleTap();
                          });
                        }
                      },
                      onVerticalDragUpdate: (details) {
                        final delta = -details.primaryDelta! / screenHeight;
                        final newVolume = (widget.currentVolume + delta * 1.5).clamp(0.0, 1.0);
                        widget.onVolumeChange(newVolume);
                        _showHud(
                          title: 'VOLUME',
                          percent: newVolume,
                          icon: newVolume == 0 ? Icons.volume_off : Icons.volume_up,
                        );
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),

            // Left Animated Ripple Indicator (-10s)
            if (_showLeftRipple) ...[
              Positioned(
                left: 32,
                top: screenHeight / 2 - 50,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, val, child) {
                    return Opacity(
                      opacity: (2.0 - val * 1.5).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: val,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: CyberTheme.bgCardGlass,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: CyberTheme.neonCyan, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: CyberTheme.neonCyan.withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.replay_10, color: CyberTheme.neonCyan, size: 28),
                              const SizedBox(width: 8),
                              Text('-10s', style: CyberTheme.hudTitle(size: 16, color: CyberTheme.neonCyan)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Right Animated Ripple Indicator (+10s)
            if (_showRightRipple) ...[
              Positioned(
                right: 32,
                top: screenHeight / 2 - 50,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, val, child) {
                    return Opacity(
                      opacity: (2.0 - val * 1.5).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: val,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: CyberTheme.bgCardGlass,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: CyberTheme.neonCyan, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: CyberTheme.neonCyan.withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('+10s', style: CyberTheme.hudTitle(size: 16, color: CyberTheme.neonCyan)),
                              const SizedBox(width: 8),
                              const Icon(Icons.forward_10, color: CyberTheme.neonCyan, size: 28),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Vertical Live HUD Meter (Brightness / Volume)
            if (_showHudMeter) ...[
              Center(
                child: AnimatedOpacity(
                  opacity: _showHudMeter ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 70,
                    height: 190,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    decoration: CyberTheme.glassCard(
                      borderColor: CyberTheme.neonCyan,
                      borderRadius: 18,
                      shadows: [
                        BoxShadow(
                          color: CyberTheme.neonCyan.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(_hudMeterIcon, color: CyberTheme.neonCyan, size: 22),
                        // Meter Bar
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            width: 10,
                            decoration: BoxDecoration(
                              color: CyberTheme.bgSurface,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: CyberTheme.borderCyan),
                            ),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                FractionallySizedBox(
                                  heightFactor: (_hudMeterPercent / (_hudMeterTitle == 'BRIGHTNESS' ? 2.0 : 1.0)).clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: CyberTheme.cyanPurpleGradient,
                                      borderRadius: BorderRadius.circular(5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: CyberTheme.neonCyan.withValues(alpha: 0.7),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          '${(_hudMeterPercent * 100).toInt()}%',
                          style: CyberTheme.hudBadge(size: 11, color: CyberTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
