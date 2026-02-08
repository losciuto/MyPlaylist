import 'package:xml/xml.dart';
import '../models/video.dart' as model;

class NfoGenerator {
  /// Generates a Kodi-compatible NFO XML string from the application's Video model.
  static String generateFromVideo(model.Video video) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');

    builder.element('movie', nest: () {
      builder.element('title', nest: video.title);
      builder.element('plot', nest: video.plot);
      builder.element('year', nest: video.year);
      builder.element('runtime', nest: video.duration);
      
      // Rating block
      builder.element('rating', attributes: {'name': 'app', 'max': '10', 'default': 'true'}, nest: () {
        builder.element('value', nest: video.rating.toString());
      });

      // Genres
      if (video.genres.isNotEmpty) {
        for (final genre in video.genres.split(',')) {
          final cleanGenre = genre.trim();
          if (cleanGenre.isNotEmpty) {
            builder.element('genre', nest: cleanGenre);
          }
        }
      }

      // Directors
      final directorNames = video.directors.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final directorThumbs = video.directorThumbs.split('|').map((e) => e.trim()).toList();
      for (int i = 0; i < directorNames.length; i++) {
        builder.element('director', nest: () {
          builder.element('name', nest: directorNames[i]);
          if (i < directorThumbs.length && directorThumbs[i].isNotEmpty) {
            builder.element('thumb', nest: directorThumbs[i]);
          }
        });
      }

      // Actors
      final actorNames = video.actors.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final actorThumbs = video.actorThumbs.split('|').map((e) => e.trim()).toList();
      for (int i = 0; i < actorNames.length; i++) {
        builder.element('actor', nest: () {
          builder.element('name', nest: actorNames[i]);
          if (i < actorThumbs.length && actorThumbs[i].isNotEmpty) {
            builder.element('thumb', nest: actorThumbs[i]);
          }
        });
      }

      // Poster
      if (video.posterPath.isNotEmpty) {
        builder.element('thumb', attributes: {'aspect': 'poster'}, nest: video.posterPath);
      }

      // Saga
      if (video.saga.isNotEmpty) {
        builder.element('set', nest: () {
          builder.element('name', nest: video.saga);
        });
      }
    });

    return builder.buildDocument().toXmlString(pretty: true, indent: '    ');
  }

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
               builder.element('director', nest: () {
                 builder.element('name', nest: member['name']);
                 if (member['profile_path'] != null) {
                   builder.element('thumb', nest: 'https://image.tmdb.org/t/p/w185${member['profile_path']}');
                 }
               });
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

      // Saga (Collection)
      if (tmdbData['belongs_to_collection'] != null) {
        final col = tmdbData['belongs_to_collection'];
        builder.element('set', nest: () {
          builder.element('name', nest: col['name'] ?? '');
        });
      }
    });

    return builder.buildDocument().toXmlString(pretty: true, indent: '    ');
  }

  /// Generates a Kodi-compatible TV SHOW NFO XML string from the application's Video model.
  static String generateTvShowFromVideo(model.Video video) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');

    builder.element('tvshow', nest: () {
      builder.element('title', nest: video.title);
      builder.element('showtitle', nest: video.title);
      builder.element('plot', nest: video.plot);
      builder.element('year', nest: video.year);
      builder.element('runtime', nest: video.duration);
      
      // Rating block
      builder.element('rating', attributes: {'name': 'app', 'max': '10', 'default': 'true'}, nest: () {
        builder.element('value', nest: video.rating.toString());
      });

      // Genres
      if (video.genres.isNotEmpty) {
        for (final genre in video.genres.split(',')) {
          final cleanGenre = genre.trim();
          if (cleanGenre.isNotEmpty) {
            builder.element('genre', nest: cleanGenre);
          }
        }
      }

      // Directors (Creators)
      final directorNames = video.directors.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final directorThumbs = video.directorThumbs.split('|').map((e) => e.trim()).toList();
      for (int i = 0; i < directorNames.length; i++) {
        builder.element('director', nest: () {
          builder.element('name', nest: directorNames[i]);
          if (i < directorThumbs.length && directorThumbs[i].isNotEmpty) {
            builder.element('thumb', nest: directorThumbs[i]);
          }
        });
      }

      // Actors
      final actorNames = video.actors.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final actorThumbs = video.actorThumbs.split('|').map((e) => e.trim()).toList();
      for (int i = 0; i < actorNames.length; i++) {
        builder.element('actor', nest: () {
          builder.element('name', nest: actorNames[i]);
          if (i < actorThumbs.length && actorThumbs[i].isNotEmpty) {
            builder.element('thumb', nest: actorThumbs[i]);
          }
        });
      }

      // Poster
      if (video.posterPath.isNotEmpty) {
        builder.element('thumb', attributes: {'aspect': 'poster'}, nest: video.posterPath);
      }
    });

    return builder.buildDocument().toXmlString(pretty: true, indent: '    ');
  }

  /// Generates a Kodi-compatible TV SHOW NFO XML string from TMDB data map.
  static String generateTvShowNfo(Map<String, dynamic> tmdbData) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    
    builder.element('tvshow', nest: () {
      builder.element('title', nest: tmdbData['name'] ?? '');
      builder.element('originaltitle', nest: tmdbData['original_name'] ?? '');
      builder.element('showtitle', nest: tmdbData['name'] ?? '');
      
      builder.element('plot', nest: tmdbData['overview'] ?? '');
      
      final firstAirDate = tmdbData['first_air_date'] as String?; // YYYY-MM-DD
      if (firstAirDate != null && firstAirDate.isNotEmpty) {
        builder.element('premiered', nest: firstAirDate);
        builder.element('year', nest: firstAirDate.split('-').first);
      }
      
      builder.element('userrating', nest: tmdbData['vote_average']?.toString() ?? '0.0');
      // Kodi standard rating block
      builder.element('rating', attributes: {'name': 'tmdb', 'max': '10', 'default': 'true'}, nest: () {
        builder.element('value', nest: tmdbData['vote_average']?.toString() ?? '0.0');
        builder.element('votes', nest: tmdbData['vote_count']?.toString() ?? '0');
      });

      if (tmdbData['episode_run_time'] != null && (tmdbData['episode_run_time'] as List).isNotEmpty) {
         builder.element('runtime', nest: tmdbData['episode_run_time'][0]?.toString() ?? '');
      }
      
      if (tmdbData['networks'] != null && (tmdbData['networks'] as List).isNotEmpty) {
         builder.element('studio', nest: tmdbData['networks'][0]['name'] ?? '');
      }

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

        // Directors (usually creators for TV shows, or encoded in crew)
        if (tmdbData['created_by'] != null) {
           for (final creator in tmdbData['created_by']) {
             builder.element('director', nest: () {
               builder.element('name', nest: creator['name']);
               if (creator['profile_path'] != null) {
                 builder.element('thumb', nest: 'https://image.tmdb.org/t/p/w185${creator['profile_path']}');
               }
             });
           }
        }

        // Actors (Top 10)
        if (cast != null) {
          for (final actor in cast.take(15)) {
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
