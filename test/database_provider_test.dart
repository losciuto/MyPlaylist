import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/providers/database_provider.dart';
import 'package:my_playlist/models/video.dart' as model;

void main() {
  group('DatabaseProvider Tests', () {
    test('duplicateKey returns correct format for movie', () {
      final video = model.Video(
        path: '/movies/test.mkv',
        mtime: 0,
        title: 'Test Movie',
        year: '2020',
      );
      final key = DatabaseProvider.duplicateKey(video);
      expect(key, 'test movie|2020');
    });

    test('duplicateKey returns correct format for series with folder', () {
      final video = model.Video(
        path: '/series/MySeries/S01/episode.mkv',
        mtime: 0,
        title: 'MySeries',
        year: '2019',
        isSeries: true,
      );
      final key = DatabaseProvider.duplicateKey(video);
      expect(key, contains('|series|'));
      expect(key, contains('episode.mkv'));
    });

    test('duplicateKey handles empty title and year', () {
      final video = model.Video(
        path: '/movies/unknown.mkv',
        mtime: 0,
      );
      final key = DatabaseProvider.duplicateKey(video);
      expect(key, '|');
    });

    test('duplicateKey handles case insensitivity', () {
      final video1 = model.Video(
        path: '/movies/UPPER.mkv',
        mtime: 0,
        title: 'Test Movie',
        year: '2020',
      );
      final video2 = model.Video(
        path: '/movies/lower.mkv',
        mtime: 0,
        title: 'test movie',
        year: '2020',
      );
      // Stesso titolo con diversa capitalizzazione sono duplicati
      expect(
        DatabaseProvider.duplicateKey(video1),
        DatabaseProvider.duplicateKey(video2),
      );
    });

    test('duplicateKey handles series with different filenames', () {
      final video1 = model.Video(
        path: '/series/MySeries/S01/episode1.mkv',
        mtime: 0,
        title: 'MySeries',
        year: '2019',
        isSeries: true,
      );
      final video2 = model.Video(
        path: '/series/MySeries/S01/episode2.mkv',
        mtime: 0,
        title: 'MySeries',
        year: '2019',
        isSeries: true,
      );
      // Diversi file non sono duplicati
      expect(
        DatabaseProvider.duplicateKey(video1),
        isNot(DatabaseProvider.duplicateKey(video2)),
      );
    });

    test('duplicateKey handles same series episode as duplicate', () {
      final video1 = model.Video(
        path: '/series/MySeries/S01/episode.mkv',
        mtime: 0,
        title: 'MySeries',
        year: '2019',
        isSeries: true,
      );
      final video2 = model.Video(
        path: '/series/MySeries/S01/episode.mkv',
        mtime: 0,
        title: 'MySeries',
        year: '2019',
        isSeries: true,
      );
      // Stesso file è duplicato
      expect(
        DatabaseProvider.duplicateKey(video1),
        DatabaseProvider.duplicateKey(video2),
      );
    });
  });
}
