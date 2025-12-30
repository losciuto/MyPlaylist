import 'dart:io';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../models/video.dart';
import '../utils/nfo_parser.dart';

class ScanStatus {
  final String message;
  final int count;

  ScanStatus(this.message, this.count);
}

class ScanService {
  static final ScanService instance = ScanService._();
  ScanService._();

  final List<String> videoExtensions = [
    '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.mpg', 
    '.mpeg', '.m2v', '.ts', '.mts', '.m2ts', '.vob', '.ogv', '.ogg', '.qt', 
    '.yuv', '.rm', '.rmvb', '.asf', '.amv', '.divx', '.3gp', '.3g2', '.mxf'
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
      // Use efficient recursive listing
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (videoExtensions.contains(ext)) {
            // yield ScanStatus('Found: ${p.basename(entity.path)}', count);
            try {
              await _processVideo(entity);
              count++;
              if (count % 5 == 0) {
                 yield ScanStatus('Processed $count videos...', count);
              }
            } catch (e) {
              // Log error but continue
              // print('Error processing ${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      yield ScanStatus('Error scanning: $e', count);
      return;
    }

    yield ScanStatus('Scan complete. Total: $count', count);
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

    print('DEBUG [ScanService]: Video: ${p.basename(path)}, NFO found: $nfoExists at $nfoPath');
    
    final Map<String, dynamic>? metadata = await NfoParser.parseNfo(nfoPath);
    
    // Create Video object
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
    
    final video = Video(
      path: path,
      mtime: mtime,
      title: formattedTitle,
      genres: metadata?['genres'] ?? '',
      year: year,
      directors: metadata?['directors'] ?? '',
      plot: metadata?['plot'] ?? '',
      actors: metadata?['actors'] ?? '',
      duration: metadata?['duration'] ?? '',
      rating: metadata?['rating'] ?? 0.0,
      posterPath: metadata?['poster'] ?? '',
    );

    // Insert into DB (update if exists)
    await DatabaseHelper.instance.insertVideo(video);
  }
}
