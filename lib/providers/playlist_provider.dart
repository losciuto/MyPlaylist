import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart' as db;
import '../models/video.dart';
import '../services/settings_service.dart';
import '../models/player_config.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Video> _currentPlaylist = [];
  int _totalVideoCount = 0;
  String? _lastTempPlaylistPath;
  final Set<int> _proposedVideoIds = {};

  List<Video> get playlist => _currentPlaylist;
  int get totalVideoCount => _totalVideoCount;
  int get proposedVideoCount => _proposedVideoIds.length;
  String? get lastTempPlaylistPath => _lastTempPlaylistPath;
  bool get hasPlaylist => _currentPlaylist.isNotEmpty;

  PlaylistProvider() {
    _loadPlaylistState();
    updateVideoCount();
  }

  Future<void> updateVideoCount() async {
    _totalVideoCount = await db.AppDatabase.instance.getVideoCount();
    notifyListeners();
  }

  Future<void> setPlaylist(List<Video> videos) async {
    _currentPlaylist = videos;
    // Track proposed IDs for this session
    for (var v in videos) {
      if (v.id != null) {
        _proposedVideoIds.add(v.id!);
      }
    }
    notifyListeners();
    _savePlaylistState();
  }

  void resetProposedVideos() {
    _proposedVideoIds.clear();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> generateRandom({int? count, bool launchPlayer = true}) async {
    final limit = count ?? 20;
    // Check if we exhausted the available videos in this session
    if (_proposedVideoIds.length >= _totalVideoCount) {
      _proposedVideoIds.clear();
    }
    
    final videos = await db.AppDatabase.instance.getRandomPlaylist(
      limit, 
      excludeIds: _proposedVideoIds.toList()
    );

    // If we didn't get enough (maybe some were deleted or filtered out), 
    // and we have proposed IDs, clear and try once more.
    if (videos.isEmpty && _proposedVideoIds.isNotEmpty) {
       _proposedVideoIds.clear();
       final retryVideos = await db.AppDatabase.instance.getRandomPlaylist(limit);
       await setPlaylist(retryVideos);
    } else {
       await setPlaylist(videos);
    }

    if (launchPlayer) {
      await playCurrentPlaylist();
    }
    
    return _currentPlaylist.map((v) => v.toMap()).toList();
  }

  Future<List<Map<String, dynamic>>> generateRecentPlaylist({int? count, bool launchPlayer = true}) async {
    final limit = count ?? 20; // Default to 20 if count is not provided
    final videos = await db.AppDatabase.instance.getRecentPlaylist(limit);
    await setPlaylist(videos);
    
    if (launchPlayer) {
      await playCurrentPlaylist();
    }
    
    return _currentPlaylist.map((v) => v.toMap()).toList();
  }

  Future<List<Map<String, dynamic>>> generateFilteredPlaylist({
    List<String>? genres,
    List<String>? years,
    double? minRating,
    List<String>? actors,
    List<String>? directors,
    List<String>? excludedGenres,
    List<String>? excludedYears,
    List<String>? excludedActors,
    List<String>? excludedDirectors,
    List<String>? sagas,
    List<String>? excludedSagas,
    int? limit,
    bool launchPlayer = true,
  }) async {
    // For filtered, if the pool is too small, we might want to reset proposed IDs too?
    // Let's implement it similar to random but specifically for filtered results.
    
    final videos = await db.AppDatabase.instance.getFilteredPlaylist(
      genres: genres,
      years: years,
      minRating: minRating,
      actors: actors,
      directors: directors,
      excludedGenres: excludedGenres,
      excludedYears: excludedYears,
      excludedActors: excludedActors,
      excludedDirectors: excludedDirectors,
      sagas: sagas,
      excludedSagas: excludedSagas,
      limit: limit ?? 20,
      excludeIds: _proposedVideoIds.toList()
    );

    if (videos.isEmpty && _proposedVideoIds.isNotEmpty) {
      // Potentially all filtered videos were already proposed.
      // We don't clear everything because other filters might still have unproposed videos,
      // but for this specific filter set, we might need a workaround.
      // For simplicity, if we get nothing, we try again without exclusion.
      final retryVideos = await db.AppDatabase.instance.getFilteredPlaylist(
        genres: genres,
        years: years,
        minRating: minRating,
        actors: actors,
        directors: directors,
        excludedGenres: excludedGenres,
        excludedYears: excludedYears,
        excludedActors: excludedActors,
        excludedDirectors: excludedDirectors,
        sagas: sagas,
        excludedSagas: excludedSagas,
        limit: limit ?? 20
      );
      await setPlaylist(retryVideos);
    } else {
      await setPlaylist(videos);
    }

    if (launchPlayer) {
      await playCurrentPlaylist();
    }
    
    return _currentPlaylist.map((v) => v.toMap()).toList();
  }

  Future<void> loadPlaylistState() => _loadPlaylistState();

  Future<void> _loadPlaylistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paths = prefs.getStringList('last_playlist_paths');
      if (paths != null && paths.isNotEmpty) {
        final videos = await db.AppDatabase.instance.getVideosByPaths(paths);
        _currentPlaylist = videos;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading playlist state: $e');
    }
  }

  Future<void> _savePlaylistState() async {
    try {
       final prefs = await SharedPreferences.getInstance();
       final paths = _currentPlaylist.map((v) => v.path).toList();
       await prefs.setStringList('last_playlist_paths', paths);
    } catch (e) {
       debugPrint('Error saving playlist state: $e');
    }
  }

  Future<String?> exportPlaylist(String dialogTitle) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: 'playlist.m3u',
      allowedExtensions: ['m3u'],
      type: FileType.custom,
    );

    if (outputFile != null) {
      final file = File(outputFile);
      final buffer = StringBuffer();
      buffer.writeln('#EXTM3U');
      for (final v in _currentPlaylist) {
        buffer.writeln('#EXTINF:-1,${v.title}');
        buffer.writeln(v.path);
      }
      await file.writeAsString(buffer.toString());
      return outputFile;
    }
    return null;
  }

  Future<String> createTempPlaylistFile() async {
    final tempDir = await getTemporaryDirectory();
    final playlistFile = File(p.join(tempDir.path, 'playlist.m3u'));
    
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');
    for (final v in _currentPlaylist) {
      buffer.writeln('#EXTINF:-1,${v.title}');
      buffer.writeln(v.path);
    }
    await playlistFile.writeAsString(buffer.toString());
    
    notifyListeners();
    return playlistFile.path;
  }
  
  Future<void> playCurrentPlaylist() async {
    final settings = SettingsService();
    final path = await createTempPlaylistFile();
    await launchPlayer(settings.playerPath, path);
  }

  Future<void> playSingleVideo(Video video) async {
    final settings = SettingsService();
    final tempDir = await getTemporaryDirectory();
    final playlistFile = File(p.join(tempDir.path, 'single_video.m3u'));
    
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');
    buffer.writeln('#EXTINF:-1,${video.title}');
    buffer.writeln(video.path);
    await playlistFile.writeAsString(buffer.toString());
    
    await launchPlayer(settings.playerPath, playlistFile.path);
  }

  Process? _playerProcess;

  Future<void> stopPlayer() async {
    if (_playerProcess != null) {
      debugPrint('Stopping player process...');
      _playerProcess!.kill(ProcessSignal.sigterm);
      _playerProcess = null;
    } else {
      // Fallback: prova a chiudere VLC direttamente se il riferimento è perso
      try {
        if (Platform.isLinux) {
          await Process.run('pkill', ['-x', 'vlc']);
        } else if (Platform.isWindows) {
          await Process.run('taskkill', ['/IM', 'vlc.exe', '/F']);
        }
      } catch (e) {
        debugPrint('Error in stopPlayer fallback: $e');
      }
    }
    // Small delay to allow OS to release port if needed (VLC RC port)
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> launchPlayer(String playerPath, String playlistPath) async {
    final settings = SettingsService();
    await stopPlayer();

    try {
      // Get player config (with backward compatibility)
      final config = settings.playerConfig ?? PlayerConfig.custom(playerPath);
      final execPath = config.getExecutablePath();
      
      // Special VLC handling (kill existing + RC interface)
      final isVlc = config.preset == PlayerPreset.vlc || execPath.toLowerCase().contains('vlc');
      
      if (isVlc) {
        try {
          if (Platform.isLinux) {
            await Process.run('pkill', ['-x', 'vlc']);
          } else if (Platform.isWindows) {
            await Process.run('taskkill', ['/IM', 'vlc.exe', '/F']);
          }
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('Error killing existing VLC instances: $e');
        }
      }

      // Build args
      List<String> args;
      if (isVlc) {
        args = ['--extraintf', 'rc', '--rc-host', '0.0.0.0:${settings.vlcPort}', playlistPath];
      } else {
        args = List<String>.from(config.playlistArgs);
        if (args.isEmpty) args = [playlistPath];
        else args.add(playlistPath);
      }

      debugPrint('Starting player: ${config.name} ($execPath) with args: $args');
      _playerProcess = await Process.start(execPath, args);
      
      _playerProcess!.exitCode.then((_) {
        _playerProcess = null;
      });
      
    } catch (e) {
      debugPrint('Error launching player: $e');
      rethrow;
    }
  }
}
