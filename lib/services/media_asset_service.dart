import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../services/logger_service.dart';

class MediaAssetService {
  final LoggerService _logger = LoggerService();

  /// Downloads a thumbnail if it's a network URL and saves it to a local path.
  /// returns the local path if successful or if it was already local.
  Future<String> downloadThumbnail(String url, String baseDir, String name) async {
    if (url.isEmpty) return '';
    if (!url.startsWith('http')) return url; // Already local

    try {
      final actorsDir = Directory(p.join(baseDir, '.actors'));
      if (!actorsDir.existsSync()) {
        await actorsDir.create(recursive: true);
      }

      // Create a safe filename from the name
      final safeName = name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final extension = p.extension(Uri.parse(url).path);
      final finalExt = extension.isEmpty ? '.jpg' : extension;
      final localPath = p.join(actorsDir.path, '$safeName$finalExt');

      final file = File(localPath);
      if (file.existsSync()) {
        return localPath;
      }

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.warning('Timeout downloading thumbnail for $name after 10s');
          throw Exception('Timeout');
        },
      );
      
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _logger.info('Downloaded thumbnail for $name to $localPath');
        return localPath;
      } else {
        _logger.warning('Failed to download thumbnail for $name: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error downloading thumbnail for $name', e);
    }

    return url; // Fallback to network URL
  }
}
