import 'dart:async';
import 'dart:io';
import 'package:watcher/watcher.dart';
import 'package:path/path.dart' as p;
import '../database/app_database.dart' as db;
import '../utils/nfo_parser.dart';
import '../models/video.dart';
import 'package:flutter/foundation.dart';

class FileWatcherService {
  static final FileWatcherService _instance = FileWatcherService._internal();
  factory FileWatcherService() => _instance;
  FileWatcherService._internal();

  final Map<String, DirectoryWatcher> _watchers = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  Timer? _debounceTimer;
  final Set<String> _pendingFiles = {};

  static const _videoExtensions = ['.mp4', '.avi', '.mkv', '.mov', '.m4v', '.flv', '.wmv'];
  static const _debounceDuration = Duration(seconds: 2);

  bool get isWatching => _watchers.isNotEmpty;
  List<String> get watchedDirectories => _watchers.keys.toList();

  Future<void> startWatching(String directoryPath) async {
    if (_watchers.containsKey(directoryPath)) {
      debugPrint('Already watching: $directoryPath');
      return;
    }

    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        debugPrint('Directory does not exist: $directoryPath');
        return;
      }

      final watcher = DirectoryWatcher(directoryPath);
      _watchers[directoryPath] = watcher;

      final subscription = watcher.events.listen(
        (event) => _handleFileEvent(event),
        onError: (error) {
          debugPrint('Watcher error for $directoryPath: $error');
          stopWatching(directoryPath);
        },
      );

      _subscriptions[directoryPath] = subscription;
      debugPrint('Started watching: $directoryPath');
    } catch (e) {
      debugPrint('Failed to start watching $directoryPath: $e');
    }
  }

  Future<void> stopWatching(String directoryPath) async {
    await _subscriptions[directoryPath]?.cancel();
    _subscriptions.remove(directoryPath);
    _watchers.remove(directoryPath);
    debugPrint('Stopped watching: $directoryPath');
  }

  Future<void> stopAll() async {
    for (final path in _watchers.keys.toList()) {
      await stopWatching(path);
    }
    _debounceTimer?.cancel();
    _pendingFiles.clear();
  }

  void _handleFileEvent(WatchEvent event) {
    final filePath = event.path;
    
    // Only process video files and NFO files
    if (!_isVideoFile(filePath) && !_isNfoFile(filePath)) {
      return;
    }

    // Handle different event types
    switch (event.type) {
      case ChangeType.ADD:
      case ChangeType.MODIFY:
        _scheduleProcessing(filePath);
        break;
      case ChangeType.REMOVE:
        _handleFileRemoval(filePath);
        break;
    }
  }

  bool _isVideoFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return _videoExtensions.contains(ext);
  }

  bool _isNfoFile(String path) {
    return p.extension(path).toLowerCase() == '.nfo';
  }

  void _scheduleProcessing(String filePath) {
    _pendingFiles.add(filePath);
    
    // Debounce to avoid processing too frequently
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _processPendingFiles();
    });
  }

  Future<void> _processPendingFiles() async {
    final files = Set<String>.from(_pendingFiles);
    _pendingFiles.clear();

    for (final filePath in files) {
      try {
        if (_isVideoFile(filePath)) {
          await _processVideoFile(filePath);
        } else if (_isNfoFile(filePath)) {
          await _processNfoFile(filePath);
        }
      } catch (e) {
        debugPrint('Error processing file $filePath: $e');
      }
    }
  }

  Future<void> _processVideoFile(String videoPath) async {
    final file = File(videoPath);
    if (!await file.exists()) return;

    final database = db.AppDatabase.instance;
    
    // Check if video already exists
    final existing = await database.getVideoByPath(videoPath);
    if (existing != null) {
      debugPrint('Video already in database: $videoPath');
      return;
    }

    // Create basic video entry
    final stat = await file.stat();
    final video = Video(
      id: 0,
      path: videoPath,
      mtime: stat.modified.millisecondsSinceEpoch / 1000,
      title: p.basenameWithoutExtension(videoPath),
      genres: '',
      year: '',
      directors: '',
      plot: '',
      actors: '',
      duration: '',
      rating: 0.0,
      isSeries: false,
      posterPath: '',
      saga: '',
      sagaIndex: 0,
    );

    await database.insertVideo(video);
    debugPrint('Auto-added video: $videoPath');

    // Check for NFO file
    final nfoPath = '${p.withoutExtension(videoPath)}.nfo';
    if (await File(nfoPath).exists()) {
      await _processNfoFile(nfoPath);
    }
  }

  Future<void> _processNfoFile(String nfoPath) async {
    final videoPath = '${p.withoutExtension(nfoPath)}${_findVideoExtension(nfoPath)}';
    if (videoPath.isEmpty) return;

    final database = db.AppDatabase.instance;
    final existing = await database.getVideoByPath(videoPath);
    if (existing == null) return;

    try {
      final nfoData = await NfoParser.parseNfo(nfoPath);
      if (nfoData != null) {
        final updatedVideo = existing.copyWith(
          title: nfoData['title'] ?? existing.title,
          year: nfoData['year'] ?? existing.year,
          genres: nfoData['genre'] ?? existing.genres,
          plot: nfoData['plot'] ?? existing.plot,
          directors: nfoData['director'] ?? existing.directors,
          actors: nfoData['actor'] ?? existing.actors,
          rating: nfoData['rating'] ?? existing.rating,
        );
        
        await database.updateVideo(updatedVideo);
        debugPrint('Auto-updated video from NFO: $videoPath');
      }
    } catch (e) {
      debugPrint('Error parsing NFO $nfoPath: $e');
    }
  }

  String _findVideoExtension(String nfoPath) {
    final basePath = p.withoutExtension(nfoPath);
    for (final ext in _videoExtensions) {
      if (File('$basePath$ext').existsSync()) {
        return ext;
      }
    }
    return '';
  }

  Future<void> _handleFileRemoval(String filePath) async {
    if (!_isVideoFile(filePath)) return;

    final database = db.AppDatabase.instance;
    final existing = await database.getVideoByPath(filePath);
    if (existing != null) {
      await database.deleteVideo(existing.id!);
      debugPrint('Auto-removed video: $filePath');
    }
  }
}
