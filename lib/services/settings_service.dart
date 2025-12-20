import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() {
    return _instance;
  }

  SettingsService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Keys
  static const String _keyPlayerPath = 'player_path';
  static const String _keyDefaultPlaylistSize = 'default_playlist_size';

  // State
  String _playerPath = '';
  int _defaultPlaylistSize = 20;

  bool get initialized => _initialized;
  String get playerPath => _playerPath;
  int get defaultPlaylistSize => _defaultPlaylistSize;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    _playerPath = _prefs.getString(_keyPlayerPath) ?? '';
    _defaultPlaylistSize = _prefs.getInt(_keyDefaultPlaylistSize) ?? 20;
    
    _initialized = true;
    notifyListeners();
  }

  Future<void> setPlayerPath(String path) async {
    _playerPath = path;
    await _prefs.setString(_keyPlayerPath, path);
    notifyListeners();
  }

  Future<void> setDefaultPlaylistSize(int size) async {
    _defaultPlaylistSize = size;
    await _prefs.setInt(_keyDefaultPlaylistSize, size);
    notifyListeners();
  }
}
