import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String version;
  final String body;
  final String downloadUrl;

  UpdateInfo({
    required this.version,
    required this.body,
    required this.downloadUrl,
  });
}

class GitHubService {
  static const String _releasesUrl =
      'https://api.github.com/repos/losciuto/MyPlaylist/releases/latest';

  Future<UpdateInfo?> checkForUpdates() async {
    try {
      // Ottieni la versione reale dell'app dalla piattaforma
      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final response = await http
          .get(Uri.parse(_releasesUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String tagName = data['tag_name'] ?? '';
        final String body = data['body'] ?? '';

        // Default download URL is the release page
        String downloadUrl = data['html_url'] ?? '';

        // Cerchiamo un asset specifico per Linux (.AppImage o .deb)
        final List<dynamic>? assets = data['assets'];
        if (assets != null && assets.isNotEmpty) {
          for (final asset in assets) {
            final String name = asset['name']?.toString().toLowerCase() ?? '';
            final String browserDownloadUrl =
                asset['browser_download_url'] ?? '';

            if (browserDownloadUrl.isNotEmpty &&
                (name.endsWith('.appimage') ||
                    name.endsWith('.deb') ||
                    name.endsWith('.tar.gz'))) {
              downloadUrl = browserDownloadUrl;
              break;
            }
          }
        }

        // Estrae il numero di versione (puro) dal tag (es: v3.12.0 -> 3.12.0)
        final String remoteVersion = _cleanVersion(tagName);
        final String localVersion = _cleanVersion(currentVersion);

        if (_isNewerVersion(remoteVersion, localVersion)) {
          return UpdateInfo(
            version: tagName,
            body: body,
            downloadUrl: downloadUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('[GitHubService] Error checking for updates: $e');
    }
    return null;
  }

  String _cleanVersion(String input) {
    // Rimuove la 'v' iniziale e caratteri non numerici/punti
    final RegExp regExp = RegExp(r'[0-9]+\.[0-9]+(\.[0-9]+)?');
    final match = regExp.firstMatch(input);
    return match?.group(0) ?? input;
  }

  bool _isNewerVersion(String remote, String current) {
    try {
      List<int> remoteParts = remote
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      List<int> currentParts = current
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      for (int i = 0; i < 3; i++) {
        final r = remoteParts.length > i ? remoteParts[i] : 0;
        final c = currentParts.length > i ? currentParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
