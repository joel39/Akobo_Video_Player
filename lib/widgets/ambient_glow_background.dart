import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';

class AmbientGlowBackground extends StatefulWidget {
  final bool isPlaying;
  final bool enabled;

  const AmbientGlowBackground({
    super.key,
    required this.isPlaying,
    this.enabled = true,
  });

  @override
  State<AmbientGlowBackground> createState() => _AmbientGlowBackgroundState();
}

class _AmbientGlowBackgroundState extends State<AmbientGlowBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Container(color: CyberTheme.bgObsidian);
    }

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final opacity = widget.isPlaying ? _pulseAnim.value : 0.18;

        return Container(
          decoration: BoxDecoration(
            color: CyberTheme.bgObsidian,
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                CyberTheme.neonCyan.withValues(alpha: opacity * 0.35),
                CyberTheme.neonPurple.withValues(alpha: opacity * 0.25),
                CyberTheme.bgSurface.withValues(alpha: 0.9),
                CyberTheme.bgObsidian,
              ],
              stops: const [0.0, 0.4, 0.75, 1.0],
            ),
          ),
        );
      },
    );
  }
}
