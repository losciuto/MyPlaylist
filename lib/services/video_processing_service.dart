import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../models/video.dart' as model;
import '../services/tmdb_service.dart';
import '../services/fanart_service.dart';
import '../utils/nfo_generator.dart';
import '../utils/nfo_parser.dart';
import '../services/metadata_service.dart';
import '../database/app_database.dart' as db;

class VideoProcessingStatus {
  final int current;
  final int total;
  final String currentTitle;
  final bool isCancelled;

  VideoProcessingStatus({
    required this.current,
    required this.total,
    required this.currentTitle,
    this.isCancelled = false,
  });
}

class VideoProcessingResult {
  final int updated;
  final int skipped;
  final int errors;

  VideoProcessingResult({
    required this.updated,
    required this.skipped,
    required this.errors,
  });
}

class VideoProcessingService {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  Future<VideoProcessingResult> bulkGenerateNfo({
    required List<model.Video> videos,
    required String apiKey,
    String? fanartApiKey,
    required String mode, // 'auto' or 'interactive'
    required bool onlyMissingNfo,
    required Function(VideoProcessingStatus) onProgress,
    required Future<Map<String, dynamic>?> Function(model.Video video, List<Map<String, dynamic>> results) onInteractiveSelection,
  }) async {
    _isCancelled = false;
    int updated = 0;
    int skipped = 0;
    int errors = 0;
    final total = videos.length;
    final tmdb = TmdbService(apiKey);

    for (int i = 0; i < total; i++) {
      if (_isCancelled) break;

      final video = videos[i];

      // Skip found videos in interactive mode if they already have info
      if (mode == 'interactive' && video.title.isNotEmpty && video.year.isNotEmpty) {
        skipped++;
        continue;
      }

      // Check for missing NFO if filter is active
      if (onlyMissingNfo) {
        final nfoPath = p.setExtension(video.path, '.nfo');
        if (await File(nfoPath).exists()) {
          skipped++;
          continue;
        }
      }

      onProgress(VideoProcessingStatus(
        current: i + 1,
        total: total,
        currentTitle: video.title.isNotEmpty ? video.title : p.basename(video.path),
      ));

      try {
        // Tiered Search Logic
        String baseQuery = p.basenameWithoutExtension(video.path)
            .replaceAll('.', ' ')
            .replaceAll('_', ' ')
            .replaceAll(RegExp(r'\(\d{4}\)'), '')
            .trim();

        List<String> queriesToTry = [baseQuery];
        final words = baseQuery.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
        if (words.length >= 3) queriesToTry.add(words.take(2).join(' '));
        if (words.isNotEmpty) queriesToTry.add(words.first);
        queriesToTry = queriesToTry.toSet().toList();

        final yearMatch = RegExp(r'\((\d{4})\)').firstMatch(video.title) ?? RegExp(r'\((\d{4})\)').firstMatch(p.basename(video.path));
        final int? year = yearMatch != null ? int.tryParse(yearMatch.group(1)!) : null;

        List<Map<String, dynamic>> results = [];
        final isSeries = video.isSeries;

        for (var q in queriesToTry) {
          if (isSeries) {
            results = await tmdb.searchTvShow(q, year: year);
          } else {
            results = await tmdb.searchMovie(q, year: year);
          }
          if (results.isNotEmpty) break;
        }

        Map<String, dynamic>? selectedMovie;
        if (results.isEmpty) {
          skipped++;
          continue;
        }

        if (mode == 'auto') {
          selectedMovie = results.first;
        } else {
          selectedMovie = await onInteractiveSelection(video, results);
        }

        if (selectedMovie == null) {
          if (_isCancelled) break;
          skipped++;
          continue;
        }

        // Process Details
        Map<String, dynamic> details;
        String nfoContent;
        String nfoPath;
        if (isSeries) {
          details = await tmdb.getTvShowDetails(selectedMovie['id']);
          nfoContent = NfoGenerator.generateTvShowNfo(details);
          nfoPath = p.join(video.path, 'tvshow.nfo');
        } else {
          details = await tmdb.getMovieDetails(selectedMovie['id']);
          nfoContent = NfoGenerator.generateMovieNfo(details);
          nfoPath = p.setExtension(video.path, '.nfo');
        }

        await File(nfoPath).writeAsString(nfoContent);
        
        String localPosterPath = video.posterPath;
        final baseDir = isSeries ? video.path : p.dirname(video.path);
        final baseFileName = p.basenameWithoutExtension(video.path);

        // Initialize Fanart Service
        final fanart = FanartTvService(fanartApiKey);
        Map<String, dynamic>? fanartImages;
        
        // Fetch Fanart Data
        if (fanart.hasKey) {
           try {
             if (isSeries) {
                // TVDB mapping would be better but simple TMDB ID lookup often works for Fanart v3 if supported
                // However, without TVDB ID, this might fail for some shows on Fanart.
                // We'll rely on what we have. TMDB API returns external_ids often? 
                // Wait, TMDB Service `getTvShowDetails` asks for 'append_to_response': 'credits,images'.
                // We should check if we can get external_ids from TMDB details.
                // For now, let's try calling with TMDB ID (Fanart documentation says it supports it for movies, mixed for TV).
                // Actually, let's just use it and fail gracefully.
                fanartImages = await fanart.getTvShowImages(selectedMovie['id']);
             } else {
                fanartImages = await fanart.getMovieImages(selectedMovie['id']);
             }
           } catch (e) {
             debugPrint('Fanart fetch failed: $e');
           }
        }

        // Helper to download file
        Future<void> downloadFile(String url, String path) async {
           try {
             final resp = await http.get(Uri.parse(url));
             if (resp.statusCode == 200) await File(path).writeAsBytes(resp.bodyBytes);
           } catch (e) {
             debugPrint('Download failed ($url): $e');
           }
        }

        // Poster (TMDB usually better for localized posters, keep TMDB as primary unless missing)
        if (details['poster_path'] != null) {
          final posterUrl = 'https://image.tmdb.org/t/p/original${details['poster_path']}';
          final posterPath = isSeries ? p.join(baseDir, 'poster.jpg') : '$baseDir/$baseFileName-poster.jpg';
          await downloadFile(posterUrl, posterPath);
          localPosterPath = posterPath;
        }

        // Backdrop / Fanart (Fanart.tv often has text-free backgrounds which are nice)
        // We look for 'moviebackground' in fanart or use TMDB
        String? backdropUrl;
        if (fanartImages != null) {
           final backgrounds = fanartImages[isSeries ? 'showbackground' : 'moviebackground'] as List?;
           if (backgrounds != null && backgrounds.isNotEmpty) {
             // Get the most liked or first
             backdropUrl = backgrounds.first['url'];
           }
        }
        
        if (backdropUrl == null && details['backdrop_path'] != null) {
           backdropUrl = 'https://image.tmdb.org/t/p/original${details['backdrop_path']}';
        }

        if (backdropUrl != null) {
          final fanartPath = isSeries ? p.join(baseDir, 'fanart.jpg') : '$baseDir/$baseFileName-fanart.jpg';
          await downloadFile(backdropUrl, fanartPath);
        }

        // Logo / ClearArt (Fanart.tv is KING here)
        String? logoUrl;
        if (fanartImages != null) {
           // check specifically for hdmovielogo, hdtvlogo (clearlogo), or clearart
           final logos = fanartImages[isSeries ? 'hdtvlogo' : 'hdmovielogo'] as List?;
           final clearlogo = fanartImages['clearlogo'] as List?; // fallback
           
           if (logos != null && logos.isNotEmpty) {
             logoUrl = logos.first['url']; // Fanart usually sorts by likes/usage
           } else if (clearlogo != null && clearlogo.isNotEmpty) {
             logoUrl = clearlogo.first['url'];
           }
        }

        // Fallback to TMDB logos
        if (logoUrl == null && details['images'] != null && details['images']['logos'] != null) {
          final logos = details['images']['logos'] as List;
          if (logos.isNotEmpty) {
            logoUrl = 'https://image.tmdb.org/t/p/original${logos.first['file_path']}';
          }
        }

        if (logoUrl != null) {
           final logoPath = isSeries ? p.join(baseDir, 'clearlogo.png') : '$baseDir/$baseFileName-clearlogo.png';
           await downloadFile(logoUrl, logoPath);
        }
        
        // Disc Art (Exclusive to Fanart/Specialized sites)
        if (fanartImages != null && !isSeries) {
           final discs = fanartImages['moviedisc'] as List?;
           if (discs != null && discs.isNotEmpty) {
              final discUrl = discs.first['url'];
              final discPath = '$baseDir/$baseFileName-disc.png';
              await downloadFile(discUrl, discPath);
           }
        }

        // Update DB
        final nfoTitle = isSeries ? details['name'] : (details['title'] ?? video.title);
        final nfoYear = (isSeries ? details['first_air_date'] : details['release_date'])?.toString().split('-').first ?? video.year;
        final gList = details['genres'] != null ? (details['genres'] as List).map((g) => g['name']).join(', ') : video.genres;
        final nfoPlot = details['overview'] ?? video.plot;
        final nfoRating = (details['vote_average'] as num?)?.toDouble() ?? video.rating;
        
        String nfoActors = video.actors;
        String nfoDirectors = video.directors;
        if (details['credits'] != null) {
          final cast = (details['credits']['cast'] as List?)?.take(5).map((c) => c['name']).join(', ');
          if (cast != null) nfoActors = cast;
          if (isSeries) {
            if (details['created_by'] != null) {
              nfoDirectors = (details['created_by'] as List).map((c) => c['name']).join(', ');
            }
          } else {
            final crew = (details['credits']['crew'] as List?)?.where((c) => c['job'] == 'Director').map((c) => c['name']).join(', ');
            if (crew != null) nfoDirectors = crew;
          }
        }

        final updatedVideo = model.Video(
          id: video.id,
          path: video.path,
          mtime: video.mtime,
          duration: video.duration,
          title: nfoYear.isNotEmpty ? '$nfoTitle ($nfoYear)' : nfoTitle,
          year: nfoYear,
          genres: gList,
          directors: nfoDirectors,
          actors: nfoActors,
          plot: nfoPlot,
          rating: nfoRating,
          posterPath: localPosterPath,
          isSeries: video.isSeries,
          saga: (details['belongs_to_collection'] != null) ? details['belongs_to_collection']['name'] : video.saga,
        );

        await db.AppDatabase.instance.updateVideo(updatedVideo);
        updated++;

      } catch (e) {
        errors++;
        debugPrint('Error TMDB processing ${video.path}: $e');
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }

    return VideoProcessingResult(updated: updated, skipped: skipped, errors: errors);
  }

  Future<VideoProcessingResult> bulkRenameTitles({
    required List<model.Video> videos,
    required Function(VideoProcessingStatus) onProgress,
    required Function(String) onCancelCleanup,
  }) async {
    _isCancelled = false;
    int updatedCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    final total = videos.length;
    final Set<String> processedDirs = {};

    for (int i = 0; i < total; i++) {
      if (_isCancelled) break;

      final video = videos[i];
      onProgress(VideoProcessingStatus(
        current: i + 1,
        total: total,
        currentTitle: video.title.isNotEmpty ? video.title : p.basename(video.path),
      ));
      
      processedDirs.add(p.dirname(video.path));
      
      try {
        String nfoPath = video.isSeries ? p.join(video.path, 'tvshow.nfo') : p.setExtension(video.path, '.nfo');
        File nfoFile = File(nfoPath);
        bool nfoFound = await nfoFile.exists();
        
        if (!nfoFound && !video.isSeries) {
           final parentDir = Directory(p.dirname(video.path));
           if (await parentDir.exists()) {
             final videoBasenameNoExt = p.basenameWithoutExtension(video.path).toLowerCase();
             await for (final entity in parentDir.list()) {
               if (entity is File && p.extension(entity.path).toLowerCase() == '.nfo') {
                 if (p.basenameWithoutExtension(entity.path).toLowerCase() == videoBasenameNoExt) {
                   nfoPath = entity.path;
                   nfoFile = File(nfoPath);
                   nfoFound = true;
                   break;
                 }
               }
             }
           }
        }

        if (!nfoFound) {
          skippedCount++;
          continue;
        }

        final metadata = await NfoParser.parseNfo(nfoPath);
        if (metadata == null || metadata['title'] == null || metadata['title'].isEmpty) {
          skippedCount++;
          continue;
        }

        final nfoTitle = metadata['title'];
        final nfoYear = metadata['year'];
        final fileMetadata = await MetadataService().getFileMetadata(video.path);
        final fileTitle = fileMetadata['title'] ?? '';
        
        String norm(String? s) => (s ?? '').trim().toLowerCase()
            .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
            .replaceAll(RegExp(r'\s+'), ' ');

        String targetTitle = (nfoYear != null && nfoYear.isNotEmpty) ? '$nfoTitle ($nfoYear)' : nfoTitle;

        bool dbMismatch = norm(video.title) != norm(targetTitle);
        bool fileMismatch = norm(fileTitle) != norm(targetTitle);

        if (!dbMismatch && !fileMismatch) {
          skippedCount++;
          continue;
        }

        final updatedVideo = model.Video(
          id: video.id, path: video.path, mtime: video.mtime, duration: video.duration,
          title: targetTitle, year: nfoYear ?? video.year,
          genres: metadata['genres'] ?? video.genres,
          directors: metadata['directors'] ?? video.directors,
          actors: metadata['actors'] ?? video.actors,
          plot: metadata['plot'] ?? video.plot,
          rating: metadata['rating'] ?? video.rating,
          posterPath: metadata['poster'] ?? video.posterPath,
          isSeries: video.isSeries,
          saga: (metadata['saga'] != null && metadata['saga'].toString().isNotEmpty) ? metadata['saga'] : video.saga,
        );

        if (dbMismatch) await db.AppDatabase.instance.updateVideo(updatedVideo);
        if (fileMismatch) await MetadataService().updateFileMetadata(updatedVideo);

        updatedCount++;
      } catch (e) {
        errorCount++;
        debugPrint('ERROR renaming video ${video.path}: $e');
      }
      await Future.delayed(Duration.zero);
    }

    if (_isCancelled) {
      for (final dir in processedDirs) onCancelCleanup(dir);
    }

    return VideoProcessingResult(updated: updatedCount, skipped: skippedCount, errors: errorCount);
  }
}
