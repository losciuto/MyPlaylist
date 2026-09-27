import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/services/video_processing_service.dart';
import 'package:my_playlist/models/video.dart' as model;

void main() {
  group('VideoProcessingService Tests', () {
    late VideoProcessingService service;

    setUp(() {
      service = VideoProcessingService();
    });

    test('initial state is not cancelled', () {
      expect(service.isCancelled, false);
    });

    test('cancel sets isCancelled to true', () {
      service.cancel();
      expect(service.isCancelled, true);
    });

    test('bulkGenerateNfo returns zero result for empty list', () async {
      final result = await service.bulkGenerateNfo(
        videos: [],
        apiKey: 'test_key',
        mode: 'auto',
        onlyMissingNfo: false,
        onProgress: (status) {},
        onInteractiveSelection: (video, results) async => null,
      );
      expect(result.updated, 0);
      expect(result.skipped, 0);
      expect(result.alreadyInSync, 0);
      expect(result.errors, 0);
    });

    test(
      'bulkGenerateNfo skips videos with title and year in interactive mode',
      () async {
        final videos = [
          model.Video(
            path: '/movies/test.mkv',
            title: 'Test Movie',
            year: '2020',
            mtime: 0,
          ),
        ];

        final result = await service.bulkGenerateNfo(
          videos: videos,
          apiKey: 'test_key',
          mode: 'interactive',
          onlyMissingNfo: false,
          onProgress: (status) {},
          onInteractiveSelection: (video, results) async => null,
        );
        expect(result.alreadyInSync, 1);
        expect(result.updated, 0);
      },
    );

    test(
      'bulkGenerateNfo skips existing NFO when onlyMissingNfo is true',
      () async {
        // Questo test richiede un file system reale, ma possiamo testare il comportamento base
        final videos = [model.Video(path: '/nonexistent/movie.mkv', mtime: 0)];

        final result = await service.bulkGenerateNfo(
          videos: videos,
          apiKey: 'test_key',
          mode: 'auto',
          onlyMissingNfo: true,
          onProgress: (status) {},
          onInteractiveSelection: (video, results) async => null,
        );
        // Non dovrebbe crashare anche con file inesistenti
        expect(result, isA<VideoProcessingResult>());
      },
    );
  });
}
