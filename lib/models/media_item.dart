/// Data model representing a playable video or audio item
class MediaItem {
  final String id;
  final String title;
  final String subtitle;
  final String url;
  final bool isLocal;
  final String resolution;
  final Duration? duration;
  final String? subtitleUrl;
  final String folderName;
  final String folderPath;
  final String? coverUrl;
  final DateTime? dateAdded;
  final int? sizeBytes;

  const MediaItem({
    required this.id,
    required this.title,
    this.subtitle = 'Akobo Master Stream',
    required this.url,
    this.isLocal = false,
    this.resolution = '4K UHD',
    this.duration,
    this.subtitleUrl,
    this.folderName = 'Akobo Cloud',
    this.folderPath = '',
    this.coverUrl,
    this.dateAdded,
    this.sizeBytes,
  });

  MediaItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? url,
    bool? isLocal,
    String? resolution,
    Duration? duration,
    String? subtitleUrl,
    String? folderName,
    String? folderPath,
    String? coverUrl,
    DateTime? dateAdded,
    int? sizeBytes,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      url: url ?? this.url,
      isLocal: isLocal ?? this.isLocal,
      resolution: resolution ?? this.resolution,
      duration: duration ?? this.duration,
      subtitleUrl: subtitleUrl ?? this.subtitleUrl,
      folderName: folderName ?? this.folderName,
      folderPath: folderPath ?? this.folderPath,
      coverUrl: coverUrl ?? this.coverUrl,
      dateAdded: dateAdded ?? this.dateAdded,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }


  bool get isAudio {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.opus') ||
        lower.endsWith('.wma') ||
        resolution.toLowerCase().contains('audio');
  }

  /// Built-in 4K showcase streams for instant high-def testing
  static List<MediaItem> get defaultLibrary => [
    const MediaItem(
      id: 'demo-4k-tears',
      title: 'Tears of Steel (Sci-Fi 4K)',
      subtitle: 'Blender Foundation UHD Studio',
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
      resolution: '4K UHD 60FPS',
      coverUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=600&auto=format&fit=crop',
    ),
    const MediaItem(
      id: 'demo-4k-sintel',
      title: 'Sintel Cyber Matrix 4K',
      subtitle: 'Quantum Animation Stream',
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      resolution: '4K UHD HDR',
      coverUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=600&auto=format&fit=crop',
    ),
    const MediaItem(
      id: 'demo-bunny-uhd',
      title: 'Big Buck Bunny Cinema',
      subtitle: 'Color Grading Calibration Stream',
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      resolution: '1080p FHD',
      coverUrl: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=600&auto=format&fit=crop',
    ),
    const MediaItem(
      id: 'demo-elephants',
      title: 'Elephants Dream High-Def',
      subtitle: 'Synthesized 3D Sound Demonstration',
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      resolution: '1080p Cinema',
      coverUrl: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?q=80&w=600&auto=format&fit=crop',
    ),
  ];
}

/// Data model representing a storage folder containing media items
class MediaFolder {
  final String name;
  final String path;
  final List<MediaItem> items;

  const MediaFolder({
    required this.name,
    required this.path,
    required this.items,
  });

  int get videoCount => items.where((i) => !i.resolution.contains('Audio') && !i.resolution.contains('FLAC') && !i.resolution.contains('MP3') && !i.resolution.contains('AAC')).length;
  int get audioCount => items.length - videoCount;
}
