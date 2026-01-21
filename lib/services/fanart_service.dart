import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FanartTvService {
  static const String _baseUrl = 'https://webservice.fanart.tv/v3';
  // Public Personal API Key for testing or default use-case if allowed by their ToS.
  // Ideally users should provide their own.
  final String? apiKey;

  FanartTvService(this.apiKey);

  bool get hasKey => apiKey != null && apiKey!.isNotEmpty;

  /// Get movie images by TMDB ID
  Future<Map<String, dynamic>?> getMovieImages(int tmdbId) async {
    if (!hasKey) return null;

    final uri = Uri.parse('$_baseUrl/movies/$tmdbId').replace(queryParameters: {
      'api_key': apiKey,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // Not found on Fanart.tv
        return null;
      } else {
        debugPrint('Fanart.tv Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Fanart.tv Connection Error: $e');
      return null;
    }
  }

  /// Get TV Show images by TVDB ID (Fanart uses TVDB IDs largely, but supports TMDB for mapping sometimes)
  /// actually Fanart v3 docs say: "get /movies/{id} where id is tmdb_id or imdb_id"
  /// for tv: "get /tv/{id} where id is thetvdb_id"
  /// This implies we might need the TVDB ID from TMDB first.
  /// Luckily TMDB 'external_ids' endpoint provides this.
  Future<Map<String, dynamic>?> getTvShowImages(int tvdbId) async {
    if (!hasKey) return null;

    final uri = Uri.parse('$_baseUrl/tv/$tvdbId').replace(queryParameters: {
      'api_key': apiKey,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        debugPrint('Fanart.tv TV Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Fanart.tv TV Connection Error: $e');
      return null;
    }
  }
}
