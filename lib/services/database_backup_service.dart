import 'dart:io';

import 'package:path/path.dart' as p;

import '../database/app_database.dart' as db;

enum DatabaseBackupStatus { success, cancelled, notFound, invalidFile, failed }

class DatabaseBackupOutcome {
  const DatabaseBackupOutcome(this.status, {this.path, this.error});

  final DatabaseBackupStatus status;
  final String? path;
  final String? error;
}

class DatabaseBackupService {
  static const String fileExtension = '.db';
  static const String filePrefix = 'myplaylist_backup_';

  static String fileNameFor(DateTime timestamp) {
    final stamp = timestamp
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    return '$filePrefix$stamp$fileExtension';
  }

  Future<bool> databaseFileExists() async {
    final dbPath = await db.AppDatabase.instance.getDatabasePath();
    return File(dbPath).exists();
  }

  Future<DatabaseBackupOutcome> exportTo(String? outputDir) async {
    if (outputDir == null) {
      return const DatabaseBackupOutcome(DatabaseBackupStatus.cancelled);
    }

    try {
      final dbPath = await db.AppDatabase.instance.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        return const DatabaseBackupOutcome(DatabaseBackupStatus.notFound);
      }

      final newPath = p.join(outputDir, fileNameFor(DateTime.now()));
      await dbFile.copy(newPath);
      return DatabaseBackupOutcome(DatabaseBackupStatus.success, path: newPath);
    } on Exception catch (e) {
      return DatabaseBackupOutcome(
        DatabaseBackupStatus.failed,
        error: e.toString(),
      );
    }
  }

  Future<DatabaseBackupOutcome> importFrom(String? backupPath) async {
    if (backupPath == null) {
      return const DatabaseBackupOutcome(DatabaseBackupStatus.cancelled);
    }

    if (!backupPath.endsWith(fileExtension)) {
      return const DatabaseBackupOutcome(DatabaseBackupStatus.invalidFile);
    }

    try {
      await db.AppDatabase.instance.close();

      final dbPath = await db.AppDatabase.instance.getDatabasePath();
      await File(backupPath).copy(dbPath);
      return DatabaseBackupOutcome(
        DatabaseBackupStatus.success,
        path: backupPath,
      );
    } on Exception catch (e) {
      return DatabaseBackupOutcome(
        DatabaseBackupStatus.failed,
        error: e.toString(),
      );
    }
  }
}
