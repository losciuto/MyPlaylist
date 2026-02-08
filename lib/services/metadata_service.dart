import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/video.dart';
import 'logger_service.dart';

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

  Future<Map<String, String>> getFileMetadata(String filePath) async {
    try {
      final result = await Process.run('ffprobe', [
        '-v', 'quiet',
        '-print_format', 'json',
        '-show_format',
        filePath
      ]);

      if (result.exitCode != 0) {
        debugPrint('ffprobe failed for $filePath');
        return {};
      }

      final String output = result.stdout.toString();
      
      try {
        final Map<String, dynamic> json = jsonDecode(output);
        if (json.containsKey('format') && json['format'] is Map) {
          final format = json['format'] as Map<String, dynamic>;
          if (format.containsKey('tags') && format['tags'] is Map) {
             final tags = Map<String, String>.from(format['tags']);
             return tags;
          }
        }
      } catch (e) {
        debugPrint('JSON parse error: $e');
      }
      
      return {};
    } catch (e) {
      debugPrint('Error reading metadata: $e');
      return {};
    }
  }

  Future<bool> updateFileMetadata(Video video) async {
    final FileSystemEntityType type = await FileSystemEntity.type(video.path);
    
    if (type == FileSystemEntityType.directory) {
      return _updateSeriesFiles(video);
    } else if (type == FileSystemEntityType.file) {
      return _updateSingleFile(video.path, video);
    } else {
      debugPrint('Path not found or invalid: ${video.path}');
      return false;
    }
  }

  Future<bool> _updateSingleFile(String path, Video video, {bool preserveTitle = false, String? forcedTitle}) async {
    final File originalFile = File(path);
    if (!await originalFile.exists()) return false;

    final String dir = p.dirname(path);
    final String filename = p.basename(path);
    final String tempPath = p.join(dir, 'temp_$filename');

    try {
      // 1. Rename original to temp
      await originalFile.rename(tempPath);
      
      // 2. Build common metadata args
      final List<String> metadataArgs = [
        '-metadata', 'genre=${video.genres}',
        '-metadata', 'date=${video.year}',
        '-metadata', 'artist=${video.directors}',
        if (preserveTitle) ...[
           '-metadata', 'album=${video.title}',
           '-metadata', 'show=${video.title}',
           '-metadata', 'description=${video.plot}',
           '-metadata', 'comment=${video.plot}',
           if (forcedTitle != null) '-metadata', 'title=$forcedTitle',
        ] else ...[
           '-metadata', 'title=${video.title}',
           '-metadata', 'description=${video.plot}',
           '-metadata', 'comment=${video.plot}',
        ],
      ];

      // 3. Attempt 1: Full Mapping (map 0)
      final List<String> args1 = [
        '-i', tempPath,
        '-map', '0',
        '-map_metadata', '0',
        '-c', 'copy',
        '-ignore_unknown',
        ...metadataArgs,
        path 
      ];

      var result = await Process.run('ffmpeg', args1);

      // 4. Attempt 2: Fallback Mapping (v + a only) if Attempt 1 fails
      if (result.exitCode != 0) {
        await LoggerService().warning('FFmpeg full mapping failed for $path. Retrying with video/audio only...');
        final List<String> args2 = [
          '-i', tempPath,
          '-map', '0:v',
          '-map', '0:a',
          '-map_metadata', '0',
          '-c', 'copy',
          '-ignore_unknown',
          ...metadataArgs,
          path 
        ];
        result = await Process.run('ffmpeg', args2);
      }

      if (result.exitCode == 0) {
        await File(tempPath).delete();
        return true;
      } else {
        await LoggerService().error('FFmpeg failed for $path after retry: ${result.stderr}');
        // Restore original
        if (await File(path).exists()) await File(path).delete();
        await File(tempPath).rename(path);
        return false;
      }
    } catch (e) {
      await LoggerService().error('Error updating metadata for $path', e);
      if (await File(tempPath).exists()) {
         if (await File(path).exists()) await File(path).delete();
         await File(tempPath).rename(path);
      }
      return false;
    }
  }

  String _cleanRemainder(String input) {
    String cleaned = input;
    // Tags to remove
    final stopTags = ['ita', 'eng', 'sub', '1080p', '720p', '480p', 'h264', 'x264', 'hevc', 'web-dl', 'bluray', 'dvdrip', 'ac3', 'aac'];
    
    // Find earliest tag
    int earliestIndex = -1;
    for (final tag in stopTags) {
      final index = cleaned.toLowerCase().indexOf(tag.toLowerCase());
      if (index != -1) {
         if (index > 0) {
            final charBefore = cleaned[index - 1];
            if (['.', ' ', '_', '-'].contains(charBefore)) {
                if (earliestIndex == -1 || index < earliestIndex) {
                    earliestIndex = index;
                }
            }
         }
      }
    }
    
    if (earliestIndex != -1) {
       cleaned = cleaned.substring(0, earliestIndex - 1);
    }
    
    return cleaned.replaceAll('.', ' ').replaceAll('_', ' ').replaceAll('-', ' ').trim();
  }

  String _generateEpisodeTitle(String seriesName, String filename) {
    // 1. Try SxxExx pattern
    final sxeMatch = RegExp(r'[sS](\d{1,2})[eE](\d{1,2})').firstMatch(filename);
    if (sxeMatch != null) {
      final s = sxeMatch.group(1)!.padLeft(2, '0');
      final e = sxeMatch.group(2)!.padLeft(2, '0');
      
      // Extract remainder logic
      String remainder = filename.substring(sxeMatch.end);
      String extraTitle = _cleanRemainder(remainder);
      
      if (extraTitle.isNotEmpty) {
         return '$seriesName - S${s}E$e $extraTitle';
      } else {
         return '$seriesName - S${s}E$e';
      }
    }

    // 2. Try xXX pattern (e.g. 1x05)
    final xMatch = RegExp(r'(\d{1,2})x(\d{1,2})').firstMatch(filename);
    if (xMatch != null) {
      final s = xMatch.group(1)!.padLeft(2, '0');
      final e = xMatch.group(2)!.padLeft(2, '0');
      
       String remainder = filename.substring(xMatch.end);
       String extraTitle = _cleanRemainder(remainder);
       
       if (extraTitle.isNotEmpty) {
          return '$seriesName - S${s}E$e $extraTitle';
       } else {
          return '$seriesName - S${s}E$e';
       }
    }

    // 3. Fallback: Clean filename completely
    String cleaned = _cleanRemainder(filename);
    return '$seriesName - $cleaned'; 
  }

  Future<bool> _updateSeriesFiles(Video video) async {
    final dir = Directory(video.path);
    if (!await dir.exists()) return false;

    // Reuse extension connection or hardcode
    const videoExtensions = [
      '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.mpg', 
      '.mpeg', '.m2v', '.ts', '.mts', '.m2ts', '.vob', '.ogv', '.ogg', '.qt', 
      '.yuv', '.rm', '.rmvb', '.asf', '.amv', '.divx', '.3gp', '.3g2', '.mxf'
    ];

    bool allSuccess = true;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
           final ext = p.extension(entity.path).toLowerCase();
           final basename = p.basenameWithoutExtension(entity.path);
           
           if (videoExtensions.contains(ext)) {
             debugPrint('Updating metadata for episode: ${entity.path}');
             
             final formattedTitle = _generateEpisodeTitle(video.title, basename);
             
             final success = await _updateSingleFile(
                entity.path, 
                video, 
                preserveTitle: true,
                forcedTitle: formattedTitle
             );
             if (!success) allSuccess = false;
           }
        }
      }
    } catch (e) {
      debugPrint('Error scanning series directory: $e');
      return false;
    }
    return allSuccess;
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
