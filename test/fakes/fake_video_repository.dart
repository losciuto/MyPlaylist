import 'package:my_playlist/models/video.dart';
import 'package:my_playlist/repositories/video_repository.dart';

/// Repository finto per i test: mantiene i video in memoria e registra le
/// chiamate, così i servizi non devono toccare Drift o il filesystem.
class FakeVideoRepository implements VideoRepository {
  FakeVideoRepository([List<Video>? initial])
    : videos = List<Video>.from(initial ?? const []);

  final List<Video> videos;
  final List<FailedRenameEntry> failedRenames = [];

  /// Chiamate di lettura registrate nell'ordine in cui sono arrivate.
  final List<String> reads = [];

  int get randomCalls => reads.where((r) => r.startsWith('random')).length;

  @override
  Future<List<Video>> getAllVideos() async {
    reads.add('getAllVideos');
    return List<Video>.from(videos);
  }

  @override
  Future<int> getVideoCount() async {
    reads.add('getVideoCount');
    return videos.length;
  }

  @override
  Future<Video?> getVideoByPath(String path) async {
    reads.add('getVideoByPath');
    for (final video in videos) {
      if (video.path == path) return video;
    }
    return null;
  }

  @override
  Future<List<Video>> getVideosByPaths(List<String> paths) async {
    reads.add('getVideosByPaths');
    return videos.where((v) => paths.contains(v.path)).toList();
  }

  @override
  Future<List<Video>> getRandomPlaylist(
    int limit, {
    List<int>? excludeIds,
  }) async {
    reads.add('random($limit, exclude: ${excludeIds?.length ?? 0})');
    final pool = excludeIds == null || excludeIds.isEmpty
        ? videos
        : videos
              .where((v) => v.id == null || !excludeIds.contains(v.id))
              .toList();
    return pool.take(limit).toList();
  }

  @override
  Future<List<Video>> getRecentPlaylist(int limit) async {
    reads.add('recent($limit)');
    final sorted = List<Video>.from(videos)
      ..sort((a, b) => b.mtime.compareTo(a.mtime));
    return sorted.take(limit).toList();
  }

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
  }) async {
    reads.add('filtered(limit: $limit, exclude: ${excludeIds?.length ?? 0})');
    return videos.take(limit).toList();
  }

  @override
  Future<void> insertVideo(Video video) async => videos.add(video);

  @override
  Future<void> updateVideo(Video video) async {
    final index = videos.indexWhere((v) => v.id == video.id);
    if (index >= 0) {
      videos[index] = video;
    } else {
      videos.add(video);
    }
  }

  @override
  Future<int> deleteVideo(int id) async {
    final before = videos.length;
    videos.removeWhere((v) => v.id == id);
    return before - videos.length;
  }

  @override
  Future<Set<String>> getAllFailedRenamePaths() async =>
      failedRenames.map((f) => f.path).toSet();

  @override
  Future<int> getFailedRenamesCount() async => failedRenames.length;

  @override
  Future<void> clearAll() async {
    videos.clear();
    failedRenames.clear();
  }

  @override
  Future<void> syncDatesWithMtime() async {}

  @override
  Future<void> insertFailedRename(String path, String errorMessage) async {
    failedRenames.removeWhere((f) => f.path == path);
    failedRenames.add(FailedRenameEntry(path, errorMessage));
  }
}

class FailedRenameEntry {
  const FailedRenameEntry(this.path, this.errorMessage);

  final String path;
  final String errorMessage;
}

Video buildVideo({
  int? id,
  String title = 'Film',
  String path = '/video/film.mkv',
  String genres = '',
  String year = '',
  String actors = '',
  String directors = '',
  String saga = '',
  double rating = 0,
  double mtime = 1700000000,
  bool isSeries = false,
  String posterPath = '',
}) => Video(
  id: id,
  path: path,
  mtime: mtime,
  title: title,
  genres: genres,
  year: year,
  actors: actors,
  directors: directors,
  saga: saga,
  rating: rating,
  isSeries: isSeries,
  posterPath: posterPath,
);
