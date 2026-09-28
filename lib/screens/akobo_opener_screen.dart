import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/media_scanner_service.dart';
import '../theme/cyber_theme.dart';
import 'akobo_home_screen.dart';

class AkoboOpenerScreen extends StatefulWidget {
  const AkoboOpenerScreen({super.key});

  @override
  State<AkoboOpenerScreen> createState() => _AkoboOpenerScreenState();
}

class _AkoboOpenerScreenState extends State<AkoboOpenerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  final List<String> _bootLogs = [];
  MediaScannerResult? _scanResult;

  @override
  void initState() {
    super.initState();

    // 1. Orbital Ring Rotation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 2. Pulse Controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // 3. Progress Controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack)),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: const Interval(0.0, 0.25, curve: Curves.easeIn)),
    );

    _progressController.forward();
    _runBootSequence();
  }

  Future<void> _runBootSequence() async {
    void addLog(String text) {
      if (mounted) {
        setState(() => _bootLogs.add(text));
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    addLog('Initializing Media Engine...');

    await Future.delayed(const Duration(milliseconds: 600));
    addLog('Loading Hardware Decoders...');

    // Start background local storage scan
    final scanFuture = MediaScannerService.scanDeviceMedia();

    await Future.delayed(const Duration(milliseconds: 700));
    addLog('Scanning Phone Media...');

    _scanResult = await scanFuture;

    await Future.delayed(const Duration(milliseconds: 600));
    addLog('Ready');

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (ctx, anim, secAnim) => AkoboHomeScreen(initialMedia: _scanResult),
          transitionsBuilder: (ctx, anim, secAnim, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.bgObsidian,
      body: Stack(
        children: [
          // Background Radial Glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final val = _pulseController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1 + val * 0.2,
                    colors: [
                      const Color(0xFF2563EB).withValues(alpha: 0.18 + val * 0.08),
                      const Color(0xFF1E40AF).withValues(alpha: 0.12),
                      const Color(0xFF0F172A),
                      const Color(0xFF020617),
                    ],
                    stops: const [0.0, 0.45, 0.8, 1.0],
                  ),
                ),
              );
            },
          ),

          // Center Stage Emblem & Rings
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating Outer Orbital Ring
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * math.pi,
                            child: CustomPaint(
                              size: const Size(190, 190),
                              painter: OrbitalRingPainter(
                                color: CyberTheme.primaryBlue,
                                ticks: 24,
                              ),
                            ),
                          );
                        },
                      ),

                      // Counter-Rotating Inner Tech Ring
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: -_rotationController.value * 2 * math.pi * 1.5,
                            child: CustomPaint(
                              size: const Size(150, 150),
                              painter: OrbitalRingPainter(
                                color: const Color(0xFF60A5FA),
                                ticks: 16,
                              ),
                            ),
                          );
                        },
                      ),

                      // Animated Logo
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.75),
                                      blurRadius: 36,
                                      spreadRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
                                      blurRadius: 50,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) {
                                      return Container(
                                        color: const Color(0xFF1E293B),
                                        child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF2563EB), size: 60),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Brand Title
                ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      colors: [Colors.white, Color(0xFF93C5FD), Color(0xFF3B82F6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'AKOBO',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'VIDEO PLAYER',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6.0,
                    color: Color(0xFF60A5FA),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'ULTRA HD MEDIA STATION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),

                const SizedBox(height: 38),

                // Animated Progress Bar
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    final progress = _progressController.value;
                    return Column(
                      children: [
                        Container(
                          width: 240,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2563EB), Color(0xFF60A5FA), Color(0xFF93C5FD)],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.9),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _bootLogs.isNotEmpty ? _bootLogs.last : 'Loading...',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom Version Badge
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'AKOBO ENGINE • 4K HDR',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrbitalRingPainter extends CustomPainter {
  final Color color;
  final int ticks;

  OrbitalRingPainter({required this.color, required this.ticks});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Thin Ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 4, ringPaint);

    // Ticks
    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final angleStep = 2 * math.pi / ticks;
    for (int i = 0; i < ticks; i++) {
      if (i % 3 == 0) continue; // broken futuristic aesthetic
      final angle = i * angleStep;
      final p1 = Offset(center.dx + (radius - 8) * math.cos(angle), center.dy + (radius - 8) * math.sin(angle));
      final p2 = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant OrbitalRingPainter oldDelegate) => false;
}
