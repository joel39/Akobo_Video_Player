import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';

enum VisualizerMode {
  spectrum,
  reactor,
  waveform,
}

class AudioVisualizerWidget extends StatefulWidget {
  final VisualizerMode mode;
  final bool isPlaying;

  const AudioVisualizerWidget({
    super.key,
    required this.mode,
    required this.isPlaying,
  });

  @override
  State<AudioVisualizerWidget> createState() => _AudioVisualizerWidgetState();
}

class _AudioVisualizerWidgetState extends State<AudioVisualizerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        CustomPainter painter;
        switch (widget.mode) {
          case VisualizerMode.spectrum:
            painter = SpectrumPainter(
              progress: _controller.value,
              isPlaying: widget.isPlaying,
            );
            break;
          case VisualizerMode.reactor:
            painter = ReactorPainter(
              progress: _controller.value,
              isPlaying: widget.isPlaying,
            );
            break;
          case VisualizerMode.waveform:
            painter = WaveformPainter(
              progress: _controller.value,
              isPlaying: widget.isPlaying,
            );
            break;
        }

        return CustomPaint(
          size: Size.infinite,
          painter: painter,
        );
      },
    );
  }
}

/// 1. Spectrum Equalizer Bars
class SpectrumPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;

  SpectrumPainter({required this.progress, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const int barCount = 32;
    final double barWidth = (size.width - (barCount - 1) * 3) / barCount;
    final double baselineY = size.height * 0.85;

    for (int i = 0; i < barCount; i++) {
      final double normalizedI = i / barCount;
      // Synthesize realistic audio frequency peaks
      final double wave1 = math.sin(progress * 2 * math.pi + i * 0.4);
      final double wave2 = math.cos(progress * 4 * math.pi + i * 0.8);
      final double heightFactor = isPlaying
          ? (0.25 + 0.45 * (wave1.abs() * 0.6 + wave2.abs() * 0.4) * (1.0 - (normalizedI - 0.5).abs() * 0.6))
          : 0.08;

      final double barHeight = size.height * 0.65 * heightFactor.clamp(0.05, 1.0);
      final double x = i * (barWidth + 3);
      final double topY = baselineY - barHeight;

      final rect = Rect.fromLTWH(x, topY, barWidth, barHeight);
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CyberTheme.neonCyan, CyberTheme.neonPurple],
        ).createShader(rect);

      // Rounded bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint,
      );

      // Peak Cap dot
      if (isPlaying) {
        final peakY = (topY - 5).clamp(0.0, baselineY);
        final capPaint = Paint()..color = CyberTheme.neonGreen.withValues(alpha: 0.9);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, peakY, barWidth, 2.5),
            const Radius.circular(1.5),
          ),
          capPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpectrumPainter oldDelegate) => true;
}

/// 2. Holographic Quantum Reactor (Circular radial visualizer)
class ReactorPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;

  ReactorPainter({required this.progress, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minDim = math.min(size.width, size.height);
    final radius = minDim * 0.32;

    // Glowing core gradient
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          CyberTheme.neonCyan.withValues(alpha: isPlaying ? 0.4 : 0.15),
          CyberTheme.neonPurple.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));

    canvas.drawCircle(center, radius * 1.5, corePaint);

    // Inner pulsating ring
    final pulseOffset = isPlaying ? math.sin(progress * 2 * math.pi) * 8 : 0;
    final innerRingPaint = Paint()
      ..color = CyberTheme.neonCyan.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 0.6 + pulseOffset, innerRingPaint);

    // Outer rotating ticks
    const int tickCount = 48;
    final angleStep = 2 * math.pi / tickCount;
    final rotationAngle = progress * 2 * math.pi;

    for (int i = 0; i < tickCount; i++) {
      final angle = rotationAngle + i * angleStep;
      final wave = math.sin(progress * 6 * math.pi + i * 0.5);
      final tickLength = isPlaying ? (12.0 + wave.abs() * 20.0) : 8.0;

      final startPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + (radius + tickLength) * math.cos(angle),
        center.dy + (radius + tickLength) * math.sin(angle),
      );

      final tickPaint = Paint()
        ..color = (i % 4 == 0) ? CyberTheme.neonPink : CyberTheme.neonCyan
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startPoint, endPoint, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ReactorPainter oldDelegate) => true;
}

/// 3. Waveform Oscillogram (Fluids glowing sine waves)
class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;

  WaveformPainter({required this.progress, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final width = size.width;

    void drawSineWave({
      required double freq,
      required double amp,
      required double speed,
      required Color color,
      required double strokeWidth,
    }) {
      final path = Path();
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      path.moveTo(0, centerY);
      for (double x = 0; x <= width; x += 4) {
        final normX = x / width;
        final envelope = math.sin(normX * math.pi); // Tapers edges
        final yOffset = math.sin((normX * freq * 2 * math.pi) + (progress * speed * 2 * math.pi)) *
            (isPlaying ? amp : 6.0) *
            envelope;
        path.lineTo(x, centerY + yOffset);
      }
      canvas.drawPath(path, paint);
    }

    // Layer 1: Neon Cyan Lead Wave
    drawSineWave(
      freq: 2.5,
      amp: size.height * 0.22,
      speed: 1.5,
      color: CyberTheme.neonCyan.withValues(alpha: 0.9),
      strokeWidth: 3.0,
    );

    // Layer 2: Neon Purple Sub-Harmonic Wave
    drawSineWave(
      freq: 4.0,
      amp: size.height * 0.16,
      speed: -1.0,
      color: CyberTheme.neonPurple.withValues(alpha: 0.75),
      strokeWidth: 2.0,
    );

    // Layer 3: Neon Green High-Frequency Resonance
    drawSineWave(
      freq: 7.0,
      amp: size.height * 0.08,
      speed: 2.2,
      color: CyberTheme.neonGreen.withValues(alpha: 0.65),
      strokeWidth: 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}
