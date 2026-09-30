import 'package:flutter/foundation.dart';

import 'logger_service.dart';

/// Un errore segnalato dall'applicazione, pronto per essere mostrato.
class AppError {
  const AppError({
    required this.title,
    required this.message,
    required this.timestamp,
    this.source,
  });

  final String title;
  final String message;
  final DateTime timestamp;
  final String? source;
}

/// Raccoglie gli errori che oggi venivano solo scritti in console, così
/// l'utente può leggerli senza aprire i log.
///
/// Gli errori restano in memoria: dopo il riavvio l'applicazione riparte
/// pulita, mentre il file di log continua a fare da archivio.
class ErrorReporterService with ChangeNotifier {
  ErrorReporterService();

  static const int maxErrors = 50;

  final List<AppError> _errors = [];

  /// Cronologia, dalla piu' recente alla piu' vecchia.
  List<AppError> get errors => List<AppError>.unmodifiable(_errors);

  int get count => _errors.length;
  bool get isEmpty => _errors.isEmpty;

  void report(String title, Object error, {String? source}) {
    _errors.insert(
      0,
      AppError(
        title: title,
        message: error.toString(),
        timestamp: DateTime.now(),
        source: source,
      ),
    );
    if (_errors.length > maxErrors) {
      _errors.removeRange(maxErrors, _errors.length);
    }
    notifyListeners();
  }

  void clear() {
    if (_errors.isEmpty) return;
    _errors.clear();
    notifyListeners();
  }

  /// Registra l'errore e lo scrive anche nel file di log.
  Future<void> reportAndLog(
    String title,
    Object error, {
    String? source,
  }) async {
    report(title, error, source: source);
    await LoggerService().error(
      source == null ? title : '$source - $title',
      error,
    );
  }
}

ErrorReporterService errorReporter = ErrorReporterService();
