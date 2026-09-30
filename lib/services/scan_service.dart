import 'dart:io';
import 'package:path/path.dart' as p;
import '../repositories/video_repository.dart';
import '../models/video.dart' as model;
import '../utils/nfo_parser.dart';
import '../utils/video_extensions.dart';
import 'media_asset_service.dart';
import 'settings_service.dart';
import './logger_service.dart';

/// Tipo di aggiornamento emesso durante la scansione.
enum ScanStatusType {
  /// La cartella scelta non esiste.
  folderMissing,

  /// Avvio della scansione.
  started,

  /// Numero di elementi elaborati (aggiornamento interno, non mostrato).
  countUpdate,

  /// Avanzamento della scansione.
  progress,

  /// La scansione si è interrotta per un errore.
  failed,

  /// Scansione conclusa.
  completed,
}

/// Stato della scansione: i messaggi sono risolti dalla UI con i testi
/// localizzati, il servizio non contiene stringhe visibili.
class ScanStatus {
  const ScanStatus({
    required this.type,
    required this.count,
    this.currentItem,
    this.path,
    this.error,
  });

  const ScanStatus.folderMissing()
    : type = ScanStatusType.folderMissing,
      count = 0,
      currentItem = null,
      path = null,
      error = null;

  const ScanStatus.started(this.path)
    : type = ScanStatusType.started,
      count = 0,
      currentItem = null,
      error = null;

  const ScanStatus.countUpdate(this.count, {this.currentItem})
    : type = ScanStatusType.countUpdate,
      path = null,
      error = null;

  const ScanStatus.progress(this.count, {this.currentItem})
    : type = ScanStatusType.progress,
      path = null,
      error = null;

  const ScanStatus.failed(this.count, this.error)
    : type = ScanStatusType.failed,
      currentItem = null,
      path = null;

  const ScanStatus.completed(this.count)
    : type = ScanStatusType.completed,
      currentItem = null,
      path = null,
      error = null;

  final ScanStatusType type;
  final int count;
  final String? currentItem;

  /// Cartella coinvolta nell'evento (avvio o cartella mancante).
  final String? path;

  /// Dettaglio dell'errore, se presente.
  final Object? error;
}

class ScanService {
  /// Il [repository] è opzionale: in produzione si usa il repository globale,
  /// nei test se ne può iniettare uno finto.
  ScanService([VideoRepository? repository])
    : _repository = repository ?? videoRepository;

  static final ScanService instance = ScanService();

  final VideoRepository _repository;
  final _mediaAssetService = MediaAssetService();

  final List<String> seriesKeywords = [
    'serie',
    'series',
    'seriale',
    'tv show',
    'tvshow',
  ];

  Stream<ScanStatus> scanFolder(String folderPath) async* {
    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      yield ScanStatus.folderMissing();
      return;
    }

    yield ScanStatus.started(folderPath);

    int count = 0;

    try {
      // Carichiamo la lista dei percorsi che sono falliti durante la rinomina
      final failedPaths = await _repository.getAllFailedRenamePaths();

      await for (final status in _scanRecursive(dir, failedPaths)) {
        if (status.type == ScanStatusType.countUpdate) {
          count += status.count;
          if (count % 5 == 0) {
            yield ScanStatus.progress(count, currentItem: status.currentItem);
          }
        } else {
          yield status;
        }
      }
    } on Exception catch (e) {
      LoggerService().error('Errore durante la scansione', e);
      yield ScanStatus.failed(count, e);
      return;
    }

    yield ScanStatus.completed(count);
  }

  Stream<ScanStatus> _scanRecursive(
    Directory dir,
    Set<String> failedPaths,
  ) async* {
    final settings = SettingsService();
    final String fullPath = dir.path;
    final String dirName = p.basename(fullPath).toLowerCase();

    // Check if we should skip this folder because it's a backup folder
    if (settings.excludeConvertedBackupFromScan) {
      bool isBackupFolder = false;

      // 1. Check custom backup path
      if (settings.videoBackupPath.isNotEmpty &&
          p.canonicalize(fullPath) ==
              p.canonicalize(settings.videoBackupPath)) {
        isBackupFolder = true;
      }

      // 2. Check default names (to be extra safe if user hasn't set one yet but files exist)
      if (dirName == 'converted_backups' || dirName == 'oldavi') {
        isBackupFolder = true;
      }

      if (isBackupFolder) {
        LoggerService().debug(
          'SKIP [ScanService]: Backup folder ignored: $fullPath',
        );
        return;
      }
    }

    // 1. Explicit Series Check: tvshow.nfo detection
    // If a folder has tvshow.nfo, it IS a series.
    final tvshowNfo = File(p.join(dir.path, 'tvshow.nfo'));
    if (await tvshowNfo.exists()) {
      try {
        final added = await _processSeries(dir, failedPaths);
        yield ScanStatus.countUpdate(
          added ? 1 : 0,
          currentItem: p.basename(dir.path),
        );
      } on Exception catch (e) {
        LoggerService().debug('Error processing series ${dir.path}: $e');
      }
      return; // Stop recursion, we handled this folder as a unit
    }

    // 2. Series Container Check: Folder name contains keywords
    // If a folder is named "Series", "TV Shows", etc., its subfolders are the series.
    bool isSeriesContainer = false;
    for (final kw in seriesKeywords) {
      if (dirName.contains(kw)) {
        isSeriesContainer = true;
        break;
      }
    }

    if (isSeriesContainer) {
      try {
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is Directory) {
            // Each subdirectory is treated as a Series
            final added = await _processSeries(entity, failedPaths);
            yield ScanStatus.countUpdate(
              added ? 1 : 0,
              currentItem: p.basename(entity.path),
            );
          }
        }
      } on Exception catch (e) {
        LoggerService().debug(
          'Error processing series container ${dir.path}: $e',
        );
      }
      return; // Stop recursion, we've handled the contents
    }

    // 3. Normal Recursive Scan
    try {
      final entities = await dir.list(followLinks: false).toList();

      // Process in batches of 5 to avoid overwhelming file handles/network
      const batchSize = 5;
      for (var i = 0; i < entities.length; i += batchSize) {
        final batch = entities.sublist(
          i,
          i + batchSize > entities.length ? entities.length : i + batchSize,
        );

        final tasks = batch.map((entity) async {
          final name = p.basename(entity.path);
          if (name.startsWith('.')) return 0;

          if (entity is Directory) {
            int subCount = 0;
            await for (final status in _scanRecursive(entity, failedPaths)) {
              if (status.type == ScanStatusType.countUpdate) {
                subCount += status.count;
              }
            }
            return subCount;
          } else if (entity is File) {
            final ext = p.extension(entity.path).toLowerCase();
            if (VideoExtensions.supported.contains(ext)) {
              try {
                final added = await _processVideo(entity, failedPaths);
                if (added) {
                  // Yield an intermediate status update to show the current file in UI
                  return 1;
                }
              } on Exception catch (e) {
                LoggerService().debug(
                  'Error processing video ${entity.path}: $e',
                );
              }
            }
          }
          return 0;
        });

        final results = await Future.wait(tasks);
        final batchAddedCount = results.fold<int>(0, (sum, val) => sum + val);
        if (batchAddedCount > 0) {
          // Send the name of the last file in the batch or a generic update
          yield ScanStatus.countUpdate(
            batchAddedCount,
            currentItem: p.basename(batch.last.path),
          );
        }
      }
    } on Exception catch (e) {
      LoggerService().debug('Error listing directory ${dir.path}: $e');
    }
  }

  Future<bool> _processSeries(
    Directory seriesDir,
    Set<String> failedPaths,
  ) async {
    final path = seriesDir.path;

    // 1. Check if in blacklisted failedPaths
    if (failedPaths.contains(path)) {
      LoggerService().debug(
        'SKIP [ScanService]: Series in Failed Renames: ${p.basename(path)}',
      );
      return false;
    }

    // 2. Check if already has Poster and Rating
    final existing = await _repository.getVideoByPath(path);
    if (existing != null &&
        existing.posterPath.isNotEmpty &&
        existing.rating > 0.0) {
      LoggerService().debug(
        'SKIP [ScanService]: Series already has metadata: ${p.basename(path)}',
      );
      return false;
    }

    final stat = await seriesDir.stat();
    final mtime = stat.modified.millisecondsSinceEpoch / 1000.0;

    final String nfoPath = p.join(path, 'tvshow.nfo');

    final Map<String, dynamic>? metadata = await NfoParser.parseNfo(nfoPath);

    final rawTitle = metadata?['title'] ?? p.basename(path);
    final year = metadata?['year'] ?? '';

    String formattedTitle = rawTitle;
    if (year.isNotEmpty) {
      final yearSuffix = '($year)';
      if (!rawTitle.contains(yearSuffix)) {
        formattedTitle = '$rawTitle $yearSuffix';
      }
    }

    final processedDirects = await _processThumbnails(
      metadata?['directors'] ?? '',
      metadata?['directorThumbs'] ?? '',
      seriesDir.path,
    );
    final processedActors = await _processThumbnails(
      metadata?['actors'] ?? '',
      metadata?['actorThumbs'] ?? '',
      seriesDir.path,
    );

    final video = model.Video(
      path: path,
      mtime: mtime,
      title: formattedTitle,
      genres: metadata?['genres'] ?? '',
      year: year,
      directors: processedDirects.names,
      directorThumbs: processedDirects.thumbs,
      plot: metadata?['plot'] ?? '',
      actors: processedActors.names,
      actorThumbs: processedActors.thumbs,
      duration: metadata?['duration'] ?? '',
      rating: metadata?['rating'] ?? 0.0,
      isSeries: true,
      posterPath: metadata?['poster'] ?? '',
      saga: metadata?['saga'] ?? '',
      dateAdded: stat.modified,
    );

    await _repository.insertVideo(video);
    return true;
  }

  Future<bool> _processVideo(File videoFile, Set<String> failedPaths) async {
    final path = videoFile.path;

    // 1. Check if in blacklisted failedPaths
    if (failedPaths.contains(path)) {
      LoggerService().debug(
        'SKIP [ScanService]: Video in Failed Renames: ${p.basename(path)}',
      );
      return false;
    }

    // 2. Check if already has Poster and Rating
    final existing = await _repository.getVideoByPath(path);
    if (existing != null &&
        existing.posterPath.isNotEmpty &&
        existing.rating > 0.0) {
      LoggerService().debug(
        'SKIP [ScanService]: Video already has metadata: ${p.basename(path)}',
      );
      return false;
    }

    final stat = await videoFile.stat();
    final mtime =
        stat.modified.millisecondsSinceEpoch / 1000.0; // Seconds as double

    // Check for NFO (Priority: video_filename.nfo > movie.nfo)
    String nfoPath = p.setExtension(path, '.nfo');
    File nfoFile = File(nfoPath);
    bool nfoExists = await nfoFile.exists();

    if (!nfoExists) {
      final movieNfoPath = p.join(p.dirname(path), 'movie.nfo');
      final movieNfoFile = File(movieNfoPath);
      if (await movieNfoFile.exists()) {
        nfoPath = movieNfoPath;
        nfoFile = movieNfoFile;
        nfoExists = true;
      }
    }

    LoggerService().debug(
      'DEBUG [ScanService]: model.Video: ${p.basename(path)}, NFO found: $nfoExists at $nfoPath',
    );

    final Map<String, dynamic>? metadata = await NfoParser.parseNfo(nfoPath);

    // Create model.Video object
    // If metadata is null, use minimal info (filename as title)
    final rawTitle = metadata?['title'] ?? p.basenameWithoutExtension(path);
    final year = metadata?['year'] ?? '';

    String formattedTitle = rawTitle;
    if (year.isNotEmpty) {
      final yearSuffix = '($year)';
      if (!rawTitle.contains(yearSuffix)) {
        formattedTitle = '$rawTitle $yearSuffix';
      }
    }

    final processedDirects = await _processThumbnails(
      metadata?['directors'] ?? '',
      metadata?['directorThumbs'] ?? '',
      p.dirname(path),
    );
    final processedActors = await _processThumbnails(
      metadata?['actors'] ?? '',
      metadata?['actorThumbs'] ?? '',
      p.dirname(path),
    );

    final video = model.Video(
      path: path,
      mtime: mtime,
      title: formattedTitle,
      genres: metadata?['genres'] ?? '',
      year: year,
      directors: processedDirects.names,
      directorThumbs: processedDirects.thumbs,
      plot: metadata?['plot'] ?? '',
      actors: processedActors.names,
      actorThumbs: processedActors.thumbs,
      duration: metadata?['duration'] ?? '',
      rating: metadata?['rating'] ?? 0.0,
      posterPath: metadata?['poster'] ?? '',
      saga: metadata?['saga'] ?? '',
      dateAdded: stat.modified,
    );

    // Insert into DB (update if exists)
    await _repository.insertVideo(video);
    return true;
  }

  Future<({String names, String thumbs})> _processThumbnails(
    String namesStr,
    String thumbsStr,
    String baseDir,
  ) async {
    if (namesStr.isEmpty) return (names: '', thumbs: '');

    final names = namesStr.split(',').map((e) => e.trim()).toList();
    final thumbs = thumbsStr.split('|').map((e) => e.trim()).toList();

    // Parallelize thumbnail processing
    final downloadTasks = <Future<String>>[];
    for (int i = 0; i < names.length; i++) {
      final name = names[i];
      final thumb = i < thumbs.length ? thumbs[i] : '';

      if (thumb.isNotEmpty && thumb.startsWith('http')) {
        downloadTasks.add(
          _mediaAssetService.downloadThumbnail(thumb, baseDir, name),
        );
      } else {
        downloadTasks.add(Future.value(thumb));
      }
    }

    final newThumbs = await Future.wait(downloadTasks);
    return (names: namesStr, thumbs: newThumbs.join('|'));
  }
}
