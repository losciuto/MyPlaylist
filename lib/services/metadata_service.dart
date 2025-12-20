import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/video.dart';

class MetadataService {
  static final MetadataService _instance = MetadataService._internal();

  factory MetadataService() {
    return _instance;
  }

  MetadataService._internal();

  Future<bool> checkFfmpegAvailability() async {
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('FFmpeg check failed: $e');
      return false;
    }
  }

  Future<bool> updateFileMetadata(Video video) async {
    final File originalFile = File(video.path);
    if (!await originalFile.exists()) {
      debugPrint('File not found: ${video.path}');
      return false;
    }

    final String dir = p.dirname(video.path);
    final String filename = p.basename(video.path);
    final String tempPath = p.join(dir, 'temp_$filename');

    try {
      // 1. Rename original to temp
      await originalFile.rename(tempPath);
      debugPrint('Renamed to temp: $tempPath');

      // 2. Run ffmpeg to write metadata to original path (new file)
      // -map_metadata 0: Keep existing global metadata
      // -c copy: Copy streams without re-encoding
      final List<String> args = [
        '-i', tempPath,
        '-map_metadata', '0',
        '-c', 'copy',
        '-metadata', 'title=${video.title}',
        '-metadata', 'date=${video.year}',
        '-metadata', 'genre=${video.genres}', // May need handling for multiple genres
        '-metadata', 'artist=${video.directors}', // Director often mapped to artist
        '-metadata', 'description=${video.plot}', // Description or comment
        '-metadata', 'comment=${video.plot}',
        video.path 
      ];

      debugPrint('Running ffmpeg: $args');
      final result = await Process.run('ffmpeg', args);

      if (result.exitCode == 0) {
        debugPrint('FFmpeg success. Deleting temp.');
        await File(tempPath).delete();
        return true;
      } else {
        debugPrint('FFmpeg failed: ${result.stderr}');
        // Restore original
        if (await File(video.path).exists()) {
          await File(video.path).delete();
        }
        await File(tempPath).rename(video.path);
        return false;
      }
    } catch (e) {
      debugPrint('Error updating metadata: $e');
      // Attempt restore
      if (await File(tempPath).exists()) {
         if (await File(video.path).exists()) {
            await File(video.path).delete();
         }
         await File(tempPath).rename(video.path);
      }
      return false;
    }
  }

  Future<void> cleanupTempFiles(String directoryPath) async {
    try {
      final dir = Directory(directoryPath);
      if (await dir.exists()) {
        final List<FileSystemEntity> entities = await dir.list().toList();
        for (final entity in entities) {
          if (entity is File && p.basename(entity.path).startsWith('temp_')) {
            try {
              debugPrint('Cleaning up orphan temp file: ${entity.path}');
              // If original doesn't exist, restore temp to original? 
              // Or just delete temp if original exists?
              // Safer strategy: Only delete temp if original exists.
              // If original is missing, temp might be the backup!
              
              final originalName = p.basename(entity.path).substring(5); // remove 'temp_'
              final originalPath = p.join(directoryPath, originalName);
              
              if (await File(originalPath).exists()) {
                 await entity.delete();
              } else {
                 // Potentially restore?
                 debugPrint('Original missing, restoring temp: $originalPath');
                 await entity.rename(originalPath);
              }
            } catch (e) {
              debugPrint('Error cleaning temp file: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error listing directory for cleanup: $e');
    }
  }
}
