import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/models/video.dart';
import 'package:my_playlist/repositories/video_repository.dart';
import 'package:my_playlist/services/statistics_service.dart';

/// Repository finto: contiene solo i video inseriti nel test.
class FakeVideoRepository implements VideoRepository {
  FakeVideoRepository(this.videos);

  final List<Video> videos;

  @override
  Future<List<Video>> getAllVideos() async => videos;

  @override
  Future<int> getVideoCount() async => videos.length;

  @override
  Future<Video?> getVideoByPath(String path) async =>
      videos.where((v) => v.path == path).firstOrNull;

  @override
  Future<List<Video>> getVideosByPaths(List<String> paths) async =>
      videos.where((v) => paths.contains(v.path)).toList();

  @override
  Future<List<Video>> getRandomPlaylist(
    int limit, {
    List<int>? excludeIds,
  }) async => videos.take(limit).toList();

  @override
  Future<List<Video>> getRecentPlaylist(int limit) async =>
      videos.take(limit).toList();

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
  }) async => videos.take(limit).toList();

  @override
  Future<void> insertVideo(Video video) async => videos.add(video);

  @override
  Future<void> updateVideo(Video video) async {}

  @override
  Future<int> deleteVideo(int id) async => 0;

  @override
  Future<Set<String>> getAllFailedRenamePaths() async => <String>{};

  @override
  Future<void> insertFailedRename(String path, String errorMessage) async {}

  @override
  Future<int> getFailedRenamesCount() async => 0;

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> syncDatesWithMtime() async {}
}

Video buildVideo({
  String title = 'Film',
  String genres = '',
  String year = '',
  String saga = '',
  double rating = 0,
  bool isSeries = false,
}) => Video(
  path: '/video/$title.mkv',
  mtime: 1700000000,
  title: title,
  genres: genres,
  year: year,
  saga: saga,
  rating: rating,
  isSeries: isSeries,
);

void main() {
  group('StatisticsService', () {
    test('un archivio vuoto non genera distribuzioni', () async {
      final stats = await StatisticsService.calculateStatistics(
        repository: FakeVideoRepository(const []),
      );

      expect(stats.totalVideos, 0);
      expect(stats.moviesCount, 0);
      expect(stats.seriesCount, 0);
      expect(stats.averageRating, 0);
      expect(stats.genreDistribution, isEmpty);
    });

    test('conta film e serie', () async {
      final repository = FakeVideoRepository([
        buildVideo(title: 'Film A'),
        buildVideo(title: 'Serie B', isSeries: true),
        buildVideo(title: 'Serie C', isSeries: true),
      ]);

      final stats = await StatisticsService.calculateStatistics(
        repository: repository,
      );

      expect(stats.totalVideos, 3);
      expect(stats.moviesCount, 1);
      expect(stats.seriesCount, 2);
    });

    test('la distribuzione dei generi conta i video che li hanno', () async {
      final repository = FakeVideoRepository([
        buildVideo(title: 'A', genres: 'Azione'),
        buildVideo(title: 'B', genres: 'Azione'),
        buildVideo(title: 'C', genres: 'Commedia'),
      ]);

      final stats = await StatisticsService.calculateStatistics(
        repository: repository,
      );

      expect(stats.genreDistribution['Azione'], 2);
      expect(stats.genreDistribution['Commedia'], 1);
    });

    test('la media del voto considera solo i video valutati', () async {
      final repository = FakeVideoRepository([
        buildVideo(title: 'A', rating: 8),
        buildVideo(title: 'B', rating: 6),
        buildVideo(title: 'C'),
      ]);

      final stats = await StatisticsService.calculateStatistics(
        repository: repository,
      );

      expect(stats.totalWithRating, 2);
      expect(stats.averageRating, closeTo(7.0, 0.001));
    });

    test(
      'la distribuzione delle saghe conta i video che ne fanno parte',
      () async {
        final repository = FakeVideoRepository([
          buildVideo(title: 'A', saga: 'Trilogia'),
          buildVideo(title: 'B', saga: 'Trilogia'),
          buildVideo(title: 'C'),
        ]);

        final stats = await StatisticsService.calculateStatistics(
          repository: repository,
        );

        expect(stats.sagaDistribution['Trilogia'], 2);
      },
    );
  });
}
