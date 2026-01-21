import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

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
      final response = await http.get(Uri.parse(_releasesUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String tagName = data['tag_name'] ?? '';
        final String body = data['body'] ?? '';
        
        // Default download URL is the release page
        String downloadUrl = data['html_url'] ?? '';
        
        // Try to find a direct download link for Linux (.AppImage or .deb)
        final List<dynamic>? assets = data['assets'];
        if (assets != null && assets.isNotEmpty) {
          for (final asset in assets) {
            final String name = asset['name']?.toString().toLowerCase() ?? '';
            final String browserDownloadUrl = asset['browser_download_url'] ?? '';
            
            if (browserDownloadUrl.isNotEmpty && 
                (name.endsWith('.appimage') || name.endsWith('.deb') || name.endsWith('.tar.gz'))) {
              downloadUrl = browserDownloadUrl;
              break; // Take the first matching Linux asset
            }
          }
        }

        // Clean version string: take only digits and dots
        final String remoteVersion = _extractVersion(tagName);
        final String currentVersion = _extractVersion(AppConfig.appVersion);

        if (_isNewerVersion(remoteVersion, currentVersion)) {
          return UpdateInfo(
            version: tagName,
            body: body,
            downloadUrl: downloadUrl,
          );
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
    return null;
  }

  String _extractVersion(String input) {
    // Keep only numbers and dots
    final RegExp regExp = RegExp(r'[0-9]+\.[0-9]+(\.[0-9]+)?');
    final match = regExp.firstMatch(input);
    return match?.group(0) ?? input;
  }

  bool _isNewerVersion(String remote, String current) {
    try {
      List<int> remoteParts = remote.split('.').map(int.parse).toList();
      List<int> currentParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < remoteParts.length && i < currentParts.length; i++) {
        if (remoteParts[i] > currentParts[i]) return true;
        if (remoteParts[i] < currentParts[i]) return false;
      }
      
      return remoteParts.length > currentParts.length;
    } catch (e) {
      return false; 
    }
  }
}
