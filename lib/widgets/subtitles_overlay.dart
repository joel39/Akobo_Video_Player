import 'package:flutter/material.dart';
import '../services/subtitle_parser.dart';
import '../theme/cyber_theme.dart';

class SubtitlesOverlay extends StatelessWidget {
  final List<SubtitleCue> cues;
  final Duration position;
  final double offsetSeconds;

  const SubtitlesOverlay({
    super.key,
    required this.cues,
    required this.position,
    required this.offsetSeconds,
  });

  @override
  Widget build(BuildContext context) {
    if (cues.isEmpty) return const SizedBox.shrink();

    final text = SubtitleParser.getActiveSubtitle(cues, position, offsetSeconds);
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 90,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CyberTheme.borderCyan.withValues(alpha: 0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 10,
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: CyberTheme.bodyBold(
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
