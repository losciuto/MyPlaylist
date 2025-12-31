import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  final String apiKey;

  TmdbService(this.apiKey);

  /// Search for a movie by query.
  Future<List<Map<String, dynamic>>> searchMovie(String query, {int? year, String language = 'it-IT'}) async {
    if (apiKey.isEmpty) throw Exception('API Key mancante');

    final uri = Uri.parse('$_baseUrl/search/movie').replace(queryParameters: {
      'api_key': apiKey,
      'query': query,
      'language': language,
      if (year != null) 'year': year.toString(),
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['results']);
      } else {
        throw Exception('Errore TMDB: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('TMDB Search Error: $e');
      rethrow;
    }
  }

  /// Get detailed movie info including credits (cast/crew).
  Future<Map<String, dynamic>> getMovieDetails(int id, {String language = 'it-IT'}) async {
    if (apiKey.isEmpty) throw Exception('API Key mancante');

    final uri = Uri.parse('$_baseUrl/movie/$id').replace(queryParameters: {
      'api_key': apiKey,
      'language': language,
      'append_to_response': 'credits,images', // Include actors, crew, and images (logos, etc.)
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Errore TMDB Dettagli: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('TMDB Details Error: $e');
      rethrow;
    }
  }
}
