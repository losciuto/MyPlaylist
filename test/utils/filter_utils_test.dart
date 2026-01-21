import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/utils/filter_utils.dart';
import 'package:my_playlist/models/video.dart';

void main() {
  group('FilterUtils Tests', () {
    final v1 = Video(
      id: 1, path: '/movies/action/Matrix.mkv', title: 'The Matrix', year: '1999', 
      genres: 'Sci-Fi', rating: 8.7, duration: '2h 16m', isSeries: false, 
      mtime: 0, directors: '', plot: '', actors: '', posterPath: '', saga: '', sagaIndex: 0
    );
    final v2 = Video(
      id: 2, path: '/movies/drama/Godfather.mkv', title: 'The Godfather', year: '1972', 
      genres: 'Crime', rating: 9.2, duration: '2h 55m', isSeries: false,
      mtime: 0, directors: '', plot: '', actors: '', posterPath: '', saga: '', sagaIndex: 0
    );
    final v3 = Video(
      id: 3, path: '/movies/comedy/Superbad.mkv', title: 'Superbad', year: '2007', 
      genres: 'Comedy', rating: 7.6, duration: '1h 53m', isSeries: false,
      mtime: 0, directors: '', plot: '', actors: '', posterPath: '', saga: '', sagaIndex: 0
    );

    test('Filters by title', () {
      final results = FilterUtils.filterVideos([v1, v2, v3], 'Matrix');
      expect(results.length, 1);
      expect(results.first.title, 'The Matrix');
    });

    test('Filters by path', () {
      final results = FilterUtils.filterVideos([v1, v2, v3], 'comedy');
      expect(results.length, 1);
      expect(results.first.title, 'Superbad');
    });

    test('Sorts by Title Ascending', () {
      final list = [v1, v2, v3]; // Matrix, Godfather, Superbad -> Godfather, Superbad, Matrix (alphabetical)
      // Actually: Godfather (G), Matrix (M), Superbad (S)
      FilterUtils.sortVideos(list, 0, true);
      expect(list[0].title, 'Superbad'); // Wait... M, G, S -> G, M, S?
      // Sort: G(odfather), M(atrix), S(uperbad)? 
      // Let's check logic: case 0 is title.
      // G < M < S.
      // Expected: Godfather, Matrix, Superbad.
      expect(list[0].title, 'Superbad');
      expect(list[1].title, 'The Godfather');
      expect(list[2].title, 'The Matrix');
    });
    
    test('Sorts by Rating Descending', () {
      final list = [v1, v2, v3];
      FilterUtils.sortVideos(list, 11, false); // 11 is rating
      // 9.2, 8.7, 7.6
      expect(list[0].title, 'The Godfather'); // 9.2
      expect(list[1].title, 'The Matrix');    // 8.7
      expect(list[2].title, 'Superbad');      // 7.6
    });

    test('Parses duration correctly', () {
      expect(FilterUtils.parseDuration('2h 30m'), 150);
      expect(FilterUtils.parseDuration('1h'), 60);
      expect(FilterUtils.parseDuration('45m'), 45);
      expect(FilterUtils.parseDuration(''), 0);
    });
  });
}
