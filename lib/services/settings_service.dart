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
  static const String _keyRemoteServerEnabled = 'remote_server_enabled';
  static const String _keyRemoteServerPort = 'remote_server_port';
  static const String _keyRemoteServerSecret = 'remote_server_secret';
  static const String _keyVlcPort = 'vlc_port';
  static const String _keyServerInterface = 'server_interface';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyTmdbApiKey = 'tmdb_api_key';

  // State
  String _playerPath = '';
  int _defaultPlaylistSize = 20;
  bool _remoteServerEnabled = false;
  int _remoteServerPort = 8080;
  String _remoteServerSecret = 'my_default_secret_key_32chars_long'; // Should be 32 chars for AES-256
  int _vlcPort = 4212;
  String _serverInterface = '0.0.0.0';
  ThemeMode _themeMode = ThemeMode.system;
  String _tmdbApiKey = '';

  bool get initialized => _initialized;
  String get playerPath => _playerPath;
  int get defaultPlaylistSize => _defaultPlaylistSize;
  bool get remoteServerEnabled => _remoteServerEnabled;
  int get remoteServerPort => _remoteServerPort;
  String get remoteServerSecret => _remoteServerSecret;
  int get vlcPort => _vlcPort;
  String get serverInterface => _serverInterface;
  ThemeMode get themeMode => _themeMode;
  String get tmdbApiKey => _tmdbApiKey;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    _playerPath = _prefs.getString(_keyPlayerPath) ?? '';
    _defaultPlaylistSize = _prefs.getInt(_keyDefaultPlaylistSize) ?? 20;
    _remoteServerEnabled = _prefs.getBool(_keyRemoteServerEnabled) ?? false;
    _remoteServerPort = _prefs.getInt(_keyRemoteServerPort) ?? 8080;
    _remoteServerSecret = _prefs.getString(_keyRemoteServerSecret) ?? 'my_default_secret_key_32chars_long';
    _vlcPort = _prefs.getInt(_keyVlcPort) ?? 4212;
    _serverInterface = _prefs.getString(_keyServerInterface) ?? '0.0.0.0';
    _tmdbApiKey = _prefs.getString(_keyTmdbApiKey) ?? '';
    
    final themeIndex = _prefs.getInt(_keyThemeMode);
    if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    
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

  Future<void> setRemoteServerEnabled(bool enabled) async {
    _remoteServerEnabled = enabled;
    await _prefs.setBool(_keyRemoteServerEnabled, enabled);
    notifyListeners();
  }

  Future<void> setRemoteServerPort(int port) async {
    _remoteServerPort = port;
    await _prefs.setInt(_keyRemoteServerPort, port);
    notifyListeners();
  }

  Future<void> setRemoteServerSecret(String secret) async {
    _remoteServerSecret = secret;
    await _prefs.setString(_keyRemoteServerSecret, secret);
    notifyListeners();
  }

  Future<void> setVlcPort(int port) async {
    _vlcPort = port;
    await _prefs.setInt(_keyVlcPort, port);
    notifyListeners();
  }

  Future<void> setServerInterface(String interface) async {
    _serverInterface = interface;
    await _prefs.setString(_keyServerInterface, interface);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(_keyThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> setTmdbApiKey(String key) async {
    _tmdbApiKey = key;
    await _prefs.setString(_keyTmdbApiKey, key);
    notifyListeners();
  }
}
