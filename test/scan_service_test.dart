import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/models/video.dart';
import 'package:my_playlist/services/scan_service.dart';

import 'fakes/fake_video_repository.dart';

/// Copre gli stati emessi da [ScanService]: i messaggi non devono più essere
/// stringhe inglesi incorporate nel servizio, perché sono localizzati dalla UI.
void main() {
  group('ScanStatus', () {
    test('la cartella mancante è segnalata con il tipo dedicato', () {
      const status = ScanStatus.folderMissing();
      expect(status.type, ScanStatusType.folderMissing);
      expect(status.count, 0);
    });

    test('lavvio riporta il percorso della cartella', () {
      const status = ScanStatus.started('/video/film');
      expect(status.type, ScanStatusType.started);
      expect(status.path, '/video/film');
    });

    test('il conteggio interno non viene mostrato come messaggio', () {
      const status = ScanStatus.countUpdate(2, currentItem: 'film.mkv');
      expect(status.type, ScanStatusType.countUpdate);
      expect(status.count, 2);
      expect(status.currentItem, 'film.mkv');
    });

    test('errore e completamento conservano il conteggio', () {
      const failure = ScanStatus.failed(5, 'disco non montato');
      expect(failure.type, ScanStatusType.failed);
      expect(failure.count, 5);
      expect(failure.error, 'disco non montato');

      const done = ScanStatus.completed(5);
      expect(done.type, ScanStatusType.completed);
      expect(done.count, 5);
    });
  });

  group('ScanService.scanFolder', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('scan_service_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test(
      'emette folderMissing e termina per un percorso inesistente',
      () async {
        final missing = '${tempDir.path}/non-esiste';
        final service = ScanService(FakeVideoRepository());
        final statuses = await service.scanFolder(missing).toList();

        expect(statuses, hasLength(1));
        expect(statuses.single.type, ScanStatusType.folderMissing);
      },
    );

    test('su una cartella vuota segnala avvio e completamento', () async {
      final service = ScanService(FakeVideoRepository());
      final statuses = await service.scanFolder(tempDir.path).toList();

      expect(statuses.first.type, ScanStatusType.started);
      expect(statuses.first.path, tempDir.path);
      expect(statuses.last.type, ScanStatusType.completed);
      expect(statuses.last.count, 0);
    });

    test('conta i video supportati trovati nella cartella', () async {
      File('${tempDir.path}/primo.mkv').writeAsBytesSync([0]);
      File('${tempDir.path}/secondo.mp4').writeAsBytesSync([0]);
      File('${tempDir.path}/testo.txt').writeAsStringSync('ignora');

      final repository = FakeVideoRepository();
      final service = ScanService(repository);
      final statuses = await service.scanFolder(tempDir.path).toList();
      final done = statuses.last;

      expect(done.type, ScanStatusType.completed);
      expect(done.count, 2);
      expect(repository.videos, hasLength(2));
      expect(
        repository.videos.map((Video v) => v.title),
        containsAll(<String>['primo', 'secondo']),
      );
    });
  });
}
