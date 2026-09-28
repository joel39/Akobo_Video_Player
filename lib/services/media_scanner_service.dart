import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/media_item.dart';

class MediaScannerResult {
  final List<MediaItem> videos;
  final List<MediaItem> audios;
  final List<MediaItem> all;

  const MediaScannerResult({
    required this.videos,
    required this.audios,
    required this.all,
  });
}

class MediaScannerService {
  static const List<String> videoExtensions = [
    '.mp4', '.mkv', '.webm', '.avi', '.mov', '.3gp', '.ts', '.m4v', '.wmv', '.flv'
  ];

  static const List<String> audioExtensions = [
    '.mp3', '.wav', '.flac', '.aac', '.m4a', '.ogg', '.opus', '.wma'
  ];

  /// Request media access permissions from Android
  static Future<bool> requestMediaPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final statuses = await [
        Permission.videos,
        Permission.audio,
        Permission.storage,
      ].request();

      final videoGranted = statuses[Permission.videos]?.isGranted ?? false;
      final audioGranted = statuses[Permission.audio]?.isGranted ?? false;
      final storageGranted = statuses[Permission.storage]?.isGranted ?? false;

      return videoGranted || audioGranted || storageGranted;
    } catch (e) {
      debugPrint('Permission request error: $e');
      return false;
    }
  }

  /// Scans phone storage for videos and audios, merging with built-in showcase 4K media
  static Future<MediaScannerResult> scanDeviceMedia() async {
    final List<MediaItem> localVideos = [];
    final List<MediaItem> localAudios = [];

    if (!kIsWeb && Platform.isAndroid) {
      // Step 1: Request media permissions before accessing storage
      await requestMediaPermissions();

      // Step 2: Directories to scan
      final Set<String> targetDirectories = {
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Music',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/DCIM/Camera',
        '/storage/emulated/0/Videos',
        '/storage/emulated/0/Podcasts',
        '/storage/emulated/0/Audiobooks',
        '/storage/emulated/0/Recordings',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/WhatsApp/Media',
        '/storage/emulated/0/Telegram',
        '/sdcard/Movies',
        '/sdcard/Download',
        '/sdcard/Music',
        '/sdcard/DCIM',
        '/sdcard/Videos',
      };

      // Also dynamically discover any custom folders under /storage/emulated/0
      try {
        final root = Directory('/storage/emulated/0');
        if (await root.exists()) {
          await for (final entity in root.list(followLinks: false)) {
            if (entity is Directory) {
              final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? '';
              // Avoid hidden dirs and internal Android sandbox
              if (!name.startsWith('.') && name != 'Android') {
                targetDirectories.add(entity.path);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Root directory listing notice: $e');
      }

      final Set<String> seenPaths = {};

      for (final dirPath in targetDirectories) {
        try {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            await for (final entity in dir.list(recursive: true, followLinks: false)) {
              if (entity is File) {
                final path = entity.path;
                if (seenPaths.contains(path)) continue;
                seenPaths.add(path);

                final pathLower = path.toLowerCase();
                final ext = pathLower.contains('.') ? pathLower.substring(pathLower.lastIndexOf('.')) : '';
                final fileName = entity.uri.pathSegments.isNotEmpty
                    ? entity.uri.pathSegments.last
                    : path;

                // Ignore tiny hidden cache files
                if (fileName.startsWith('.')) continue;

                // Format File Size & Date
                String sizeLabel = '';
                int fileBytes = 0;
                DateTime? fileModified;
                try {
                  final stat = await entity.stat();
                  fileBytes = stat.size;
                  fileModified = stat.modified;
                  if (fileBytes < 1024 * 10) continue; // Skip files < 10KB
                  final mb = fileBytes / (1024 * 1024);
                  sizeLabel = mb > 1024
                      ? '${(mb / 1024).toStringAsFixed(1)} GB'
                      : '${mb.toStringAsFixed(1)} MB';
                } catch (_) {}

                final parentDir = entity.parent;
                final fSegments = parentDir.uri.pathSegments.where((s) => s.isNotEmpty).toList();
                final folderName = fSegments.isNotEmpty ? fSegments.last : 'Storage';
                final folderPath = parentDir.path;

                if (videoExtensions.contains(ext)) {
                  String res = 'HD Video';
                  if (pathLower.contains('4k') || pathLower.contains('2160') || pathLower.contains('uhd')) {
                    res = '4K UHD';
                  } else if (pathLower.contains('1080') || pathLower.contains('fhd')) {
                    res = '1080p FHD';
                  } else if (pathLower.contains('720')) {
                    res = '720p HD';
                  }

                  localVideos.add(MediaItem(
                    id: 'local-vid-${path.hashCode}',
                    title: _cleanTitle(fileName),
                    subtitle: sizeLabel.isNotEmpty ? sizeLabel : 'Local Device Video',
                    url: path,
                    isLocal: true,
                    resolution: res,
                    folderName: folderName,
                    folderPath: folderPath,
                    dateAdded: fileModified,
                    sizeBytes: fileBytes,
                  ));
                } else if (audioExtensions.contains(ext)) {
                  String res = 'Audio Track';
                  if (ext == '.flac' || ext == '.wav') {
                    res = 'Lossless HD';
                  } else if (ext == '.mp3') {
                    res = 'MP3 Studio';
                  } else if (ext == '.m4a' || ext == '.aac') {
                    res = 'AAC Digital';
                  }

                  localAudios.add(MediaItem(
                    id: 'local-aud-${path.hashCode}',
                    title: _cleanTitle(fileName),
                    subtitle: sizeLabel.isNotEmpty ? sizeLabel : 'Local Audio Track',
                    url: path,
                    isLocal: true,
                    resolution: res,
                    folderName: folderName,
                    folderPath: folderPath,
                    dateAdded: fileModified,
                    sizeBytes: fileBytes,
                  ));
                }

              }
            }
          }
        } catch (e) {
          debugPrint('Directory scan skip for $dirPath: $e');
        }
      }
    }

    // Showcase demo items
    final defaultStreams = MediaItem.defaultLibrary;
    final List<MediaItem> allVideos = [...localVideos, ...defaultStreams];
    final List<MediaItem> allAudios = [...localAudios];

    // If device had no audio files yet, add high-def synthesized audio streams
    if (allAudios.isEmpty) {
      allAudios.addAll([
        const MediaItem(
          id: 'demo-audio-synth',
          title: 'Cyber Synthwave Matrix 8K',
          subtitle: 'Acoustic Soundstage Demonstration',
          url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          resolution: '3D Spatial Audio',
        ),
        const MediaItem(
          id: 'demo-audio-sub',
          title: 'Quantum Bass Calibration Stream',
          subtitle: 'Sub-bass 32Hz Frequency Test',
          url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
          resolution: 'FLAC Lossless',
        ),
      ]);
    }

    final allItems = [...allVideos, ...allAudios];

    return MediaScannerResult(
      videos: allVideos,
      audios: allAudios,
      all: allItems,
    );
  }

  static String _cleanTitle(String filename) {
    var title = filename;
    if (title.contains('.')) {
      title = title.substring(0, title.lastIndexOf('.'));
    }
    return title.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  /// Groups media items by their storage folder name
  static List<MediaFolder> groupMediaIntoFolders(List<MediaItem> allItems) {
    final Map<String, List<MediaItem>> folderMap = {};
    for (final item in allItems) {
      final folderKey = item.folderName.isNotEmpty ? item.folderName : 'Internal Storage';
      folderMap.putIfAbsent(folderKey, () => []).add(item);
    }
    final folders = folderMap.entries.map((e) {
      final firstPath = e.value.first.folderPath;
      return MediaFolder(
        name: e.key,
        path: firstPath.isNotEmpty ? firstPath : e.key,
        items: e.value,
      );
    }).toList();
    // Sort alphabetically
    folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return folders;
  }
}
