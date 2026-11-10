import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'settings_service.dart';
import 'logger_service.dart';

class VlcKillTimerService with ChangeNotifier {
  VlcKillTimerService._internal() {
    _timer = Timer.periodic(const Duration(minutes: 1), _checkTimer);
  }

  factory VlcKillTimerService() => _instance;
  static final VlcKillTimerService _instance = VlcKillTimerService._internal();

  final LoggerService _logger = LoggerService();
  Timer? _timer;
  SettingsService? _settings;
  bool _hasKilledToday = false;
  DateTime? _lastKillDate;

  void initialize(SettingsService settings) {
    _settings = settings;
    settings.addListener(_onSettingsChanged);
    _checkTimer(null);
  }

  void _onSettingsChanged() {
    if (_settings != null) {
      _hasKilledToday = false;
      _lastKillDate = null;
      _checkTimer(null);
    }
  }

  void _checkTimer(Timer? timer) {
    if (_settings == null) return;
    if (!_settings!.vlcKillTimerEnabled) {
      _hasKilledToday = false;
      _lastKillDate = null;
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastKillDate == today && _hasKilledToday) {
      return;
    }

    final targetTime = _settings!.vlcKillTimerTime;
    final parts = targetTime.split(':');
    if (parts.length != 2) return;

    final targetHour = int.tryParse(parts[0]);
    final targetMinute = int.tryParse(parts[1]);
    if (targetHour == null || targetMinute == null) return;

    final targetDateTime = DateTime(now.year, now.month, now.day, targetHour, targetMinute);

    if (now.isAfter(targetDateTime) || now.isAtSameMomentAs(targetDateTime)) {
      _logger.debug('VLC Kill Timer: Time reached ($targetTime). Killing VLC...');
      _killVlc();
      _hasKilledToday = true;
      _lastKillDate = today;
    }
  }

  Future<void> _killVlc() async {
    try {
      if (Platform.isLinux) {
        await Process.run('pkill', ['-x', 'vlc']);
      } else if (Platform.isWindows) {
        await Process.run('taskkill', ['/IM', 'vlc.exe', '/F']);
      } else if (Platform.isMacOS) {
        await Process.run('pkill', ['-x', 'vlc']);
      }
      _logger.debug('VLC Kill Timer: VLC terminated successfully');
    } on Exception catch (e) {
      _logger.debug('VLC Kill Timer: Error killing VLC: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _settings?.removeListener(_onSettingsChanged);
    super.dispose();
  }
}