import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/video.dart';
import '../services/settings_service.dart';

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
    _totalVideoCount = await DatabaseHelper.instance.getVideoCount();
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

  Future<List<String>> generateRandom({int? count, bool launchPlayer = true}) async {
    final limit = count ?? 20;
    // Check if we exhausted the available videos in this session
    if (_proposedVideoIds.length >= _totalVideoCount) {
      _proposedVideoIds.clear();
    }
    
    final videos = await DatabaseHelper.instance.getRandomPlaylist(
      limit, 
      excludeIds: _proposedVideoIds.toList()
    );

    // If we didn't get enough (maybe some were deleted or filtered out), 
    // and we have proposed IDs, clear and try once more.
    if (videos.isEmpty && _proposedVideoIds.isNotEmpty) {
       _proposedVideoIds.clear();
       final retryVideos = await DatabaseHelper.instance.getRandomPlaylist(limit);
       await setPlaylist(retryVideos);
    } else {
       await setPlaylist(videos);
    }

    if (launchPlayer) {
      await playCurrentPlaylist();
    }
    
    return _currentPlaylist.map((v) => v.title).toList();
  }

  Future<List<String>> generateRecentPlaylist({int? count, bool launchPlayer = true}) async {
    final limit = count ?? 20; // Default to 20 if count is not provided
    final videos = await DatabaseHelper.instance.getRecentPlaylist(limit);
    await setPlaylist(videos);
    
    if (launchPlayer) {
      await playCurrentPlaylist();
    }
    
    return _currentPlaylist.map((v) => v.title).toList();
  }

  Future<List<String>> generateFilteredPlaylist({
    List<String>? genres,
    List<String>? years,
    double? minRating,
    List<String>? actors,
    List<String>? directors,
    int? limit,
    bool launchPlayer = true,
  }) async {
    // For filtered, if the pool is too small, we might want to reset proposed IDs too?
    // Let's implement it similar to random but specifically for filtered results.
    
    final videos = await DatabaseHelper.instance.getFilteredPlaylist(
      genres: genres,
      years: years,
      minRating: minRating,
      actors: actors,
      directors: directors,
      limit: limit ?? 20, // Default to 20 if limit is not provided
      excludeIds: _proposedVideoIds.toList()
    );

    if (videos.isEmpty && _proposedVideoIds.isNotEmpty) {
      // Potentially all filtered videos were already proposed.
      // We don't clear everything because other filters might still have unproposed videos,
      // but for this specific filter set, we might need a workaround.
      // For simplicity, if we get nothing, we try again without exclusion.
      final retryVideos = await DatabaseHelper.instance.getFilteredPlaylist(
        genres: genres,
        years: years,
        minRating: minRating,
        actors: actors,
        directors: directors,
        limit: limit ?? 20
      );
      await setPlaylist(retryVideos);
    } else {
      await setPlaylist(videos);
    }

    if (launchPlayer) {
      await playCurrentPlaylist();
    }
    
    return _currentPlaylist.map((v) => v.title).toList();
  }

  Future<void> loadPlaylistState() => _loadPlaylistState();

  Future<void> _loadPlaylistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paths = prefs.getStringList('last_playlist_paths');
      if (paths != null && paths.isNotEmpty) {
        final videos = await DatabaseHelper.instance.getVideosByPaths(paths);
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

  Future<String?> exportPlaylist() async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Esporta Playlist',
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
    // Kill existing process if alive
    await stopPlayer();

    try {
      List<String> args = [playlistPath];
      final isVlc = playerPath.toLowerCase().contains('vlc');
      
      if (isVlc) {
        // KILL ALL EXISTING VLC INSTANCES
        try {
          if (Platform.isLinux) {
            await Process.run('pkill', ['-x', 'vlc']);
          } else if (Platform.isWindows) {
            await Process.run('taskkill', ['/IM', 'vlc.exe', '/F']);
          }
          // Give system a moment to clean up resources
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('Error killing existing VLC instances: $e');
        }

        // Enable RC interface on 0.0.0.0:vlcPort
        args = ['--extraintf', 'rc', '--rc-host', '0.0.0.0:${settings.vlcPort}', playlistPath];
      }

      debugPrint('Starting player: $playerPath with args: $args');
      _playerProcess = await Process.start(playerPath, args);
      
      // Optional: Listen to exit to clear variable, though not strictly needed if we just overwrite
      _playerProcess!.exitCode.then((_) {
        _playerProcess = null;
      });
      
    } catch (e) {
      debugPrint('Error launching player: $e');
      rethrow;
    }
  }
}
