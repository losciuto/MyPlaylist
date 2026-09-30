import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/services/video_processing_service.dart';

import 'fakes/fake_video_repository.dart';

void main() {
  late Directory tempDir;
  late FakeVideoRepository repository;
  late VideoProcessingService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('video_processing_repo');
    repository = FakeVideoRepository();
    service = VideoProcessingService(repository);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('bulkRenameTitles - tracciamento dei fallimenti', () {
    test('un video senza .nfo viene registrato come fallito', () async {
      final video = buildVideo(
        id: 1,
        title: 'Senza nfo',
        path: '${tempDir.path}/senza_nfo.mkv',
      );
      File(video.path).writeAsStringSync('video');

      final result = await service.bulkRenameTitles(
        videos: [video],
        onProgress: (_) {},
        onCancelCleanup: (_) {},
      );

      expect(result.errors, 1);
      expect(result.updated, 0);
      expect(repository.failedRenames, hasLength(1));
      expect(repository.failedRenames.single.path, video.path);
      expect(repository.failedRenames.single.errorMessage, contains('nfo'));
    });

    test('i fallimenti precedenti vengono saltati', () async {
      final video = buildVideo(
        id: 1,
        title: 'Gia fallito',
        path: '${tempDir.path}/gia_fallito.mkv',
      );
      await repository.insertFailedRename(video.path, 'Fallimento precedente');

      final result = await service.bulkRenameTitles(
        videos: [video],
        onProgress: (_) {},
        onCancelCleanup: (_) {},
      );

      expect(result.previouslyFailed, 1);
      expect(result.errors, 0);
      expect(result.updated, 0);
      // Non viene ritentato, quindi il fallimento precedente resta com'e'.
      expect(
        repository.failedRenames.single.errorMessage,
        'Fallimento precedente',
      );
    });

    test('un .nfo presente aggiorna il video nel repository', () async {
      final video = buildVideo(
        id: 7,
        title: 'Titolo vecchio',
        path: '${tempDir.path}/titolo_vecchio.mkv',
      );
      File(video.path).writeAsStringSync('video');
      File('${tempDir.path}/titolo_vecchio.nfo').writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<movie>
  <title>Titolo nuovo</title>
  <year>2021</year>
  <rating>7.5</rating>
</movie>
''');

      final result = await service.bulkRenameTitles(
        videos: [video],
        onProgress: (_) {},
        onCancelCleanup: (_) {},
      );

      // Il file non e' un video valido: la scrittura dei metadati fallisce e
      // viene conteggiata come errore, ma l'aggiornamento e' gia' stato
      // salvato nel repository.
      expect(result.errors, 1);
      expect(repository.videos, hasLength(1));
      // Il titolo prende l'anno dal nome del file, come fa il rinominatore.
      expect(repository.videos.single.title, 'Titolo nuovo (2021)');
      expect(repository.videos.single.year, '2021');
      // La scrittura dei metadati sul file finto fallisce, quindi il servizio
      // registra il video come rinominabile in futuro: e' il comportamento
      // voluto, evita di riprovare subito.
      expect(repository.failedRenames, hasLength(1));
      expect(repository.failedRenames.single.path, video.path);
    });

    test('un .nfo senza titolo valido registra il fallimento', () async {
      final video = buildVideo(
        id: 3,
        title: 'Nfo vuoto',
        path: '${tempDir.path}/nfo_vuoto.mkv',
      );
      File(video.path).writeAsStringSync('video');
      File('${tempDir.path}/nfo_vuoto.nfo').writeAsStringSync(
        '<?xml version="1.0"?><movie><year>2020</year></movie>',
      );

      final result = await service.bulkRenameTitles(
        videos: [video],
        onProgress: (_) {},
        onCancelCleanup: (_) {},
      );

      expect(result.errors, 1);
      expect(repository.failedRenames, hasLength(1));
      expect(
        repository.failedRenames.single.errorMessage.toLowerCase(),
        contains('titolo'),
      );
    });

    test('l\'avanzamento viene notificato per ogni video', () async {
      final videos = [
        buildVideo(id: 1, title: 'A', path: '${tempDir.path}/a.mkv'),
        buildVideo(id: 2, title: 'B', path: '${tempDir.path}/b.mkv'),
      ];
      for (final v in videos) {
        File(v.path).writeAsStringSync('video');
      }

      final progress = <int>[];
      await service.bulkRenameTitles(
        videos: videos,
        onProgress: (status) => progress.add(status.current),
        onCancelCleanup: (_) {},
      );

      expect(progress, [1, 2]);
    });

    test('cancel interrompe il lavoro e pulisce le directory', () async {
      final videos = [
        buildVideo(id: 1, title: 'A', path: '${tempDir.path}/a.mkv'),
        buildVideo(id: 2, title: 'B', path: '${tempDir.path}/b.mkv'),
      ];
      for (final v in videos) {
        File(v.path).writeAsStringSync('video');
      }

      final cleaned = <String>[];
      service.cancel();
      final result = await service.bulkRenameTitles(
        videos: videos,
        onProgress: (_) => service.cancel(),
        onCancelCleanup: cleaned.add,
      );

      expect(result.updated, 0);
      expect(cleaned, isNotEmpty);
    });
  });

  group('bulkGenerateNfo - filtri applicati prima della rete', () {
    test(
      'in modalita\' interattiva i video gia\' completi vengono saltati',
      () async {
        final result = await service.bulkGenerateNfo(
          videos: [
            buildVideo(
              id: 1,
              title: 'Gia completo',
              year: '2020',
              path: '${tempDir.path}/gia_completo.mkv',
            ),
          ],
          apiKey: 'chiave_non_valida',
          mode: 'interactive',
          onlyMissingNfo: false,
          onProgress: (_) {},
          onInteractiveSelection: (_, _) async => null,
        );

        expect(result.alreadyInSync, 1);
        expect(result.updated, 0);
        expect(result.errors, 0);
      },
    );

    test('con onlyMissingNfo un .nfo gia\' presente viene saltato', () async {
      final path = '${tempDir.path}/con_nfo.mkv';
      File(path).writeAsStringSync('video');
      File('${tempDir.path}/con_nfo.nfo').writeAsStringSync('<movie/>');

      final result = await service.bulkGenerateNfo(
        videos: [buildVideo(id: 1, path: path)],
        apiKey: 'chiave_non_valida',
        mode: 'auto',
        onlyMissingNfo: true,
        onProgress: (_) {},
        onInteractiveSelection: (_, _) async => null,
      );

      expect(result.alreadyInSync, 1);
      expect(result.updated, 0);
      expect(result.errors, 0);
    });
  });

  group('deleteVideoWithFiles', () {
    test('un film viene rimosso con i file di accompagnamento', () async {
      final base = '${tempDir.path}/film.mkv';
      File(base).writeAsStringSync('video');
      // I sidecar hanno il suffisso -poster.jpg: e' cio' che il servizio
      // elimina insieme al video.
      final poster = File('${tempDir.path}/film-poster.jpg');
      poster.writeAsStringSync('img');

      final video = buildVideo(id: 5, path: base, posterPath: poster.path);

      final deleted = await service.deleteVideoWithFiles(video);

      expect(File(base).existsSync(), isFalse);
      expect(poster.existsSync(), isFalse);
      expect(deleted, isNotEmpty);
    });

    test('un file inesistente non genera errori', () async {
      final video = buildVideo(
        id: 6,
        title: 'Assente',
        path: '${tempDir.path}/assente.mkv',
      );

      final deleted = await service.deleteVideoWithFiles(video);

      expect(deleted, isEmpty);
    });

    test('una serie viene rimossa con l\'intera cartella', () async {
      final dir = Directory('${tempDir.path}/serie')..createSync();
      File('${dir.path}/ep1.mkv').writeAsStringSync('video');
      File('${dir.path}/tvshow.nfo').writeAsStringSync('<tvshow/>');

      final video = buildVideo(
        id: 8,
        title: 'Serie',
        path: dir.path,
        isSeries: true,
      );

      final deleted = await service.deleteVideoWithFiles(video);

      expect(dir.existsSync(), isFalse);
      expect(deleted, contains(dir.path));
    });
  });
}
