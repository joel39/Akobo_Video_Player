import 'package:flutter/material.dart';
import '../services/akobo_playback_manager.dart';
import '../theme/cyber_theme.dart';

/// Floating mini-player dock shown on the Home Screen when media is active.
class MiniPlayerDock extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onClose;

  const MiniPlayerDock({
    super.key,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CyberTheme.isDark(context);
    final manager = AkoboPlaybackManager.instance;
    final item = manager.currentMedia;
    if (item == null) return const SizedBox.shrink();

    final isPlaying = manager.isPlaying;
    final isAudio = item.resolution.contains('Audio') ||
        item.resolution.contains('FLAC') ||
        item.resolution.contains('MP3');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: CyberTheme.primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // Thumbnail or Cover Image
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: CyberTheme.primaryBlue.withValues(alpha: 0.12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                      ? Image.network(
                          item.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _buildPlaceholderIcon(isAudio),
                        )
                      : _buildPlaceholderIcon(isAudio),
                ),
                const SizedBox(width: 10),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: CyberTheme.primaryBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.resolution,
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: CyberTheme.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? CyberTheme.darkTextSecondary : CyberTheme.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),



                // Previous Button
                IconButton(
                  tooltip: 'Previous',
                  icon: Icon(
                    Icons.skip_previous_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 22,
                  ),
                  onPressed: manager.previous,
                ),

                // Play / Pause Button
                IconButton(
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                    color: CyberTheme.primaryBlue,
                    size: 32,
                  ),
                  onPressed: manager.togglePlayPause,
                ),

                // Next Button
                IconButton(
                  tooltip: 'Next',
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 22,
                  ),
                  onPressed: manager.next,
                ),

                // Close Button
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 18,
                  ),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(bool isAudio) {
    return Center(
      child: Icon(
        isAudio ? Icons.music_note_rounded : Icons.play_arrow_rounded,
        color: CyberTheme.primaryBlue,
        size: 24,
      ),
    );
  }
}
