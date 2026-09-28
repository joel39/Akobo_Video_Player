import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/thumbnail_service.dart';
import '../theme/cyber_theme.dart';

class VideoThumbnailWidget extends StatelessWidget {
  final MediaItem item;

  const VideoThumbnailWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CyberTheme.isDark(context);
    final isAudio = item.resolution.contains('Audio') ||
        item.resolution.contains('FLAC') ||
        item.resolution.contains('MP3') ||
        item.resolution.contains('AAC');

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base Background
        Container(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),

        // Thumbnail Content
        if (item.isLocal || item.coverUrl == null || item.coverUrl!.isEmpty)
          FutureBuilder<Uint8List?>(
            future: ThumbnailService.getThumbnail(item.url),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData &&
                  snapshot.data != null) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                );
              }
              if (item.coverUrl != null && item.coverUrl!.isNotEmpty) {
                return Image.network(
                  item.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => _fallbackPlaceholder(isAudio),
                );
              }
              return _fallbackPlaceholder(isAudio);
            },
          )
        else
          Image.network(
            item.coverUrl!,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) {
              return FutureBuilder<Uint8List?>(
                future: ThumbnailService.getThumbnail(item.url),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    );
                  }
                  return _fallbackPlaceholder(isAudio);
                },
              );
            },
          ),

        // Subtle Vignette Overlay for Crisp Readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackPlaceholder(bool isAudio) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CyberTheme.primaryBlue.withValues(alpha: 0.15),
        ),
        child: Icon(
          isAudio ? Icons.music_note_rounded : Icons.play_arrow_rounded,
          color: CyberTheme.primaryBlue,
          size: 28,
        ),
      ),
    );
  }
}
