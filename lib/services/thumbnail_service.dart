import 'package:flutter/services.dart';

class ThumbnailService {
  static const MethodChannel _channel = MethodChannel('com.akobo.akobo_flutter/video_thumbnail');
  static final Map<String, Uint8List?> _memoryCache = {};
  static final Map<String, Future<Uint8List?>> _inFlight = {};

  /// Retrieves a video frame thumbnail as compressed JPEG bytes
  static Future<Uint8List?> getThumbnail(String path) async {
    if (path.isEmpty) return null;

    if (_memoryCache.containsKey(path)) {
      return _memoryCache[path];
    }

    if (_inFlight.containsKey(path)) {
      return _inFlight[path];
    }

    final future = _fetchThumbnail(path);
    _inFlight[path] = future;
    try {
      final result = await future;
      _memoryCache[path] = result;
      return result;
    } finally {
      _inFlight.remove(path);
    }
  }

  static Future<Uint8List?> _fetchThumbnail(String path) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('getVideoThumbnail', {'path': path});
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Clears in-memory cache if memory is constrained
  static void clearCache() {
    _memoryCache.clear();
  }
}
