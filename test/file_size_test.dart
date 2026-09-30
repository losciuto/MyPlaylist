import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/utils/file_size.dart';

void main() {
  group('formatFileSize', () {
    test('usa i gigabyte per i file grandi', () {
      expect(formatFileSize(1500000000), '1.50 GB');
    });

    test('usa i megabyte senza convertirli in gigabyte', () {
      expect(formatFileSize(524288000), '524.3 MB');
    });

    test('usa i kilobyte per i file piccoli', () {
      expect(formatFileSize(2048), '2 KB');
    });

    test('restituisce un punto interrogativo per valori non disponibili', () {
      expect(formatFileSize(null), '?');
      expect(formatFileSize(-1), '?');
    });
  });

  group('readFileSizeBytes', () {
    test('restituisce la dimensione di un file esistente', () async {
      final dir = Directory.systemTemp.createTempSync('file_size_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/dummy.bin')
        ..writeAsBytesSync(List.filled(10, 0));

      expect(await readFileSizeBytes(file.path), 10);
    });

    test('restituisce null per un percorso inesistente', () async {
      expect(await readFileSizeBytes('/percorso/che/non/esiste.mkv'), isNull);
    });
  });
}
