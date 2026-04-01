import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/player_config.dart';
import '../models/filter_settings.dart';

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
  static const String _keyPlayerConfig = 'player_config';
  static const String _keyDefaultPlaylistSize = 'default_playlist_size';
  static const String _keyRemoteServerEnabled = 'remote_server_enabled';
  static const String _keyRemoteServerPort = 'remote_server_port';
  static const String _keyRemoteServerSecret = 'remote_server_secret';
  static const String _keyVlcPort = 'vlc_port';
  static const String _keyServerInterface = 'server_interface';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyTmdbApiKey = 'tmdb_api_key';
  static const String _keyAutoSyncEnabled = 'auto_sync_enabled';
  static const String _keyWatchedDirectories = 'watched_directories';
  static const String _keyAutoSyncNfoOnEdit = 'auto_sync_nfo_on_edit';
  static const String _keyIgnoredDuplicateKeys = 'ignored_duplicate_keys';
  static const String _keyFastMetadataEngineEnabled =
      'fast_metadata_engine_enabled';
  static const String _keyAutoConvertToMkv = 'auto_convert_to_mkv';
  static const String _keyVideoBackupPath = 'video_backup_path';
  static const String _keyExcludeConvertedBackupFromScan =
      'exclude_converted_backup_from_scan';
  static const String _keyLastFilterSettings = 'last_filter_settings';

  // State
  String _playerPath = '';
  PlayerConfig? _playerConfig;
  int _defaultPlaylistSize = 20;
  bool _remoteServerEnabled = true;
  int _remoteServerPort = 8080;
  String _remoteServerSecret =
      'my_default_secret_key_32chars_long'; // Should be 32 chars for AES-256
  int _vlcPort = 4242;
  String _serverInterface = '0.0.0.0';
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('it');
  String _tmdbApiKey = '';
  bool _autoSyncEnabled = false;
  List<String> _watchedDirectories = [];
  bool _autoSyncNfoOnEdit = false;
  Set<String> _ignoredDuplicateKeys = {};
  bool _fastMetadataEngineEnabled = true;
  bool _autoConvertToMkv = false;
  String _videoBackupPath = '';
  bool _excludeConvertedBackupFromScan = true;
  FilterSettings? _lastFilterSettings;

  bool get initialized => _initialized;
  String get playerPath => _playerPath;
  PlayerConfig? get playerConfig => _playerConfig;
  int get defaultPlaylistSize => _defaultPlaylistSize;
  bool get remoteServerEnabled => _remoteServerEnabled;
  int get remoteServerPort => _remoteServerPort;
  String get remoteServerSecret => _remoteServerSecret;
  int get vlcPort => _vlcPort;
  String get serverInterface => _serverInterface;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get tmdbApiKey => _tmdbApiKey;
  bool get autoSyncEnabled => _autoSyncEnabled;
  List<String> get watchedDirectories => List.unmodifiable(_watchedDirectories);
  bool get autoSyncNfoOnEdit => _autoSyncNfoOnEdit;
  Set<String> get ignoredDuplicateKeys =>
      Set.unmodifiable(_ignoredDuplicateKeys);
  bool get fastMetadataEngineEnabled => _fastMetadataEngineEnabled;
  bool get autoConvertToMkv => _autoConvertToMkv;
  String get videoBackupPath => _videoBackupPath;
  bool get excludeConvertedBackupFromScan => _excludeConvertedBackupFromScan;
  FilterSettings? get lastFilterSettings => _lastFilterSettings;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    _playerPath = _prefs.getString(_keyPlayerPath) ?? '';

    // Load player config (new format)
    final playerConfigJson = _prefs.getString(_keyPlayerConfig);
    if (playerConfigJson != null) {
      try {
        _playerConfig = PlayerConfig.fromJson(json.decode(playerConfigJson));
      } catch (e) {
        // Invalid config, will use legacy playerPath
      }
    }

    // Backward compatibility: if no config but playerPath exists, create custom config
    if (_playerConfig == null && _playerPath.isNotEmpty) {
      _playerConfig = PlayerConfig.custom(_playerPath);
    }

    _defaultPlaylistSize = _prefs.getInt(_keyDefaultPlaylistSize) ?? 20;
    _remoteServerEnabled = _prefs.getBool(_keyRemoteServerEnabled) ?? true;
    _remoteServerPort = _prefs.getInt(_keyRemoteServerPort) ?? 8080;
    _remoteServerSecret =
        _prefs.getString(_keyRemoteServerSecret) ??
        'my_default_secret_key_32chars_long';
    _vlcPort = _prefs.getInt(_keyVlcPort) ?? 4242;
    _serverInterface = _prefs.getString(_keyServerInterface) ?? '0.0.0.0';
    _tmdbApiKey = _prefs.getString(_keyTmdbApiKey) ?? '';
    _fanartApiKey = _prefs.getString(_keyFanartApiKey) ?? '';

    final themeIndex = _prefs.getInt(_keyThemeMode);
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    final languageCode = _prefs.getString('language_code') ?? 'it';
    _locale = Locale(languageCode);

    _autoSyncEnabled = _prefs.getBool(_keyAutoSyncEnabled) ?? false;
    _watchedDirectories = _prefs.getStringList(_keyWatchedDirectories) ?? [];
    _autoSyncNfoOnEdit = _prefs.getBool(_keyAutoSyncNfoOnEdit) ?? false;
    _ignoredDuplicateKeys = Set.from(
      _prefs.getStringList(_keyIgnoredDuplicateKeys) ?? [],
    );
    _fastMetadataEngineEnabled =
        _prefs.getBool(_keyFastMetadataEngineEnabled) ?? true;
    // Caricamento conversione MKV (con fallback per vecchia chiave AVI)
    _autoConvertToMkv =
        _prefs.getBool(_keyAutoConvertToMkv) ??
        _prefs.getBool('auto_convert_avi_to_mkv') ??
        false;
    _videoBackupPath =
        _prefs.getString(_keyVideoBackupPath) ??
        _prefs.getString('avi_backup_path') ??
        '';
    _excludeConvertedBackupFromScan =
        _prefs.getBool(_keyExcludeConvertedBackupFromScan) ?? true;

    final filterJson = _prefs.getString(_keyLastFilterSettings);
    if (filterJson != null) {
      try {
        _lastFilterSettings = FilterSettings.fromJson(json.decode(filterJson));
      } catch (e) {
        debugPrint('Error loading last filter settings: $e');
      }
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> setPlayerPath(String path) async {
    _playerPath = path;
    await _prefs.setString(_keyPlayerPath, path);
    // Also update config for backward compatibility
    _playerConfig = PlayerConfig.custom(path);
    await _prefs.setString(
      _keyPlayerConfig,
      json.encode(_playerConfig!.toJson()),
    );
    notifyListeners();
  }

  Future<void> setPlayerConfig(PlayerConfig config) async {
    _playerConfig = config;
    _playerPath = config.getExecutablePath(); // For backward compatibility
    await _prefs.setString(_keyPlayerConfig, json.encode(config.toJson()));
    await _prefs.setString(_keyPlayerPath, _playerPath);
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

  Future<void> setLocale(Locale cx) async {
    if (_locale == cx) return;
    _locale = cx;
    await _prefs.setString('language_code', cx.languageCode);
    notifyListeners();
  }

  Future<void> setTmdbApiKey(String key) async {
    _tmdbApiKey = key;
    await _prefs.setString(_keyTmdbApiKey, key);
    notifyListeners();
  }

  static const String _keyFanartApiKey = 'fanart_api_key';
  String _fanartApiKey = '';
  String get fanartApiKey => _fanartApiKey;

  Future<void> setFanartApiKey(String key) async {
    _fanartApiKey = key;
    await _prefs.setString(_keyFanartApiKey, key);
    notifyListeners();
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    _autoSyncEnabled = enabled;
    await _prefs.setBool(_keyAutoSyncEnabled, enabled);
    notifyListeners();
  }

  Future<void> addWatchedDirectory(String path) async {
    if (!_watchedDirectories.contains(path)) {
      _watchedDirectories.add(path);
      await _prefs.setStringList(_keyWatchedDirectories, _watchedDirectories);
      notifyListeners();
    }
  }

  Future<void> removeWatchedDirectory(String path) async {
    if (_watchedDirectories.contains(path)) {
      _watchedDirectories.remove(path);
      await _prefs.setStringList(_keyWatchedDirectories, _watchedDirectories);
      notifyListeners();
    }
  }

  Future<void> setWatchedDirectories(List<String> paths) async {
    _watchedDirectories = List.from(paths);
    await _prefs.setStringList(_keyWatchedDirectories, _watchedDirectories);
    notifyListeners();
  }

  Future<void> setAutoSyncNfoOnEdit(bool enabled) async {
    _autoSyncNfoOnEdit = enabled;
    await _prefs.setBool(_keyAutoSyncNfoOnEdit, enabled);
    notifyListeners();
  }

  Future<void> addIgnoredDuplicateKey(String key) async {
    _ignoredDuplicateKeys.add(key);
    await _prefs.setStringList(
      _keyIgnoredDuplicateKeys,
      _ignoredDuplicateKeys.toList(),
    );
    notifyListeners();
  }

  Future<void> removeIgnoredDuplicateKey(String key) async {
    _ignoredDuplicateKeys.remove(key);
    await _prefs.setStringList(
      _keyIgnoredDuplicateKeys,
      _ignoredDuplicateKeys.toList(),
    );
    notifyListeners();
  }

  Future<void> clearIgnoredDuplicateKeys() async {
    _ignoredDuplicateKeys.clear();
    await _prefs.remove(_keyIgnoredDuplicateKeys);
    notifyListeners();
  }

  Future<void> setFastMetadataEngineEnabled(bool enabled) async {
    _fastMetadataEngineEnabled = enabled;
    await _prefs.setBool(_keyFastMetadataEngineEnabled, enabled);
    notifyListeners();
  }

  Future<void> setAutoConvertToMkv(bool enabled) async {
    _autoConvertToMkv = enabled;
    await _prefs.setBool(_keyAutoConvertToMkv, enabled);
    notifyListeners();
  }

  Future<void> setVideoBackupPath(String path) async {
    _videoBackupPath = path;
    await _prefs.setString(_keyVideoBackupPath, path);
    notifyListeners();
  }

  Future<void> setExcludeConvertedBackupFromScan(bool value) async {
    _excludeConvertedBackupFromScan = value;
    await _prefs.setBool(_keyExcludeConvertedBackupFromScan, value);
    notifyListeners();
  }

  Future<void> setLastFilterSettings(FilterSettings? settings) async {
    _lastFilterSettings = settings;
    if (settings == null) {
      await _prefs.remove(_keyLastFilterSettings);
    } else {
      await _prefs.setString(
        _keyLastFilterSettings,
        json.encode(settings.toJson()),
      );
    }
    notifyListeners();
  }
}
