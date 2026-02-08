import 'dart:io';
import 'package:path/path.dart' as p;
import '../database/app_database.dart' as db;
import '../models/video.dart' as model;
import '../utils/nfo_parser.dart';

class ScanStatus {
  final String message;
  final int count;

  ScanStatus(this.message, this.count);
}

class ScanService {
  static final ScanService instance = ScanService._();
  ScanService._();

  static const List<String> videoExtensions = [
    '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.mpg', 
    '.mpeg', '.m2v', '.ts', '.mts', '.m2ts', '.vob', '.ogv', '.ogg', '.qt', 
    '.yuv', '.rm', '.rmvb', '.asf', '.amv', '.divx', '.3gp', '.3g2', '.mxf'
  ];

  final List<String> seriesKeywords = [
    'serie', 'series', 'seriale', 'tv show', 'tvshow'
  ];

  Stream<ScanStatus> scanFolder(String folderPath) async* {
    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      yield ScanStatus('Folder does not exist.', 0);
      return;
    }

    yield ScanStatus('Starting scan in $folderPath...', 0);

    int count = 0;
    
    try {
      await for (final status in _scanRecursive(dir)) {
        if (status.message == 'COUNT_UPDATE') {
          count += status.count;
          if (count % 5 == 0) {
            yield ScanStatus('Processed $count items...', count);
          }
        } else {
          yield status;
        }
      }
    } catch (e) {
      yield ScanStatus('Error scanning: $e', count);
      return;
    }

    yield ScanStatus('Scan complete. Total: $count', count);
  }

  Stream<ScanStatus> _scanRecursive(Directory dir) async* {
    final dirName = p.basename(dir.path).toLowerCase();

    // 1. Explicit Series Check: tvshow.nfo detection
    // If a folder has tvshow.nfo, it IS a series.
    final tvshowNfo = File(p.join(dir.path, 'tvshow.nfo'));
    if (await tvshowNfo.exists()) {
      try {
        await _processSeries(dir);
        yield ScanStatus('COUNT_UPDATE', 1);
      } catch (e) {
        print('Error processing series ${dir.path}: $e');
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
        await for (final entity in dir.list(recursive: false, followLinks: false)) {
          if (entity is Directory) {
            // Each subdirectory is treated as a Series
            await _processSeries(entity);
            yield ScanStatus('COUNT_UPDATE', 1);
          }
        }
      } catch (e) {
        print('Error processing series container ${dir.path}: $e');
      }
      return; // Stop recursion, we've handled the contents
    }

    // 3. Normal Recursive Scan
    int localCount = 0;
    try {
      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is Directory) {
          await for (final status in _scanRecursive(entity)) {
            if (status.message == 'COUNT_UPDATE') {
              localCount += status.count;
              yield ScanStatus('COUNT_UPDATE', status.count);
            } else {
              yield status;
            }
          }
        } else if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (videoExtensions.contains(ext)) {
            try {
              await _processVideo(entity);
              localCount++;
              yield ScanStatus('COUNT_UPDATE', 1);
            } catch (e) {}
          }
        }
      }
    } catch (e) {}
  }

  Future<void> _processSeries(Directory seriesDir) async {
    final path = seriesDir.path;
    final stat = await seriesDir.stat();
    final mtime = stat.modified.millisecondsSinceEpoch / 1000.0;

    String nfoPath = p.join(path, 'tvshow.nfo');
    File nfoFile = File(nfoPath);
    bool nfoExists = await nfoFile.exists();

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

    final video = model.Video(
      path: path,
      mtime: mtime,
      title: formattedTitle,
      genres: metadata?['genres'] ?? '',
      year: year,
      directors: metadata?['directors'] ?? '',
      directorThumbs: metadata?['directorThumbs'] ?? '',
      plot: metadata?['plot'] ?? '',
      actors: metadata?['actors'] ?? '',
      actorThumbs: metadata?['actorThumbs'] ?? '',
      duration: metadata?['duration'] ?? '',
      rating: metadata?['rating'] ?? 0.0,
      isSeries: true,
      posterPath: metadata?['poster'] ?? '',
      saga: metadata?['saga'] ?? '',
    );

    await db.AppDatabase.instance.insertVideo(video);
  }

  Future<void> _processVideo(File videoFile) async {
    final path = videoFile.path;
    final stat = await videoFile.stat();
    final mtime = stat.modified.millisecondsSinceEpoch / 1000.0; // Seconds as double

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

    print('DEBUG [ScanService]: model.Video: ${p.basename(path)}, NFO found: $nfoExists at $nfoPath');
    
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
    
    final video = model.Video(
      path: path,
      mtime: mtime,
      title: formattedTitle,
      genres: metadata?['genres'] ?? '',
      year: year,
      directors: metadata?['directors'] ?? '',
      directorThumbs: metadata?['directorThumbs'] ?? '',
      plot: metadata?['plot'] ?? '',
      actors: metadata?['actors'] ?? '',
      actorThumbs: metadata?['actorThumbs'] ?? '',
      duration: metadata?['duration'] ?? '',
      rating: metadata?['rating'] ?? 0.0,
      posterPath: metadata?['poster'] ?? '',
      saga: metadata?['saga'] ?? '',
    );

    // Insert into DB (update if exists)
    await db.AppDatabase.instance.insertVideo(video);
  }
}
