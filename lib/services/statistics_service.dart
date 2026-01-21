import '../database/app_database.dart' as db;

class VideoStatistics {
  final int totalVideos;
  final Map<String, int> genreDistribution;
  final Map<String, int> yearDistribution;
  final Map<String, int> sagaDistribution;
  final double averageRating;
  final int totalWithRating;
  final int seriesCount;
  final int moviesCount;

  VideoStatistics({
    required this.totalVideos,
    required this.genreDistribution,
    required this.yearDistribution,
    required this.sagaDistribution,
    required this.averageRating,
    required this.totalWithRating,
    required this.seriesCount,
    required this.moviesCount,
  });
}

class StatisticsService {
  static Future<VideoStatistics> calculateStatistics() async {
    final database = db.AppDatabase.instance;
    final videos = await database.getAllVideos();

    // Genre distribution
    final genreMap = <String, int>{};
    for (final video in videos) {
      if (video.genres.isNotEmpty) {
        final genres = video.genres.split(',').map((g) => g.trim()).where((g) => g.isNotEmpty);
        for (final genre in genres) {
          genreMap[genre] = (genreMap[genre] ?? 0) + 1;
        }
      }
    }

    // Year distribution
    final yearMap = <String, int>{};
    for (final video in videos) {
      if (video.year.isNotEmpty) {
        yearMap[video.year] = (yearMap[video.year] ?? 0) + 1;
      }
    }

    // Saga distribution
    final sagaMap = <String, int>{};
    for (final video in videos) {
      if (video.saga.isNotEmpty) {
        sagaMap[video.saga] = (sagaMap[video.saga] ?? 0) + 1;
      }
    }

    // Rating statistics
    final videosWithRating = videos.where((v) => v.rating > 0).toList();
    final averageRating = videosWithRating.isEmpty
        ? 0.0
        : videosWithRating.map((v) => v.rating).reduce((a, b) => a + b) / videosWithRating.length;

    // Series vs Movies
    final seriesCount = videos.where((v) => v.isSeries).length;
    final moviesCount = videos.length - seriesCount;

    return VideoStatistics(
      totalVideos: videos.length,
      genreDistribution: genreMap,
      yearDistribution: yearMap,
      sagaDistribution: sagaMap,
      averageRating: averageRating,
      totalWithRating: videosWithRating.length,
      seriesCount: seriesCount,
      moviesCount: moviesCount,
    );
  }
}
