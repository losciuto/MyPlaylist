import '../services/settings_service.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/video.dart';
import 'logger_service.dart';
import '../utils/video_extensions.dart';
import '../config/app_config.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';

enum MetadataUpdateResult { updated, alreadyInSync, failed }

class MetadataUpdateResponse {
  final MetadataUpdateResult result;
  final String method;
  final String? reason;

  MetadataUpdateResponse(this.result, {this.method = '', this.reason});
}

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
            final rawTags = Map<String, dynamic>.from(format['tags']);
            final Map<String, String> tags = {};
            rawTags.forEach((k, v) => tags[k.toLowerCase()] = v.toString());
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

  Future<MetadataUpdateResponse> updateFileMetadata(
    Video video, {
    bool enforceFullMetadata = false,
    Function(String, String?)? onMethodDecided,
  }) async {
    final FileSystemEntityType type = await FileSystemEntity.type(video.path);

    if (type == FileSystemEntityType.directory) {
      return _updateSeriesFiles(
        video,
        enforceFullMetadata: enforceFullMetadata,
        onMethodDecided: onMethodDecided,
      );
    } else if (type == FileSystemEntityType.file) {
      return _updateSingleFile(
        video.path,
        video,
        enforceFullMetadata: enforceFullMetadata,
        onMethodDecided: onMethodDecided,
      );
    } else {
      debugPrint('Path not found or invalid: ${video.path}');
      return MetadataUpdateResponse(MetadataUpdateResult.failed);
    }
  }

  /// Legge i tag raw dal file tramite ffprobe (formato + streams tags).
  Future<Map<String, String>> getRawFileMetadata(String filePath) async {
    try {
      final result = await Process.run('ffprobe', [
        '-v', 'quiet',
        '-print_format', 'json',
        '-show_format',
        '-show_streams',
        filePath,
      ]);
      if (result.exitCode != 0) return {};
      final json = jsonDecode(result.stdout.toString());
      final Map<String, String> tags = {};
      // Tags del formato
      final format = json['format'];
      if (format is Map && format['tags'] is Map) {
        (format['tags'] as Map).forEach((k, v) {
          tags[k.toString().toLowerCase()] = v.toString();
        });
      }
      return tags;
    } catch (e) {
      debugPrint('getRawFileMetadata error: $e');
      return {};
    }
  }

  /// Salva una mappa di tag nel file, scegliendo lo strumento migliore
  /// disponibile: mkvpropedit > MP4Box > FFmpeg.
  Future<MetadataUpdateResponse> saveFileMetadata(
    String path,
    Map<String, String> tags,
  ) async {
    final ext = p.extension(path).toLowerCase();
    try {
      if (ext == '.mkv' && await _isToolAvailable('mkvpropedit')) {
        return _saveMKVMetadata(path, tags);
      } else if ((ext == '.mp4' || ext == '.m4v') &&
          await _isToolAvailable('MP4Box')) {
        return _saveMP4Metadata(path, tags);
      } else {
        return _saveGenericMetadata(path, tags);
      }
    } catch (e) {
      await LoggerService().error('Error saving metadata to $path', e);
      return MetadataUpdateResponse(MetadataUpdateResult.failed);
    }
  }

  Future<MetadataUpdateResponse> _saveMKVMetadata(
    String path,
    Map<String, String> tags,
  ) async {
    final tempTagsXml = p.join(
      p.dirname(path),
      'temp_tags_${DateTime.now().millisecondsSinceEpoch}.xml',
    );

    final xml = StringBuffer();
    xml.writeln('<?xml version="1.0"?>');
    xml.writeln('<!DOCTYPE Tags SYSTEM "matroskatags.dtd">');
    xml.writeln('<Tags>');
    xml.writeln('  <Tag>');
    xml.writeln('    <Targets><TargetTypeValue>50</TargetTypeValue></Targets>');
    tags.forEach((key, value) {
      xml.writeln('    <Simple>');
      xml.writeln('      <Name>${_escapeXml(key.toUpperCase())}</Name>');
      xml.writeln('      <String>${_escapeXml(value)}</String>');
      xml.writeln('    </Simple>');
    });
    xml.writeln('  </Tag>');
    xml.writeln('</Tags>');

    await File(tempTagsXml).writeAsString(xml.toString());

    final List<String> mkvArgs = [path, '--tags', 'all:$tempTagsXml'];
    // Aggiorna anche il titolo nel segment info se presente
    final title = tags['title'] ?? tags['TITLE'];
    if (title != null && title.isNotEmpty) {
      mkvArgs.addAll(['--edit', 'info', '--set', 'title=$title']);
    }

    final result = await Process.run('mkvpropedit', mkvArgs);
    if (await File(tempTagsXml).exists()) await File(tempTagsXml).delete();

    if (result.exitCode == 0) {
      return MetadataUpdateResponse(
        MetadataUpdateResult.updated,
        method: 'mkvpropedit',
      );
    }
    await LoggerService().error(
      'mkvpropedit saveFileMetadata failed: ${result.stderr}',
    );
    return MetadataUpdateResponse(
      MetadataUpdateResult.failed,
      reason: result.stderr.toString(),
    );
  }

  Future<MetadataUpdateResponse> _saveMP4Metadata(
    String path,
    Map<String, String> tags,
  ) async {
    final itags = tags.entries.map((e) {
      final k = e.key.toLowerCase();
      final v = e.value.replaceAll(':', ';').replaceAll('"', "'");
      return '$k=$v';
    }).join(':');

    final result = await Process.run('MP4Box', ['-itags', itags, path]);
    if (result.exitCode == 0) {
      return MetadataUpdateResponse(
        MetadataUpdateResult.updated,
        method: 'MP4Box',
      );
    }
    await LoggerService().error(
      'MP4Box saveFileMetadata failed: ${result.stderr}',
    );
    return MetadataUpdateResponse(
      MetadataUpdateResult.failed,
      reason: result.stderr.toString(),
    );
  }

  Future<MetadataUpdateResponse> _saveGenericMetadata(
    String path,
    Map<String, String> tags,
  ) async {
    final dir = p.dirname(path);
    final filename = p.basename(path);
    final tempPath = p.join(dir, 'temp_meta_$filename');

    final List<String> args = [
      '-i', path,
      '-map', '0',
      '-c', 'copy',
      '-ignore_unknown',
    ];
    tags.forEach((key, value) {
      args.addAll(['-metadata', '$key=$value']);
    });
    args.add(tempPath);

    final result = await Process.run('ffmpeg', args);
    if (result.exitCode == 0) {
      await File(path).delete();
      await File(tempPath).rename(path);
      return MetadataUpdateResponse(
        MetadataUpdateResult.updated,
        method: 'FFmpeg',
      );
    }
    if (await File(tempPath).exists()) await File(tempPath).delete();
    await LoggerService().error(
      'FFmpeg saveFileMetadata failed: ${result.stderr}',
    );
    return MetadataUpdateResponse(
      MetadataUpdateResult.failed,
      reason: result.stderr.toString(),
    );
  }

  Future<MetadataUpdateResponse> _updateSingleFile(
    String path,
    Video video, {
    bool preserveTitle = false,
    String? forcedTitle,
    bool enforceFullMetadata = false,
    Function(String, String?)? onMethodDecided,
  }) async {
    String currentPath = path;
    final settings = SettingsService();

    final String ext = p.extension(currentPath).toLowerCase();
    // Elenco di estensioni comunemente remuxabili in MKV senza ricodifica
    final Set<String> remuxableExtensions = {
      '.avi',
      '.mp4',
      '.m4v',
      '.mov',
      '.wmv',
      '.flv',
      '.mpg',
      '.mpeg',
      '.ts',
      '.m2ts',
      '.3gp',
    };

    if (settings.autoConvertToMkv && remuxableExtensions.contains(ext)) {
      onMethodDecided?.call(currentPath, 'Remuxing -> MKV');
      final String? newMkvPath = await _remuxToMkvAndBackup(currentPath, video);
      if (newMkvPath != null) {
        currentPath = newMkvPath;
        // Se è un film standalone (il percorso coincide con video.path), aggiorna il DB
        if (path == video.path && !video.isSeries) {
          final updatedVideo = video.copyWith(path: newMkvPath);
          await AppDatabase.instance.updateVideo(updatedVideo);
          await LoggerService().info(
            '[MetadataService] Remuxing in MKV completato e DB aggiornato: $newMkvPath',
          );
        } else {
          await LoggerService().info(
            '[MetadataService] Remuxing episodio in MKV completato: $newMkvPath',
          );
        }
      }
    }

    final File originalFile = File(currentPath);
    if (!await originalFile.exists()) {
      return MetadataUpdateResponse(MetadataUpdateResult.failed);
    }

    final String dir = p.dirname(currentPath);


    try {
      // 1. Check if update is needed BEFORE renaming to temp
      final String encodedBy =
          'MyPlaylist ${AppConfig.appVersion} ${DateFormat('dd/MM/yyyy').format(DateTime.now())}';
      final currentMetadata = await getFileMetadata(currentPath);

      // If metadata is empty, it might be a corrupted file or unsupported format
      if (currentMetadata.isEmpty) {
        await LoggerService().error(
          'Could not read metadata for $currentPath. File might be corrupted.',
        );
        return MetadataUpdateResponse(MetadataUpdateResult.failed);
      }

      final targetTitle = forcedTitle ?? video.title;
      bool titleMatch = norm(currentMetadata['title']) == norm(targetTitle);

      if (!enforceFullMetadata) {
        // Logica originale per la rinomina/aggiornamento standard:
        // Controlla il titolo. Se combacia, salta (già in sync). Se NON combacia, aggiorna tutto.
        if (titleMatch) {
          debugPrint('Skip $currentPath (Metadata title already in sync)');
          return MetadataUpdateResponse(MetadataUpdateResult.alreadyInSync);
        }
      } else {
        // Logica per l'aggiornamento di massa (Bulk Sync):
        // Verifica se i tag necessari (quelli presenti nel DB) sono già nel file.
        
        bool plotInSync = true;
        if (video.plot.isNotEmpty) {
          plotInSync = _hasOneOf(currentMetadata, ['description', 'comment', 'sdesc']);
        }

        bool ratingInSync = true;
        if (video.rating > 0) {
          ratingInSync = _hasOneOf(currentMetadata, ['rating', 'vote', 'user_rating']);
        }

        bool posterInSync = true;
        if (video.posterPath.isNotEmpty) {
          posterInSync = _hasOneOf(currentMetadata, ['poster_url', 'artwork', 'cover']);
        }

        // Se tutto quello che abbiamo nel DB è riflesso nel file, saltiamo.
        if (plotInSync && ratingInSync && posterInSync) {
          debugPrint('Skip $currentPath (Metadata DB source already reflected in file)');
          return MetadataUpdateResponse(MetadataUpdateResult.alreadyInSync);
        }
      }

      final bool useFastEngine = SettingsService().fastMetadataEngineEnabled;
      final ext = p.extension(currentPath).toLowerCase();

      debugPrint('[MetadataService] Update requested for $currentPath');
      debugPrint('[MetadataService] Fast Engine Setting: $useFastEngine');

      String? ffmpegReason;

      if (useFastEngine) {
        if (ext == '.mkv') {
          final bool toolAvailable = await _isToolAvailable('mkvpropedit');
          debugPrint('[MetadataService] mkvpropedit available: $toolAvailable');
          if (toolAvailable) {
            onMethodDecided?.call('mkvpropedit', null);
            final error = await _updateSingleFileMKVInPlace(
              currentPath,
              video,
              encodedBy,
              preserveTitle,
              forcedTitle,
            );
            if (error == null) {
              debugPrint('[MetadataService] MKV in-place update SUCCESS');
              return MetadataUpdateResponse(
                MetadataUpdateResult.updated,
                method: 'mkvpropedit',
              );
            }
            debugPrint(
              '[MetadataService] MKV in-place update FAILED: $error, falling back...',
            );
            ffmpegReason = 'tool_failed:mkvpropedit:$error';
          } else {
            ffmpegReason = 'tool_not_found:mkvpropedit';
          }
        } else if (ext == '.mp4' || ext == '.m4v') {
          final bool toolAvailable = await _isToolAvailable('MP4Box');
          debugPrint('[MetadataService] MP4Box available: $toolAvailable');
          if (toolAvailable) {
            onMethodDecided?.call('MP4Box', null);
            final error = await _updateSingleFileMP4InPlace(
              currentPath,
              video,
              encodedBy,
              preserveTitle,
              forcedTitle,
            );
            if (error == null) {
              debugPrint('[MetadataService] MP4 in-place update SUCCESS');
              return MetadataUpdateResponse(
                MetadataUpdateResult.updated,
                method: 'MP4Box',
              );
            }
            debugPrint(
              '[MetadataService] MP4 in-place update FAILED: $error, falling back...',
            );
            ffmpegReason = 'tool_failed:MP4Box:$error';
          } else {
            ffmpegReason = 'tool_not_found:MP4Box';
          }
        } else {
          ffmpegReason = 'unsupported_format:$ext';
        }
      } else {
        debugPrint('[MetadataService] Fast Engine disabled by user settings');
        ffmpegReason = 'fast_engine_disabled';
      }

      debugPrint('[MetadataService] Using FFmpeg fallback (slow)... Reason: $ffmpegReason');
      onMethodDecided?.call('FFmpeg', ffmpegReason);

      final String filename = p.basename(currentPath);
      final String tempPath = p.join(dir, 'temp_$filename');

      // 2. Now that we know we need an update, rename original to temp
      await File(currentPath).rename(tempPath);

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
        currentPath,
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
          currentPath,
        ];
        result = await Process.run('ffmpeg', args2);
      }

      if (result.exitCode == 0) {
        if (await File(tempPath).exists()) await File(tempPath).delete();
        return MetadataUpdateResponse(
          MetadataUpdateResult.updated,
          method: 'FFmpeg',
          reason: ffmpegReason,
        );
      } else {
        await LoggerService().error(
          'FFmpeg failed for $currentPath after retry: ${result.stderr}',
        );
        // Restore original
        if (await File(currentPath).exists()) await File(currentPath).delete();
        if (await File(tempPath).exists()) await File(tempPath).rename(currentPath);
        return MetadataUpdateResponse(MetadataUpdateResult.failed);
      }
    } catch (e) {
      await LoggerService().error('Error updating metadata for $currentPath', e);
      // We don't have tempPath here, but it was set earlier. 
      // If error happens during ffmpeg, we might need to restore.
      return MetadataUpdateResponse(MetadataUpdateResult.failed);
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

  Future<String?> _getMountPoint(String path) async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('df', ['--output=target', path]);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().trim().split('\n');
          if (lines.length > 1) {
            return lines[1].trim();
          }
        }
      }
    } catch (e) {
      debugPrint('Error finding mount point: $e');
    }
    return p.rootPrefix(path);
  }

  Future<String?> _remuxToMkvAndBackup(String currentPath, Video video) async {
    try {
      final String dir = p.dirname(currentPath);
      final String baseName = p.basenameWithoutExtension(currentPath);
      final String newPath = p.join(dir, '$baseName.mkv');

      if (!await _isToolAvailable('mkvmerge')) {
        await LoggerService().error('mkvmerge not found. Cannot remux to MKV.');
        return null;
      }

      debugPrint('[MetadataService] Remuxing to MKV: $currentPath');
      final remuxResult =
          await Process.run('mkvmerge', ['-o', newPath, currentPath]);
      if (remuxResult.exitCode != 0) {
        await LoggerService().error(
          'mkvmerge failed for $currentPath: ${remuxResult.stderr}',
        );
        return null;
      }

      // Backup AVI
      String? mountPoint = await _getMountPoint(currentPath);
      String root = mountPoint ?? p.rootPrefix(currentPath);
      
      final settings = SettingsService();
      String videoBackupDir;
      if (settings.videoBackupPath.isNotEmpty) {
        videoBackupDir = settings.videoBackupPath;
      } else {
        videoBackupDir = p.join(root, 'Converted_Backups');
      }

      try {
        final dirObj = Directory(videoBackupDir);
        if (!await dirObj.exists()) {
          debugPrint('[MetadataService] Creating backup folder: $videoBackupDir');
          await dirObj.create(recursive: true);
        }
        // Verifica finale che la directory esista davvero prima di procedere
        if (!await dirObj.exists()) {
          throw Exception("Directory not created: $videoBackupDir");
        }
      } catch (e) {
        await LoggerService().warning('Failed to create custom backup dir $videoBackupDir, falling back to local: $e');
        // Fallback: create Converted_Backups in the video's directory
        videoBackupDir = p.join(p.dirname(currentPath), 'Converted_Backups');
        final dirObj = Directory(videoBackupDir);
        if (!await dirObj.exists()) {
          await dirObj.create(recursive: true);
        }
      }

      final backupPath = p.join(videoBackupDir, p.basename(currentPath));
      debugPrint('[MetadataService] Moving original file to $backupPath');

      try {
        await File(currentPath).rename(backupPath);
      } catch (e) {
        // Cross-device link error fallback
        await File(currentPath).copy(backupPath);
        await File(currentPath).delete();
      }

      return newPath;
    } catch (e) {
      await LoggerService().error(
        'Error during MKV remuxing for $currentPath',
        e,
      );
      return null;
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

  Future<String?> _updateSingleFileMKVInPlace(
    String path,
    Video video,
    String encodedBy,
    bool preserveTitle,
    String? forcedTitle,
  ) async {
    try {
      final String dir = p.dirname(path);
      final String tagsPath = p.join(
        dir,
        'temp_tags_${DateTime.now().millisecondsSinceEpoch}.xml',
      );
      final title = forcedTitle ?? video.title;

      final xml =
          '''<?xml version="1.0"?>
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

      String dateValue = video.year.trim();
      if (dateValue.length == 4 && RegExp(r'^\d+$').hasMatch(dateValue)) {
        dateValue = '$dateValue-01-01T00:00:00Z';
      }

      final List<String> args = [
        path,
        '--edit',
        'info',
        '--set',
        'title=$title',
        if (dateValue.isNotEmpty) ...[
          '--set',
          'date=$dateValue',
        ],
        '--tags',
        'all:$tagsPath',
      ];

      debugPrint('[MetadataService] Running mkvpropedit with args: $args');
      final process = await Process.start('mkvpropedit', args);

      // Simple timeout implementation for Process
      bool timedOut = false;
      final timeout = const Duration(seconds: 30);
      final timer = Timer(timeout, () {
        timedOut = true;
        process.kill();
        debugPrint('[MetadataService] mkvpropedit TIMEOUT after ${timeout.inSeconds}s');
      });

      final exitCode = await process.exitCode;
      timer.cancel();

      await File(tagsPath).delete();

      if (exitCode == 0 && !timedOut) {
        debugPrint('[MetadataService] mkvpropedit SUCCESS');
        return null;
      }

      if (timedOut) {
        return 'timeout_too_slow';
      }

      final stderr = await process.stderr.transform(utf8.decoder).join();
      final stdout = await process.stdout.transform(utf8.decoder).join();
      String errorMsg = stderr.trim().isNotEmpty ? stderr.trim() : stdout.trim();
      if (errorMsg.isEmpty) {
        errorMsg = 'Exit code: $exitCode';
      }
      errorMsg = errorMsg.replaceAll('\n', ' ').replaceAll('\r', ' ').replaceAll(':', ';');

      debugPrint('[MetadataService] mkvpropedit FAILED: $errorMsg');
      await LoggerService().error(
        'mkvpropedit failed for $path: $errorMsg',
      );
      return errorMsg;
    } catch (e) {
      final error = e.toString().replaceAll('\n', ' ').replaceAll('\r', ' ').replaceAll(':', ';');
      await LoggerService().error('Error in MKV in-place update for $path', e);
      return error;
    }
  }

  Future<String?> _updateSingleFileMP4InPlace(
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

      if (title.isNotEmpty) {
        tags.add('title=${clean(title)}');
      }
      if (video.directors.isNotEmpty) {
        tags.add('artist=${clean(video.directors)}');
      }
      if (video.year.toString().isNotEmpty) {
        tags.add('created=${clean(video.year.toString())}');
      }
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
      final process = await Process.start('MP4Box', args);

      bool timedOut = false;
      final timeout = const Duration(seconds: 30);
      final timer = Timer(timeout, () {
        timedOut = true;
        process.kill();
        debugPrint('[MetadataService] MP4Box TIMEOUT after ${timeout.inSeconds}s');
      });

      final exitCode = await process.exitCode;
      timer.cancel();

      if (exitCode == 0 && !timedOut) {
        debugPrint('[MetadataService] MP4Box SUCCESS');
        return null;
      }

      if (timedOut) {
        return 'timeout_too_slow';
      }

      final stderr = await process.stderr.transform(utf8.decoder).join();
      final stdout = await process.stdout.transform(utf8.decoder).join();
      String errorMsg = stderr.trim().isNotEmpty ? stderr.trim() : stdout.trim();
      if (errorMsg.isEmpty) {
        errorMsg = 'Exit code: $exitCode';
      }
      errorMsg = errorMsg.replaceAll('\n', ' ').replaceAll('\r', ' ').replaceAll(':', ';');

      debugPrint('[MetadataService] MP4Box FAILED: $errorMsg');
      await LoggerService().error('MP4Box failed for $path: $errorMsg');
      return errorMsg;
    } catch (e) {
      final error = e.toString().replaceAll('\n', ' ').replaceAll('\r', ' ').replaceAll(':', ';');
      await LoggerService().error('Error in MP4 in-place update for $path', e);
      return error;
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

  Future<MetadataUpdateResponse> _updateSeriesFiles(
    Video video, {
    bool enforceFullMetadata = false,
    Function(String, String?)? onMethodDecided,
  }) async {
    final dir = Directory(video.path);
    if (!await dir.exists()) {
      return MetadataUpdateResponse(MetadataUpdateResult.failed);
    }

    int updatedCount = 0;
    bool hadError = false;
    String methodUsed = '';

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
              onMethodDecided: onMethodDecided,
            );

            if (result.result == MetadataUpdateResult.updated) {
              updatedCount++;
              methodUsed = result.method;
            }
            if (result.result == MetadataUpdateResult.alreadyInSync) {
              // alreadyInSync
            }
            if (result.result == MetadataUpdateResult.failed) hadError = true;
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning series directory: $e');
      return MetadataUpdateResponse(MetadataUpdateResult.failed);
    }

    if (hadError) return MetadataUpdateResponse(MetadataUpdateResult.failed);
    if (updatedCount > 0) {
      return MetadataUpdateResponse(
        MetadataUpdateResult.updated,
        method: methodUsed,
      );
    }
    return MetadataUpdateResponse(MetadataUpdateResult.alreadyInSync);
  }

  bool _hasOneOf(Map<String, String> tags, List<String> keys) {
    for (final key in keys) {
      if (tags.containsKey(key.toLowerCase()) &&
          tags[key.toLowerCase()]?.isNotEmpty == true) {
        return true;
      }
    }
    return false;
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
