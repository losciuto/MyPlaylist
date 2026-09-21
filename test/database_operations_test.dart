import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/models/video.dart' as model;

/// Test per la logica di mappamento e manipolazione dei video
/// che non richiedono dipendenze dal database o dai servizi.
void main() {
  group('Video Model Tests', () {
    test('Video fromMap handles null values', () {
      final map = {'id': 1, 'path': '/test/movie.mkv', 'mtime': 100.0};
      final video = model.Video.fromMap(map);
      expect(video.id, 1);
      expect(video.path, '/test/movie.mkv');
      expect(video.mtime, 100.0);
      expect(video.title, '');
      expect(video.year, '');
      expect(video.rating, 0.0);
      expect(video.isSeries, false);
    });

    test('Video fromMap handles integer mtime', () {
      final map = {
        'id': 2,
        'path': '/test/movie2.mkv',
        'mtime': 200, // int instead of double
      };
      final video = model.Video.fromMap(map);
      expect(video.mtime, 200.0);
    });

    test('Video fromMap handles integer rating', () {
      final map = {
        'id': 3,
        'path': '/test/movie3.mkv',
        'mtime': 300.0,
        'rating': 8, // int instead of double
      };
      final video = model.Video.fromMap(map);
      expect(video.rating, 8.0);
    });

    test('Video fromMap handles isSeries as 1', () {
      final map = {
        'id': 4,
        'path': '/test/series',
        'mtime': 400.0,
        'isSeries': 1,
      };
      final video = model.Video.fromMap(map);
      expect(video.isSeries, true);
    });

    test('Video fromMap handles isSeries as 0', () {
      final map = {
        'id': 5,
        'path': '/test/movie5.mkv',
        'mtime': 500.0,
        'isSeries': 0,
      };
      final video = model.Video.fromMap(map);
      expect(video.isSeries, false);
    });

    test('Video toMap produces correct map', () {
      final video = model.Video(
        id: 1,
        path: '/test.mkv',
        mtime: 100.0,
        title: 'Test',
        year: '2020',
        rating: 8.5,
        isSeries: true,
        saga: 'Test Saga',
        sagaIndex: 2,
      );
      final map = video.toMap();
      expect(map['id'], 1);
      expect(map['path'], '/test.mkv');
      expect(map['mtime'], 100.0);
      expect(map['title'], 'Test');
      expect(map['year'], '2020');
      expect(map['rating'], 8.5);
      expect(map['isSeries'], 1);
      expect(map['saga'], 'Test Saga');
      expect(map['sagaIndex'], 2);
    });

    test('Video copyWith updates only specified fields', () {
      final video = model.Video(
        id: 1,
        path: '/test.mkv',
        mtime: 100.0,
        title: 'Original',
        year: '2020',
      );
      final updated = video.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.year, '2020');
      expect(updated.path, '/test.mkv');
      expect(updated.id, 1);
    });

    test('Video copyWith preserves all fields when no changes', () {
      final video = model.Video(
        id: 1,
        path: '/test.mkv',
        mtime: 100.0,
        title: 'Test',
        year: '2020',
      );
      final copy = video.copyWith();
      expect(copy.id, video.id);
      expect(copy.path, video.path);
      expect(copy.title, video.title);
      expect(copy.year, video.year);
    });
  });
}
