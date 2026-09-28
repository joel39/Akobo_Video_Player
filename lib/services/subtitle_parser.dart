/// Subtitle cue model
class SubtitleCue {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
  });
}

class SubtitleParser {
  /// Parses .srt or .vtt raw text content into cues
  static List<SubtitleCue> parse(String content) {
    final List<SubtitleCue> cues = [];
    final lines = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

    int index = 0;
    while (index < lines.length) {
      final line = lines[index].trim();
      if (line.isEmpty || line.startsWith('WEBVTT') || int.tryParse(line) != null) {
        index++;
        continue;
      }

      // Check if line contains time arrow '-->'
      if (line.contains('-->')) {
        final parts = line.split('-->');
        if (parts.length >= 2) {
          final start = _parseTimestamp(parts[0].trim());
          final end = _parseTimestamp(parts[1].trim().split(' ')[0]);

          index++;
          final textBuffer = StringBuffer();
          while (index < lines.length && lines[index].trim().isNotEmpty) {
            if (textBuffer.isNotEmpty) textBuffer.write('\n');
            textBuffer.write(lines[index].trim());
            index++;
          }

          if (start != null && end != null && textBuffer.isNotEmpty) {
            cues.add(SubtitleCue(
              start: start,
              end: end,
              text: textBuffer.toString(),
            ));
          }
        }
      }
      index++;
    }

    return cues;
  }

  /// Parses timestamp string formatted as 00:01:23.456 or 00:01:23,456
  static Duration? _parseTimestamp(String s) {
    try {
      final clean = s.replaceAll(',', '.');
      final parts = clean.split(':');
      if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final secParts = parts[2].split('.');
        final seconds = int.parse(secParts[0]);
        final millis = secParts.length > 1 ? int.parse(secParts[1].padRight(3, '0').substring(0, 3)) : 0;
        return Duration(hours: hours, minutes: minutes, seconds: seconds, milliseconds: millis);
      } else if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final secParts = parts[1].split('.');
        final seconds = int.parse(secParts[0]);
        final millis = secParts.length > 1 ? int.parse(secParts[1].padRight(3, '0').substring(0, 3)) : 0;
        return Duration(minutes: minutes, seconds: seconds, milliseconds: millis);
      }
    } catch (_) {}
    return null;
  }

  /// Retrieves the active subtitle text at [position], adjusted by [offsetSeconds]
  static String? getActiveSubtitle(List<SubtitleCue> cues, Duration position, double offsetSeconds) {
    if (cues.isEmpty) return null;
    final adjustedMillis = position.inMilliseconds + (offsetSeconds * 1000).round();

    for (final cue in cues) {
      if (adjustedMillis >= cue.start.inMilliseconds && adjustedMillis <= cue.end.inMilliseconds) {
        return cue.text;
      }
    }
    return null;
  }
}
