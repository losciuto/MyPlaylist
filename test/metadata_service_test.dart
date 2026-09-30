import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/models/video.dart';
import 'package:my_playlist/services/metadata_service.dart';

void main() {
  late Directory tempDir;
  late String missingPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('metadata_service_test');
    missingPath = '${tempDir.path}/non_esiste.mkv';
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Video buildVideo(String path) => Video(
    path: path,
    mtime: 1700000000,
    title: 'Titolo di prova',
    dateAdded: DateTime(2026, 5, 17),
  );

  group('MetadataService - percorsi inesistenti', () {
    test('updateFileMetadata su un file inesistente fallisce', () async {
      final response = await MetadataService().updateFileMetadata(
        buildVideo(missingPath),
      );

      expect(response.result, MetadataUpdateResult.failed);
    });

    test('saveFileMetadata su un file inesistente fallisce', () async {
      final response = await MetadataService().saveFileMetadata(
        missingPath,
        const {'title': 'Titolo'},
      );

      expect(response.result, MetadataUpdateResult.failed);
    });

    test(
      'getFileMetadata su un file inesistente restituisce una mappa vuota',
      () async {
        final metadata = await MetadataService().getFileMetadata(missingPath);

        expect(metadata, isEmpty);
      },
    );

    test(
      'getRawFileMetadata su un file inesistente restituisce una mappa vuota',
      () async {
        final metadata = await MetadataService().getRawFileMetadata(
          missingPath,
        );

        expect(metadata, isEmpty);
      },
    );
  });

  group('MetadataService - file reale senza contenuto', () {
    test('getFileMetadata su un file vuoto non lancia eccezioni', () async {
      final empty = File('${tempDir.path}/vuoto.mp4')..writeAsStringSync('');

      final metadata = await MetadataService().getFileMetadata(empty.path);

      expect(metadata, isA<Map<String, String>>());
    });

    test('saveFileMetadata su un file non gestito segnala il motivo', () async {
      final plain = File('${tempDir.path}/testo.txt')
        ..writeAsStringSync('contenuto');

      final response = await MetadataService().saveFileMetadata(
        plain.path,
        const {'title': 'Titolo'},
      );

      expect(response.result, MetadataUpdateResult.failed);
      expect(response.reason, isNotNull);
    });
  });

  group('MetadataService - contratto di risposta', () {
    test('il risultato espone metodo e motivo con valori predefiniti', () {
      final response = MetadataUpdateResponse(MetadataUpdateResult.updated);

      expect(response.result, MetadataUpdateResult.updated);
      expect(response.method, isEmpty);
      expect(response.reason, isNull);
    });

    test('i risultati disponibili sono tre', () {
      expect(MetadataUpdateResult.values, hasLength(3));
      expect(
        MetadataUpdateResult.values,
        containsAll(<MetadataUpdateResult>[
          MetadataUpdateResult.updated,
          MetadataUpdateResult.alreadyInSync,
          MetadataUpdateResult.failed,
        ]),
      );
    });

    test('checkFfmpegAvailability risponde sempre con un booleano', () async {
      expect(await MetadataService().checkFfmpegAvailability(), isA<bool>());
    });
  });
}
