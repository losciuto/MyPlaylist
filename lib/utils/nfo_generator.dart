import 'package:xml/xml.dart';

class NfoGenerator {
  /// Generates a Kodi-compatible NFO XML string from TMDB data map.
  static String generateMovieNfo(Map<String, dynamic> tmdbData) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    
    builder.element('movie', nest: () {
      builder.element('title', nest: tmdbData['title'] ?? '');
      builder.element('originaltitle', nest: tmdbData['original_title'] ?? '');
      
      builder.element('plot', nest: tmdbData['overview'] ?? '');
      builder.element('tagline', nest: tmdbData['tagline'] ?? '');
      
      final releaseDate = tmdbData['release_date'] as String?; // YYYY-MM-DD
      if (releaseDate != null && releaseDate.isNotEmpty) {
        builder.element('premiered', nest: releaseDate);
        builder.element('year', nest: releaseDate.split('-').first);
      }
      
      builder.element('userrating', nest: tmdbData['vote_average']?.toString() ?? '0.0');
      // Kodi standard rating block
      builder.element('rating', attributes: {'name': 'tmdb', 'max': '10', 'default': 'true'}, nest: () {
        builder.element('value', nest: tmdbData['vote_average']?.toString() ?? '0.0');
        builder.element('votes', nest: tmdbData['vote_count']?.toString() ?? '0');
      });

      builder.element('runtime', nest: tmdbData['runtime']?.toString() ?? '');
      
      // Genres
      if (tmdbData['genres'] != null) {
        for (final genre in tmdbData['genres']) {
          builder.element('genre', nest: genre['name'] ?? '');
        }
      }

      // Credits (Cast & Crew)
      final credits = tmdbData['credits'];
      if (credits != null) {
        final cast = credits['cast'] as List?;
        final crew = credits['crew'] as List?;

        // Directors
        if (crew != null) {
           for (final member in crew) {
             if (member['job'] == 'Director') {
               builder.element('director', nest: member['name']);
             }
           }
        }

        // Actors (Top 10)
        if (cast != null) {
          for (final actor in cast.take(10)) {
            builder.element('actor', nest: () {
              builder.element('name', nest: actor['name']);
              builder.element('role', nest: actor['character'] ?? '');
              if (actor['profile_path'] != null) {
                builder.element('thumb', nest: 'https://image.tmdb.org/t/p/w185${actor['profile_path']}');
              }
            });
          }
        }
      }
      
      // Poster & Backdrop (URLs)
      if (tmdbData['poster_path'] != null) {
        builder.element('thumb', attributes: {'aspect': 'poster'}, nest: 'https://image.tmdb.org/t/p/original${tmdbData['poster_path']}');
      }
      if (tmdbData['backdrop_path'] != null) {
        builder.element('fanart', nest: () {
             builder.element('thumb', nest: 'https://image.tmdb.org/t/p/original${tmdbData['backdrop_path']}');
        });
      }
    });

    return builder.buildDocument().toXmlString(pretty: true, indent: '    ');
  }
}
