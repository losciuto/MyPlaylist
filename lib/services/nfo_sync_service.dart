import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/video.dart' as model;
import '../utils/nfo_generator.dart';
import '../utils/nfo_parser.dart';
import 'logger_service.dart';

class NfoSyncService {
  final LoggerService _logger = LoggerService();

  /// Saves the current video metadata to a local .nfo file.
  Future<bool> saveNfo(model.Video video) async {
    try {
      final videoFile = File(video.path);
      if (video.isSeries) {
        // For series, the NFO is usually tvshow.nfo in the directory
        final nfoPath = p.join(video.path, 'tvshow.nfo');
        final xml = NfoGenerator.generateTvShowFromVideo(video);
        await File(nfoPath).writeAsString(xml);
        _logger.info('Saved series NFO to $nfoPath');
      } else {
        // For movies, it's video_name.nfo
        final nfoPath = p.setExtension(video.path, '.nfo');
        final xml = NfoGenerator.generateFromVideo(video);
        await File(nfoPath).writeAsString(xml);
        _logger.info('Saved movie NFO to $nfoPath');
      }
      return true;
    } catch (e) {
      _logger.error('Error saving NFO for ${video.title}', e);
      return false;
    }
  }

  /// Refreshes the video metadata by re-parsing the local .nfo file.
  Future<model.Video?> refreshFromNfo(model.Video video) async {
    try {
      String nfoPath;
      if (video.isSeries) {
        nfoPath = p.join(video.path, 'tvshow.nfo');
      } else {
        nfoPath = p.setExtension(video.path, '.nfo');
        if (!await File(nfoPath).exists()) {
          final movieNfo = p.join(p.dirname(video.path), 'movie.nfo');
          if (await File(movieNfo).exists()) {
            nfoPath = movieNfo;
          }
        }
      }

      final metadata = await NfoParser.parseNfo(nfoPath);
      if (metadata == null) return null;

      return video.copyWith(
        title: metadata['title'] ?? video.title,
        genres: metadata['genres'] ?? video.genres,
        year: metadata['year'] ?? video.year,
        directors: metadata['directors'] ?? video.directors,
        directorThumbs: metadata['directorThumbs'] ?? video.directorThumbs,
        plot: metadata['plot'] ?? video.plot,
        actors: metadata['actors'] ?? video.actors,
        actorThumbs: metadata['actorThumbs'] ?? video.actorThumbs,
        duration: metadata['duration'] ?? video.duration,
        rating: metadata['rating'] ?? video.rating,
        posterPath: metadata['poster'] ?? video.posterPath,
        saga: metadata['saga'] ?? video.saga,
      );
    } catch (e) {
      _logger.error('Error refreshing metadata from NFO for ${video.title}', e);
      return null;
    }
  }
}
