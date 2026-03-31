import '../services/settings_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/video.dart';
import 'logger_service.dart';
import '../utils/video_extensions.dart';
import '../config/app_config.dart';
import 'package:intl/intl.dart';

enum MetadataUpdateResult { updated, alreadyInSync, failed }

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
        '-v',
        'quiet',
        '-print_format',
        'json',
        '-show_format',
        filePath,
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

  Future<MetadataUpdateResult> updateFileMetadata(
    Video video, {
    bool enforceFullMetadata = false,
  }) async {
    final FileSystemEntityType type = await FileSystemEntity.type(video.path);

    if (type == FileSystemEntityType.directory) {
      return _updateSeriesFiles(
        video,
        enforceFullMetadata: enforceFullMetadata,
      );
    } else if (type == FileSystemEntityType.file) {
      return _updateSingleFile(
        video.path,
        video,
        enforceFullMetadata: enforceFullMetadata,
      );
    } else {
      debugPrint('Path not found or invalid: ${video.path}');
      return MetadataUpdateResult.failed;
    }
  }

  Future<MetadataUpdateResult> _updateSingleFile(
    String path,
    Video video, {
    bool preserveTitle = false,
    String? forcedTitle,
    bool enforceFullMetadata = false,
  }) async {
    final File originalFile = File(path);
    if (!await originalFile.exists()) return MetadataUpdateResult.failed;

    final String dir = p.dirname(path);
    final String filename = p.basename(path);
    final String tempPath = p.join(dir, 'temp_$filename');

    try {
      // 1. Check if update is needed BEFORE renaming to temp
      final String encodedBy =
          'MyPlaylist ${AppConfig.appVersion} ${DateFormat('dd/MM/yyyy').format(DateTime.now())}';
      final currentMetadata = await getFileMetadata(path);

      // If metadata is empty, it might be a corrupted file or unsupported format
      if (currentMetadata.isEmpty) {
        await LoggerService().error(
          'Could not read metadata for $path. File might be corrupted.',
        );
        return MetadataUpdateResult.failed;
      }

      final targetTitle = forcedTitle ?? video.title;
      bool titleMatch = norm(currentMetadata['title']) == norm(targetTitle);

      if (!enforceFullMetadata) {
        // Logica originale per la rinomina/aggiornamento standard:
        // Controlla il titolo. Se combacia, salta (già in sync). Se NON combacia, aggiorna tutto.
        if (titleMatch) {
          debugPrint('Skip $path (Metadata title already in sync)');
          return MetadataUpdateResult.alreadyInSync;
        }
      } else {
        // Logica per l'aggiornamento di massa (Bulk Sync):
        // Esclude dal controllo il titolo e guarda solo se i tag esterni sono "vuoti".
        bool hasPlot =
            currentMetadata['description']?.toString().isNotEmpty == true ||
            currentMetadata['comment']?.toString().isNotEmpty == true;
        bool hasRating =
            currentMetadata['rating']?.toString().isNotEmpty == true ||
            currentMetadata['vote']?.toString().isNotEmpty == true;
        bool hasPoster =
            currentMetadata['poster_url']?.toString().isNotEmpty == true ||
            currentMetadata['artwork']?.toString().isNotEmpty == true;

        // Se sono TUTTI pieni, allora saltiamo (già in sync).
        // Diversamente (se almeno uno è vuoto), procediamo ad aggiornare tutti i metadati
        if (hasPlot && hasRating && hasPoster) {
          debugPrint('Skip $path (Metadata targets already full in sync)');
          return MetadataUpdateResult.alreadyInSync;
        }
      }

      final bool useFastEngine = SettingsService().fastMetadataEngineEnabled;
      final ext = p.extension(path).toLowerCase();

      debugPrint('[MetadataService] Update requested for $path');
      debugPrint('[MetadataService] Fast Engine Setting: $useFastEngine');

      if (useFastEngine) {
        if (ext == '.mkv') {
          final bool toolAvailable = await _isToolAvailable('mkvpropedit');
          debugPrint('[MetadataService] mkvpropedit available: $toolAvailable');
          if (toolAvailable) {
            final succ = await _updateSingleFileMKVInPlace(path, video, encodedBy, preserveTitle, forcedTitle);
            if (succ) {
              debugPrint('[MetadataService] MKV in-place update SUCCESS');
              return MetadataUpdateResult.updated;
            }
            debugPrint('[MetadataService] MKV in-place update FAILED, falling back...');
          }
        } else if (ext == '.mp4' || ext == '.m4v') {
          final bool toolAvailable = await _isToolAvailable('MP4Box');
          debugPrint('[MetadataService] MP4Box available: $toolAvailable');
          if (toolAvailable) {
            final succ = await _updateSingleFileMP4InPlace(path, video, encodedBy, preserveTitle, forcedTitle);
            if (succ) {
              debugPrint('[MetadataService] MP4 in-place update SUCCESS');
              return MetadataUpdateResult.updated;
            }
            debugPrint('[MetadataService] MP4 in-place update FAILED, falling back...');
          }
        }
      } else {
        debugPrint('[MetadataService] Fast Engine disabled by user settings');
      }

      debugPrint('[MetadataService] Using FFmpeg fallback (slow)...');

      // 2. Now that we know we need an update, rename original to temp
      await originalFile.rename(tempPath);

      // 3. Build common metadata args (including encoder)
      final List<String> metadataArgs = [
        '-metadata',
        'genre=${video.genres}',
        '-metadata',
        'date=${video.year}',
        '-metadata',
        'artist=${video.directors}',
        '-metadata',
        'Codificato da=$encodedBy',
        '-metadata',
        'encoded_by=$encodedBy',
        '-metadata',
        'encoder=$encodedBy',
        '-metadata',
        'rating=${video.rating}',
        '-metadata',
        'poster_url=${video.posterPath}',
        if (preserveTitle) ...[
          '-metadata',
          'album=${video.title}',
          '-metadata',
          'show=${video.title}',
          '-metadata',
          'description=${video.plot}',
          '-metadata',
          'comment=${video.plot}',
          if (forcedTitle != null) '-metadata',
          'title=$forcedTitle',
        ] else ...[
          '-metadata',
          'title=${video.title}',
          '-metadata',
          'description=${video.plot}',
          '-metadata',
          'comment=${video.plot}',
        ],
      ];

      // 3. Attempt 1: Full Mapping (map 0)
      final List<String> args1 = [
        '-i',
        tempPath,
        '-map',
        '0',
        '-map_metadata',
        '0',
        '-c',
        'copy',
        '-ignore_unknown',
        ...metadataArgs,
        path,
      ];

      var result = await Process.run('ffmpeg', args1);

      // 4. Attempt 2: Fallback Mapping (v + a only) if Attempt 1 fails
      if (result.exitCode != 0) {
        await LoggerService().warning(
          'FFmpeg full mapping failed for $path. Retrying with video/audio only...',
        );
        final List<String> args2 = [
          '-i',
          tempPath,
          '-map',
          '0:v',
          '-map',
          '0:a',
          '-map_metadata',
          '0',
          '-c',
          'copy',
          '-ignore_unknown',
          ...metadataArgs,
          path,
        ];
        result = await Process.run('ffmpeg', args2);
      }

      if (result.exitCode == 0) {
        await File(tempPath).delete();
        return MetadataUpdateResult.updated;
      } else {
        await LoggerService().error(
          'FFmpeg failed for $path after retry: ${result.stderr}',
        );
        // Restore original
        if (await File(path).exists()) await File(path).delete();
        await File(tempPath).rename(path);
        return MetadataUpdateResult.failed;
      }
    } catch (e) {
      await LoggerService().error('Error updating metadata for $path', e);
      if (await File(tempPath).exists()) {
        if (await File(path).exists()) await File(path).delete();
        await File(tempPath).rename(path);
      }
      return MetadataUpdateResult.failed;
    }
  }

  String norm(String? s) => (s ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  Future<bool> _isToolAvailable(String command) async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('where', [command]);
        return result.exitCode == 0;
      } else {
        final result = await Process.run('which', [command]);
        return result.exitCode == 0;
      }
    } catch (_) {
      return false;
    }
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  Future<bool> _updateSingleFileMKVInPlace(
    String path,
    Video video,
    String encodedBy,
    bool preserveTitle,
    String? forcedTitle,
  ) async {
    try {
      final String dir = p.dirname(path);
      final String tagsPath = p.join(dir, 'temp_tags_${DateTime.now().millisecondsSinceEpoch}.xml');
      final title = forcedTitle ?? video.title;

      final xml = '''<?xml version="1.0"?>
<!DOCTYPE Tags SYSTEM "matroskatags.dtd">
<Tags>
  <Tag>
    <Targets>
      <TargetTypeValue>50</TargetTypeValue>
    </Targets>
    <Simple>
      <Name>GENRE</Name>
      <String>${_escapeXml(video.genres)}</String>
    </Simple>
    <Simple>
      <Name>ARTIST</Name>
      <String>${_escapeXml(video.directors)}</String>
    </Simple>
    <Simple>
      <Name>RATING</Name>
      <String>${_escapeXml(video.rating.toString())}</String>
    </Simple>
    <Simple>
      <Name>POSTER_URL</Name>
      <String>${_escapeXml(video.posterPath)}</String>
    </Simple>
    <Simple>
      <Name>ENCODED_BY</Name>
      <String>${_escapeXml(encodedBy)}</String>
    </Simple>
    <Simple>
      <Name>DESCRIPTION</Name>
      <String>${_escapeXml(video.plot)}</String>
    </Simple>
    <Simple>
      <Name>COMMENT</Name>
      <String>${_escapeXml(video.plot)}</String>
    </Simple>
    ${preserveTitle ? '''
    <Simple>
      <Name>ALBUM</Name>
      <String>${_escapeXml(video.title)}</String>
    </Simple>
    <Simple>
      <Name>SHOW</Name>
      <String>${_escapeXml(video.title)}</String>
    </Simple>
    ''' : ''}
  </Tag>
</Tags>''';

      await File(tagsPath).writeAsString(xml);

      final List<String> args = [
        path,
        '--edit', 'info',
        '--set', 'title=$title',
        '--set', 'date=${video.year}',
        '--tags', 'all:$tagsPath'
      ];

      debugPrint('[MetadataService] Running mkvpropedit with args: $args');
      final result = await Process.run('mkvpropedit', args);
      await File(tagsPath).delete();

      if (result.exitCode == 0) {
        debugPrint('[MetadataService] mkvpropedit SUCCESS');
        return true;
      }
      debugPrint('[MetadataService] mkvpropedit FAILED: ${result.stderr}');
      await LoggerService().error('mkvpropedit failed for $path: ${result.stderr}');
      return false;
    } catch (e) {
      await LoggerService().error('Error in MKV in-place update for $path', e);
      return false;
    }
  }

  Future<bool> _updateSingleFileMP4InPlace(
    String path,
    Video video,
    String encodedBy,
    bool preserveTitle,
    String? forcedTitle,
  ) async {
    try {
      final title = forcedTitle ?? video.title;
      
      // MP4Box -itags usually uses colons as separators
      List<String> tags = [];
      
      String clean(String s) => s.replaceAll(':', ';').replaceAll('"', "'");
      
      if (title.isNotEmpty) tags.add('title=${clean(title)}');
      if (video.directors.isNotEmpty) tags.add('artist=${clean(video.directors)}');
      if (video.year.toString().isNotEmpty) tags.add('created=${clean(video.year.toString())}');
      if (video.genres.isNotEmpty) tags.add('genre=${clean(video.genres)}');
      if (video.plot.isNotEmpty) {
        tags.add('comment=${clean(video.plot)}');
        tags.add('sdesc=${clean(video.plot)}'); // short description
      }
      tags.add('tool=${clean(encodedBy)}');
      
      if (preserveTitle && video.title.isNotEmpty) {
        tags.add('album=${clean(video.title)}');
        tags.add('show=${clean(video.title)}');
      }
      
      final String itagsString = tags.join(':');
      final List<String> args = ['-itags', itagsString, path];

      debugPrint('[MetadataService] Running MP4Box with args: $args');
      final result = await Process.run('MP4Box', args);
      if (result.exitCode == 0) {
        debugPrint('[MetadataService] MP4Box SUCCESS');
        return true;
      }
      debugPrint('[MetadataService] MP4Box FAILED: ${result.stderr}');
      await LoggerService().error('MP4Box failed for $path: ${result.stderr}');
      return false;
    } catch (e) {
      await LoggerService().error('Error in MP4 in-place update for $path', e);
      return false;
    }
  }

  String _cleanRemainder(String input) {
    String cleaned = input;
    // Tags to remove
    final stopTags = [
      'ita',
      'eng',
      'sub',
      '1080p',
      '720p',
      '480p',
      'h264',
      'x264',
      'hevc',
      'web-dl',
      'bluray',
      'dvdrip',
      'ac3',
      'aac',
    ];

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

    return cleaned
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
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

  Future<MetadataUpdateResult> _updateSeriesFiles(
    Video video, {
    bool enforceFullMetadata = false,
  }) async {
    final dir = Directory(video.path);
    if (!await dir.exists()) return MetadataUpdateResult.failed;

    int updatedCount = 0;
    bool hadError = false;

    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          final basename = p.basenameWithoutExtension(entity.path);

          if (VideoExtensions.supported.contains(ext)) {
            debugPrint(
              'Checking/Updating metadata for episode: ${entity.path}',
            );

            final formattedTitle = _generateEpisodeTitle(video.title, basename);

            final result = await _updateSingleFile(
              entity.path,
              video,
              preserveTitle: true,
              forcedTitle: formattedTitle,
              enforceFullMetadata: enforceFullMetadata,
            );

            if (result == MetadataUpdateResult.updated) {
              updatedCount++;
            }
            if (result == MetadataUpdateResult.alreadyInSync) {
              // alreadyInSync
            }
            if (result == MetadataUpdateResult.failed) hadError = true;
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning series directory: $e');
      return MetadataUpdateResult.failed;
    }

    if (hadError) return MetadataUpdateResult.failed;
    if (updatedCount > 0) return MetadataUpdateResult.updated;
    return MetadataUpdateResult.alreadyInSync;
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

              final originalName = p
                  .basename(entity.path)
                  .substring(5); // remove 'temp_'
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
