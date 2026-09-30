import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/services/database_backup_service.dart';

void main() {
  group('DatabaseBackupService naming', () {
    test('il nome del backup ha prefisso, timestamp e estensione .db', () {
      final name = DatabaseBackupService.fileNameFor(
        DateTime(2026, 9, 30, 18, 5, 14),
      );

      expect(name, startsWith('myplaylist_backup_'));
      expect(name, endsWith('.db'));
    });

    test('il timestamp non contiene i due punti, quindi il nome è valido', () {
      final name = DatabaseBackupService.fileNameFor(
        DateTime(2026, 9, 30, 18, 5, 14),
      );

      expect(name.contains(':'), isFalse);
    });

    test('l\'estensione dichiarata coincide con quella del nome generato', () {
      final name = DatabaseBackupService.fileNameFor(DateTime(2026, 1, 2));

      expect(name.endsWith(DatabaseBackupService.fileExtension), isTrue);
    });
  });
}
