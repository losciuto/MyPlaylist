import 'dart:async';
import 'dart:io';
import 'package:watcher/watcher.dart';
import 'package:path/path.dart' as p;
import '../repositories/video_repository.dart';
import '../utils/nfo_parser.dart';
import '../models/video.dart';
import '../utils/video_extensions.dart';
import './logger_service.dart';

class FileWatcherService {
  factory FileWatcherService([VideoRepository? repository]) {
    if (repository != null) _repository = repository;
    return _instance;
  }
  FileWatcherService._internal();
  static final FileWatcherService _instance = FileWatcherService._internal();

  static VideoRepository _repository = videoRepository;

  final Map<String, DirectoryWatcher> _watchers = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  Timer? _debounceTimer;
  final Set<String> _pendingFiles = {};

  static const _debounceDuration = Duration(seconds: 2);

  bool get isWatching => _watchers.isNotEmpty;
  List<String> get watchedDirectories => _watchers.keys.toList();

  Future<void> startWatching(String directoryPath) async {
    if (_watchers.containsKey(directoryPath)) {
      LoggerService().debug('Already watching: $directoryPath');
      return;
    }

    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        LoggerService().debug('Directory does not exist: $directoryPath');
        return;
      }

      final watcher = DirectoryWatcher(directoryPath);
      _watchers[directoryPath] = watcher;

      // La subscription è conservata in _subscriptions e cancellata
      // da stopWatching/stopAll: il lint non può verificarlo.
      // ignore: cancel_subscriptions
      final subscription = watcher.events.listen(
        (event) => _handleFileEvent(event),
        onError: (error) {
          LoggerService().error('Watcher error for $directoryPath', error);
          stopWatching(directoryPath);
        },
      );

      _subscriptions[directoryPath] = subscription;
      LoggerService().debug('Started watching: $directoryPath');
    } on Object catch (e) {
      await LoggerService().error('Failed to start watching $directoryPath', e);
    }
  }

  Future<void> stopWatching(String directoryPath) async {
    await _subscriptions[directoryPath]?.cancel();
    _subscriptions.remove(directoryPath);
    _watchers.remove(directoryPath);
    LoggerService().debug('Stopped watching: $directoryPath');
  }

  Future<void> stopAll() async {
    for (final path in _watchers.keys.toList()) {
      await stopWatching(path);
    }
    _debounceTimer?.cancel();
    _debounceTimer = null;
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
    return VideoExtensions.supported.contains(ext);
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
      } on Object catch (e) {
        await LoggerService().error('Error processing file $filePath', e);
      }
    }
  }

  Future<void> _processVideoFile(String videoPath) async {
    final file = File(videoPath);
    if (!await file.exists()) return;

    final database = _repository;

    // Check if video already exists
    final existing = await database.getVideoByPath(videoPath);
    if (existing != null) {
      LoggerService().debug('Video already in database: $videoPath');
      return;
    }

    // Create basic video entry
    final stat = await file.stat();
    final video = Video(
      id: 0,
      path: videoPath,
      mtime: stat.modified.millisecondsSinceEpoch / 1000,
      title: p.basenameWithoutExtension(videoPath),
      dateAdded: DateTime.now(),
    );

    await database.insertVideo(video);
    LoggerService().debug('Auto-added video: $videoPath');

    // Check for NFO file
    final nfoPath = '${p.withoutExtension(videoPath)}.nfo';
    if (await File(nfoPath).exists()) {
      await _processNfoFile(nfoPath);
    }
  }

  Future<void> _processNfoFile(String nfoPath) async {
    final videoPath =
        '${p.withoutExtension(nfoPath)}${_findVideoExtension(nfoPath)}';
    if (videoPath.isEmpty) return;

    final database = _repository;
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
        LoggerService().debug('Auto-updated video from NFO: $videoPath');
      }
    } on Object catch (e) {
      await LoggerService().error('Error parsing NFO $nfoPath', e);
    }
  }

  String _findVideoExtension(String nfoPath) {
    final basePath = p.withoutExtension(nfoPath);
    for (final ext in VideoExtensions.supported) {
      if (File('$basePath$ext').existsSync()) {
        return ext;
      }
    }
    return '';
  }

  Future<void> _handleFileRemoval(String filePath) async {
    if (!_isVideoFile(filePath)) return;

    final database = _repository;
    final existing = await database.getVideoByPath(filePath);
    if (existing != null) {
      await database.deleteVideo(existing.id!);
      LoggerService().debug('Auto-removed video: $filePath');
    }
  }
}
