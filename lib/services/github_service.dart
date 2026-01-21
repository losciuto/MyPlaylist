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
        
        // Find the asset for Linux/AppImage or just take the first one or the html_url
        // For simplicity and to let user choose, we can use the html_url of the release
        // OR we can look for specific assets. Let's use the release page URL for now 
        // as it's safer than guessing the asset structure.
        final String downloadUrl = data['html_url'] ?? '';

        // Clean version string (remove 'v' prefix if present)
        final String remoteVersion = tagName.startsWith('v') 
            ? tagName.substring(1) 
            : tagName;

        if (_isNewerVersion(remoteVersion, AppConfig.appVersion)) {
          return UpdateInfo(
            version: tagName,
            body: body,
            downloadUrl: downloadUrl,
          );
        }
      }
    } catch (e) {
      // Fail silently or log error
      print('Error checking for updates: $e');
    }
    return null;
  }

  bool _isNewerVersion(String remote, String current) {
    try {
      List<int> remoteParts = remote.split('.').map(int.parse).toList();
      List<int> currentParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < remoteParts.length && i < currentParts.length; i++) {
        if (remoteParts[i] > currentParts[i]) return true;
        if (remoteParts[i] < currentParts[i]) return false;
      }
      
      // If we are here, common parts are equal. 
      // If remote has more parts (e.g. 1.0.1 vs 1.0), it's newer
      return remoteParts.length > currentParts.length;
    } catch (e) {
      return false; 
    }
  }
}
