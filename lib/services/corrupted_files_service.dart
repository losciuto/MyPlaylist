import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:my_playlist/repositories/video_repository.dart';
import 'package:my_playlist/services/logger_service.dart';

/// Rappresenta un file video corrotto rilevato durante le operazioni.
class CorruptedFileEntry {
  const CorruptedFileEntry({
    required this.path,
    required this.videoId,
    required this.title,
    required this.detectedAt,
    this.errorDetails,
    this.status = CorruptedFileStatus.detected,
    this.lastVerifiedAt,
    this.verificationResult,
  });

  final String path;
  final int? videoId;
  final String title;
  final DateTime detectedAt;
  final String? errorDetails;
  final CorruptedFileStatus status;
  final DateTime? lastVerifiedAt;
  final String? verificationResult;

  CorruptedFileEntry copyWith({
    String? path,
    int? videoId,
    String? title,
    DateTime? detectedAt,
    String? errorDetails,
    CorruptedFileStatus? status,
    DateTime? lastVerifiedAt,
    String? verificationResult,
  }) {
    return CorruptedFileEntry(
      path: path ?? this.path,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      detectedAt: detectedAt ?? this.detectedAt,
      errorDetails: errorDetails ?? this.errorDetails,
      status: status ?? this.status,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      verificationResult: verificationResult ?? this.verificationResult,
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'videoId': videoId,
        'title': title,
        'detectedAt': detectedAt.toIso8601String(),
        'errorDetails': errorDetails,
        'status': status.name,
        'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
        'verificationResult': verificationResult,
      };

  static CorruptedFileEntry fromJson(Map<String, dynamic> json) =>
      CorruptedFileEntry(
        path: json['path'] as String,
        videoId: json['videoId'] as int?,
        title: json['title'] as String,
        detectedAt: DateTime.parse(json['detectedAt'] as String),
        errorDetails: json['errorDetails'] as String?,
        status: CorruptedFileStatus.values.byName(json['status'] as String),
        lastVerifiedAt: json['lastVerifiedAt'] != null
            ? DateTime.parse(json['lastVerifiedAt'] as String)
            : null,
        verificationResult: json['verificationResult'] as String?,
      );
}

enum CorruptedFileStatus {
  detected,
  verifiedCorrupted,
  verifiedOk,
  removedFromDb,
  movedToQuarantine,
  retryPending,
}

/// Servizio per tracciare e gestire i file video corrotti.
class CorruptedFilesService with ChangeNotifier {
  CorruptedFilesService([VideoRepository? repository])
      : _repository = repository ?? videoRepository;

  static const int maxEntries = 200;
  final VideoRepository _repository;

  final List<CorruptedFileEntry> _entries = [];
  bool _initialized = false;

  List<CorruptedFileEntry> get entries => List<CorruptedFileEntry>.unmodifiable(_entries);
  int get count => _entries.length;
  bool get isEmpty => _entries.isEmpty;

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadFromDisk();
    _initialized = true;
  }

  Future<void> _loadFromDisk() async {
    try {
      final file = File(_getStoragePath());
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(content);
          _entries.addAll(jsonList.map((e) => CorruptedFileEntry.fromJson(e)));
          _entries.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
        }
      }
    } on Exception catch (e) {
      LoggerService().debug('Error loading corrupted files log: $e');
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final file = File(_getStoragePath());
      await file.parent.create(recursive: true);
      final jsonList = _entries.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } on Exception catch (e) {
      LoggerService().error('Error saving corrupted files log', e);
    }
  }

  String _getStoragePath() {
    final appDir = Platform.environment['APPDATA'] ??
        Platform.environment['HOME'] ??
        '/tmp';
    return p.join(appDir, 'MyPlaylist', 'corrupted_files.json');
  }

  /// Registra un file come potenzialmente corrotto.
  Future<void> reportCorruptedFile({
    required String path,
    required String title,
    int? videoId,
    String? errorDetails,
  }) async {
    // Evita duplicati per lo stesso path
    final existingIndex = _entries.indexWhere((e) => e.path == path);
    if (existingIndex >= 0) {
      final existing = _entries[existingIndex];
      if (existing.status == CorruptedFileStatus.detected ||
          existing.status == CorruptedFileStatus.retryPending) {
        return; // Già registrato e non ancora verificato
      }
      // Se era verificato OK ma ora fallisce di nuovo, riapri
      if (existing.status == CorruptedFileStatus.verifiedOk) {
        _entries[existingIndex] = existing.copyWith(
          status: CorruptedFileStatus.detected,
          errorDetails: errorDetails,
          detectedAt: DateTime.now(),
        );
      }
    } else {
      _entries.insert(
        0,
        CorruptedFileEntry(
          path: path,
          videoId: videoId,
          title: title,
          detectedAt: DateTime.now(),
          errorDetails: errorDetails,
        ),
      );
    }

    // Limita la dimensione
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }

    notifyListeners();
    await _saveToDisk();
  }

  /// Verifica un singolo file con ffmpeg.
  Future<CorruptedFileEntry> verifyFile(CorruptedFileEntry entry) async {
    final file = File(entry.path);
    if (!await file.exists()) {
      final updated = entry.copyWith(
        status: CorruptedFileStatus.verifiedCorrupted,
        lastVerifiedAt: DateTime.now(),
        verificationResult: 'File non trovato su disco',
      );
      await _updateEntry(entry, updated);
      return updated;
    }

    try {
      final result = await Process.run('ffmpeg', [
        '-v', 'error',
        '-i', entry.path,
        '-f', 'null', '-',
      ]);

      if (result.exitCode == 0) {
        final updated = entry.copyWith(
          status: CorruptedFileStatus.verifiedOk,
          lastVerifiedAt: DateTime.now(),
          verificationResult: 'OK - File leggibile',
        );
        await _updateEntry(entry, updated);
        return updated;
      } else {
        final stderr = result.stderr.toString();
        final updated = entry.copyWith(
          status: CorruptedFileStatus.verifiedCorrupted,
          lastVerifiedAt: DateTime.now(),
          verificationResult: 'Corrotto: ${stderr.substring(0, stderr.length > 200 ? 200 : stderr.length)}',
        );
        await _updateEntry(entry, updated);
        return updated;
      }
    } on Exception catch (e) {
      final updated = entry.copyWith(
        status: CorruptedFileStatus.verifiedCorrupted,
        lastVerifiedAt: DateTime.now(),
        verificationResult: 'Errore verifica: $e',
      );
      await _updateEntry(entry, updated);
      return updated;
    }
  }

  /// Verifica tutti i file non ancora verificati.
  Future<void> verifyAllUnverified() async {
    final unverified = _entries
        .where((e) =>
            e.status == CorruptedFileStatus.detected ||
            e.status == CorruptedFileStatus.retryPending)
        .toList();

    for (final entry in unverified) {
      await verifyFile(entry);
    }
  }

  Future<void> _updateEntry(CorruptedFileEntry oldEntry, CorruptedFileEntry newEntry) async {
    final index = _entries.indexWhere((e) => e.path == oldEntry.path);
    if (index >= 0) {
      _entries[index] = newEntry;
      notifyListeners();
      await _saveToDisk();
    }
  }

  /// Rimuove il video dal database.
  Future<void> removeFromDatabase(CorruptedFileEntry entry) async {
    if (entry.videoId != null) {
      await _repository.deleteVideo(entry.videoId!);
    }
    final updated = entry.copyWith(status: CorruptedFileStatus.removedFromDb);
    await _updateEntry(entry, updated);
  }

  /// Sposta il file in una cartella di quarantena.
  Future<void> moveToQuarantine(CorruptedFileEntry entry) async {
    final file = File(entry.path);
    if (!await file.exists()) return;

    final quarantineDir = Directory(p.join(p.dirname(entry.path), '.corrupted_quarantine'));
    if (!await quarantineDir.exists()) {
      await quarantineDir.create(recursive: true);
    }

    final fileName = p.basename(entry.path);
    final targetPath = p.join(quarantineDir.path, fileName);

    try {
      await file.rename(targetPath);
      final updated = entry.copyWith(
        status: CorruptedFileStatus.movedToQuarantine,
        verificationResult: 'Spostato in: $targetPath',
      );
      await _updateEntry(entry, updated);
    } on Exception catch (e) {
      LoggerService().error('Failed to move to quarantine', e);
      // Fallback: copy + delete
      try {
        await file.copy(targetPath);
        await file.delete();
        final updated = entry.copyWith(
          status: CorruptedFileStatus.movedToQuarantine,
          verificationResult: 'Copiato e rimosso: $targetPath',
        );
        await _updateEntry(entry, updated);
      } on Exception catch (e2) {
        LoggerService().error('Failed to copy to quarantine', e2);
      }
    }
  }

  /// Segna per ritentare i metadati.
  Future<void> markForRetry(CorruptedFileEntry entry) async {
    final updated = entry.copyWith(
      status: CorruptedFileStatus.retryPending,
    );
    await _updateEntry(entry, updated);
  }

  /// Rimuove una entry dalla lista.
  Future<void> removeEntry(CorruptedFileEntry entry) async {
    _entries.removeWhere((e) => e.path == entry.path);
    notifyListeners();
    await _saveToDisk();
  }

  /// Pulisce tutte le entry verificate OK.
  Future<void> clearVerifiedOk() async {
    _entries.removeWhere((e) => e.status == CorruptedFileStatus.verifiedOk);
    notifyListeners();
    await _saveToDisk();
  }

  /// Pulisce tutta la lista.
  Future<void> clearAll() async {
    _entries.clear();
    notifyListeners();
    await _saveToDisk();
  }
}