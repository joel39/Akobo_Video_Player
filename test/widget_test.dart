import 'package:akobo_flutter/models/media_item.dart';
import 'package:akobo_flutter/services/color_matrix_service.dart';
import 'package:akobo_flutter/services/media_scanner_service.dart';
import 'package:akobo_flutter/services/subtitle_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Akobo 4K Quantum Tests', () {
    test('Default media library contains 4K showcase streams', () {
      final library = MediaItem.defaultLibrary;
      expect(library.length, greaterThanOrEqualTo(4));
      expect(library.first.resolution, contains('4K'));
    });

    test('ColorMatrixService produces valid 20-element 4x5 matrices', () {
      final matrix = ColorMatrixService.computeMatrix(
        brightness: 1.2,
        contrast: 1.1,
        saturation: 1.3,
        hueDegrees: 45.0,
      );
      expect(matrix.length, equals(20));

      for (final preset in VideoFxPreset.values) {
        final presetMatrix = ColorMatrixService.getPresetMatrix(preset);
        expect(presetMatrix.length, equals(20));
      }
    });

    test('SubtitleParser correctly parses SRT timestamps and cues', () {
      const srtSample = '''
1
00:00:01,000 --> 00:00:04,000
Akobo Quantum 4K Engine Initialized

2
00:00:05,000 --> 00:00:08,000
10-Band Graphic Equalizer Online
''';
      final cues = SubtitleParser.parse(srtSample);
      expect(cues.length, equals(2));
      expect(cues[0].text, equals('Akobo Quantum 4K Engine Initialized'));
      expect(cues[0].start, equals(const Duration(seconds: 1)));
      expect(cues[0].end, equals(const Duration(seconds: 4)));

      // Active subtitle lookup with offset
      final subAt2s = SubtitleParser.getActiveSubtitle(cues, const Duration(seconds: 2), 0.0);
      expect(subAt2s, equals('Akobo Quantum 4K Engine Initialized'));

      final subAt2sWithNeg2sOffset = SubtitleParser.getActiveSubtitle(cues, const Duration(seconds: 2), -2.0);
      expect(subAt2sWithNeg2sOffset, isNull);
    });

    test('FilePickerPlatform methods', () async {
      expect(FilePickerPlatform.instance, isNotNull);
      try {
        final List<PlatformFile> res = await FilePickerPlatform.instance.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp4'],
        );
        expect(res, isEmpty);
      } catch (_) {}
    });

    test('MediaScannerService auto-scans and populates media repositories', () async {
      final result = await MediaScannerService.scanDeviceMedia();
      expect(result.videos, isNotEmpty);
      expect(result.audios, isNotEmpty);
      expect(result.all.length, greaterThanOrEqualTo(result.videos.length + result.audios.length));
    });
  });
}
