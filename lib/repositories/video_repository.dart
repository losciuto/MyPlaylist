import '../database/app_database.dart' as db;
import '../models/video.dart';

/// Accesso ai dati dei video separato dal database concreto.
///
/// I servizi dipendono da questa interfaccia invece di chiamare
/// `AppDatabase.instance`: in questo modo possono essere costruiti con un
/// repository finto nei test senza toccare Drift o il filesystem.
abstract class VideoRepository {
  Future<int> getVideoCount();

  Future<List<Video>> getAllVideos();

  Future<Video?> getVideoByPath(String path);

  Future<List<Video>> getVideosByPaths(List<String> paths);

  Future<List<Video>> getRandomPlaylist(int limit, {List<int>? excludeIds});

  Future<List<Video>> getRecentPlaylist(int limit);

  Future<List<Video>> getFilteredPlaylist({
    List<String>? genres,
    List<String>? years,
    double? minRating,
    List<String>? actors,
    List<String>? directors,
    List<String>? excludedGenres,
    List<String>? excludedYears,
    List<String>? excludedActors,
    List<String>? excludedDirectors,
    List<String>? sagas,
    List<String>? excludedSagas,
    int limit = 20,
    List<int>? excludeIds,
  });

  Future<void> insertVideo(Video video);

  Future<void> updateVideo(Video video);

  Future<int> deleteVideo(int id);

  Future<Set<String>> getAllFailedRenamePaths();

  Future<void> insertFailedRename(String path, String errorMessage);

  Future<int> getFailedRenamesCount();

  Future<void> clearAll();

  Future<void> syncDatesWithMtime();
}

/// Implementazione di default: delega al database dell'applicazione.
class AppDatabaseVideoRepository implements VideoRepository {
  const AppDatabaseVideoRepository();

  db.AppDatabase get _db => db.AppDatabase.instance;

  @override
  Future<int> getVideoCount() => _db.getVideoCount();

  @override
  Future<List<Video>> getAllVideos() => _db.getAllVideos();

  @override
  Future<Video?> getVideoByPath(String path) => _db.getVideoByPath(path);

  @override
  Future<List<Video>> getVideosByPaths(List<String> paths) =>
      _db.getVideosByPaths(paths);

  @override
  Future<List<Video>> getRandomPlaylist(int limit, {List<int>? excludeIds}) =>
      _db.getRandomPlaylist(limit, excludeIds: excludeIds);

  @override
  Future<List<Video>> getRecentPlaylist(int limit) =>
      _db.getRecentPlaylist(limit);

  @override
  Future<List<Video>> getFilteredPlaylist({
    List<String>? genres,
    List<String>? years,
    double? minRating,
    List<String>? actors,
    List<String>? directors,
    List<String>? excludedGenres,
    List<String>? excludedYears,
    List<String>? excludedActors,
    List<String>? excludedDirectors,
    List<String>? sagas,
    List<String>? excludedSagas,
    int limit = 20,
    List<int>? excludeIds,
  }) => _db.getFilteredPlaylist(
    genres: genres,
    years: years,
    minRating: minRating,
    actors: actors,
    directors: directors,
    excludedGenres: excludedGenres,
    excludedYears: excludedYears,
    excludedActors: excludedActors,
    excludedDirectors: excludedDirectors,
    sagas: sagas,
    excludedSagas: excludedSagas,
    limit: limit,
    excludeIds: excludeIds,
  );

  @override
  Future<void> insertVideo(Video video) => _db.insertVideo(video);

  @override
  Future<void> updateVideo(Video video) => _db.updateVideo(video);

  @override
  Future<int> deleteVideo(int id) => _db.deleteVideo(id);

  @override
  Future<Set<String>> getAllFailedRenamePaths() =>
      _db.getAllFailedRenamePaths();

  @override
  Future<void> insertFailedRename(String path, String errorMessage) =>
      _db.insertFailedRename(path, errorMessage);

  @override
  Future<int> getFailedRenamesCount() => _db.getFailedRenamesCount();

  @override
  Future<void> clearAll() => _db.clearDatabase();

  @override
  Future<void> syncDatesWithMtime() => _db.syncDatesWithMtime();
}

/// Repository attualmente in uso. Di default delega al database dell'app,
/// ma puo' essere sostituito (per esempio nei test).
VideoRepository videoRepository = const AppDatabaseVideoRepository();
