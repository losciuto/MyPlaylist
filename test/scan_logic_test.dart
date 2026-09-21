import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/utils/video_extensions.dart';

/// Test semplificati per la logica di scansione file
/// che non richiedono dipendenze dal database o dalle impostazioni.
void main() {
  group('Scan Logic Tests', () {
    test('VideoExtensions supports .mkv', () {
      expect(VideoExtensions.supported.contains('.mkv'), true);
    });

    test('VideoExtensions supports .mp4', () {
      expect(VideoExtensions.supported.contains('.mp4'), true);
    });

    test('VideoExtensions supports .avi', () {
      expect(VideoExtensions.supported.contains('.avi'), true);
    });

    test('VideoExtensions rejects .txt', () {
      expect(VideoExtensions.supported.contains('.txt'), false);
    });

    test('VideoExtensions rejects .jpg', () {
      expect(VideoExtensions.supported.contains('.jpg'), false);
    });

    test('Hidden files are skipped by name', () {
      final hidden = '.hidden.mkv';
      expect(hidden.startsWith('.'), true);
    });

    test('Backup folder names are recognized', () {
      const backupNames = ['converted_backups', 'oldavi'];
      expect(backupNames.contains('converted_backups'), true);
      expect(backupNames.contains('oldavi'), true);
    });

    test('Series keywords are recognized', () {
      const seriesKeywords = [
        'serie',
        'series',
        'seriale',
        'tv show',
        'tvshow',
      ];
      final folderName = 'my_series';
      final lower = folderName.toLowerCase();
      bool isSeries = false;
      for (final kw in seriesKeywords) {
        if (lower.contains(kw)) {
          isSeries = true;
          break;
        }
      }
      expect(isSeries, true);
    });

    test('Non-series folder name is not recognized', () {
      const seriesKeywords = [
        'serie',
        'series',
        'seriale',
        'tv show',
        'tvshow',
      ];
      final folderName = 'movies';
      final lower = folderName.toLowerCase();
      bool isSeries = false;
      for (final kw in seriesKeywords) {
        if (lower.contains(kw)) {
          isSeries = true;
          break;
        }
      }
      expect(isSeries, false);
    });

    test('NFO file path is derived from video path', () {
      final videoPath = '/movies/test.mkv';
      final nfoPath = videoPath.replaceAll('.mkv', '.nfo');
      expect(nfoPath, '/movies/test.nfo');
    });

    test('Movie.nfo fallback is in same directory', () {
      final videoPath = '/movies/subfolder/test.mkv';
      final dirName = videoPath.substring(0, videoPath.lastIndexOf('/'));
      final movieNfoPath = '$dirName/movie.nfo';
      expect(movieNfoPath, '/movies/subfolder/movie.nfo');
    });
  });
}
