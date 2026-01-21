import 'dart:io';

enum PlayerPreset {
  vlc,
  mpv,
  mpcHc,
  custom,
}

class PlayerConfig {
  final PlayerPreset preset;
  final String name;
  final String? executablePath;
  final List<String> playlistArgs;
  final bool supportsRemoteControl;

  const PlayerConfig({
    required this.preset,
    required this.name,
    this.executablePath,
    required this.playlistArgs,
    this.supportsRemoteControl = false,
  });

  // VLC preset
  static PlayerConfig vlc([String? customPath]) {
    return PlayerConfig(
      preset: PlayerPreset.vlc,
      name: 'VLC Media Player',
      executablePath: customPath,
      playlistArgs: ['--started-from-file', '--playlist-enqueue'],
      supportsRemoteControl: true,
    );
  }

  // mpv preset
  static PlayerConfig mpv([String? customPath]) {
    return PlayerConfig(
      preset: PlayerPreset.mpv,
      name: 'mpv',
      executablePath: customPath,
      playlistArgs: ['--playlist'],
      supportsRemoteControl: false,
    );
  }

  // MPC-HC preset (Windows only)
  static PlayerConfig mpcHc([String? customPath]) {
    return PlayerConfig(
      preset: PlayerPreset.mpcHc,
      name: 'MPC-HC',
      executablePath: customPath,
      playlistArgs: ['/play'],
      supportsRemoteControl: false,
    );
  }

  // Custom player
  static PlayerConfig custom(String path, {String? name}) {
    return PlayerConfig(
      preset: PlayerPreset.custom,
      name: name ?? 'Custom Player',
      executablePath: path,
      playlistArgs: [],
      supportsRemoteControl: false,
    );
  }

  // Auto-detect common players
  static Future<PlayerConfig?> autoDetect() async {
    final detectionPaths = _getDetectionPaths();
    
    for (final entry in detectionPaths.entries) {
      for (final path in entry.value) {
        if (await File(path).exists()) {
          switch (entry.key) {
            case PlayerPreset.vlc:
              return vlc(path);
            case PlayerPreset.mpv:
              return mpv(path);
            case PlayerPreset.mpcHc:
              return mpcHc(path);
            default:
              break;
          }
        }
      }
    }
    return null;
  }

  static Map<PlayerPreset, List<String>> _getDetectionPaths() {
    if (Platform.isLinux) {
      return {
        PlayerPreset.vlc: [
          '/usr/bin/vlc',
          '/snap/bin/vlc',
          '/usr/local/bin/vlc',
        ],
        PlayerPreset.mpv: [
          '/usr/bin/mpv',
          '/usr/local/bin/mpv',
          '/snap/bin/mpv',
        ],
      };
    } else if (Platform.isWindows) {
      return {
        PlayerPreset.vlc: [
          r'C:\Program Files\VideoLAN\VLC\vlc.exe',
          r'C:\Program Files (x86)\VideoLAN\VLC\vlc.exe',
        ],
        PlayerPreset.mpv: [
          r'C:\Program Files\mpv\mpv.exe',
          r'C:\mpv\mpv.exe',
        ],
        PlayerPreset.mpcHc: [
          r'C:\Program Files\MPC-HC\mpc-hc64.exe',
          r'C:\Program Files (x86)\MPC-HC\mpc-hc.exe',
        ],
      };
    } else if (Platform.isMacOS) {
      return {
        PlayerPreset.vlc: [
          '/Applications/VLC.app/Contents/MacOS/VLC',
        ],
        PlayerPreset.mpv: [
          '/usr/local/bin/mpv',
          '/opt/homebrew/bin/mpv',
        ],
      };
    }
    return {};
  }

  String getExecutablePath() {
    if (executablePath != null && executablePath!.isNotEmpty) {
      return executablePath!;
    }
    // Fallback to preset name for PATH lookup
    return name.toLowerCase().replaceAll(' ', '-');
  }

  Map<String, dynamic> toJson() {
    return {
      'preset': preset.index,
      'name': name,
      'executablePath': executablePath,
      'playlistArgs': playlistArgs,
      'supportsRemoteControl': supportsRemoteControl,
    };
  }

  factory PlayerConfig.fromJson(Map<String, dynamic> json) {
    final preset = PlayerPreset.values[json['preset'] as int];
    return PlayerConfig(
      preset: preset,
      name: json['name'] as String,
      executablePath: json['executablePath'] as String?,
      playlistArgs: List<String>.from(json['playlistArgs'] as List),
      supportsRemoteControl: json['supportsRemoteControl'] as bool? ?? false,
    );
  }
}
