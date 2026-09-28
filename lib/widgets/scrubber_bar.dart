import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';

class ScrubberBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final Duration? loopA;
  final Duration? loopB;
  final ValueChanged<Duration> onSeek;

  const ScrubberBar({
    super.key,
    required this.position,
    required this.duration,
    required this.buffered,
    this.loopA,
    this.loopB,
    required this.onSeek,
  });

  @override
  State<ScrubberBar> createState() => _ScrubberBarState();
}

class _ScrubberBarState extends State<ScrubberBar> {
  bool _isDragging = false;
  double _dragPositionFraction = 0.0;

  double get _currentFraction {
    if (widget.duration.inMilliseconds == 0) return 0.0;
    if (_isDragging) return _dragPositionFraction.clamp(0.0, 1.0);
    return (widget.position.inMilliseconds / widget.duration.inMilliseconds).clamp(0.0, 1.0);
  }

  double get _bufferedFraction {
    if (widget.duration.inMilliseconds == 0) return 0.0;
    return (widget.buffered.inMilliseconds / widget.duration.inMilliseconds).clamp(0.0, 1.0);
  }

  void _handleSeek(double localDx, double totalWidth) {
    if (totalWidth <= 0 || widget.duration.inMilliseconds == 0) return;
    final fraction = (localDx / totalWidth).clamp(0.0, 1.0);
    final targetMillis = (fraction * widget.duration.inMilliseconds).round();
    widget.onSeek(Duration(milliseconds: targetMillis));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const barHeight = 4.5;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            setState(() {
              _isDragging = true;
              _dragPositionFraction = details.localPosition.dx / width;
            });
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragPositionFraction = details.localPosition.dx / width;
            });
          },
          onHorizontalDragEnd: (details) {
            _handleSeek(details.localPosition.dx, width);
            setState(() {
              _isDragging = false;
            });
          },
          onTapDown: (details) {
            _handleSeek(details.localPosition.dx, width);
          },
          child: SizedBox(
            height: 32,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 1. Background Track
                Container(
                  height: barHeight,
                  width: width,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(barHeight / 2),
                  ),
                ),

                // 2. Buffered Track
                Container(
                  height: barHeight,
                  width: (width * _bufferedFraction).clamp(0.0, width),
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(barHeight / 2),
                  ),
                ),

                // 3. A-B Loop Interval Highlight
                if (widget.loopA != null &&
                    widget.loopB != null &&
                    widget.duration.inMilliseconds > 0) ...[
                  Positioned(
                    left: (width * (widget.loopA!.inMilliseconds / widget.duration.inMilliseconds))
                        .clamp(0.0, width),
                    width: (width *
                            ((widget.loopB!.inMilliseconds - widget.loopA!.inMilliseconds) /
                                widget.duration.inMilliseconds))
                        .clamp(0.0, width),
                    child: Container(
                      height: barHeight + 4,
                      decoration: BoxDecoration(
                        color: CyberTheme.primaryBlue.withValues(alpha: 0.35),
                        border: const Border.symmetric(
                          vertical: BorderSide(color: CyberTheme.primaryBlue, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],

                // 4. Progress Played Track
                Container(
                  height: barHeight,
                  width: (width * _currentFraction).clamp(0.0, width),
                  decoration: BoxDecoration(
                    color: CyberTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(barHeight / 2),
                    boxShadow: [
                      BoxShadow(
                        color: CyberTheme.primaryBlue.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),

                // 5. Thumb Cursor
                Positioned(
                  left: ((width * _currentFraction) - 7).clamp(0.0, width - 14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _isDragging ? 16 : 13,
                    height: _isDragging ? 16 : 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: CyberTheme.primaryBlue, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: CyberTheme.primaryBlue.withValues(alpha: 0.8),
                          blurRadius: _isDragging ? 10 : 6,
                          spreadRadius: _isDragging ? 2 : 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
