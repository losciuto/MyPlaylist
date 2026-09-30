import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Esegue un processo esterno con timeout, raccogliendone l'output.
///
/// I chiamanti esterni (mkvpropedit, MP4Box, ffmpeg) condividono la stessa
/// logica: avvio, timer di sicurezza, attesa del codice di uscita e
/// normalizzazione del messaggio d'errore.
class ProcessRunner {
  const ProcessRunner._();

  static const String timeoutMarker = 'timeout_too_slow';

  static Future<ProcessRunOutcome> runWithTimeout(
    String executable,
    List<String> arguments, {
    Duration timeout = const Duration(seconds: 30),
    FutureOr<void> Function()? onFinished,
  }) async {
    final process = await Process.start(executable, arguments);

    // I flussi vengono consumati subito: senza drain una pipe piena
    // bloccherebbe il processo e l'attesa del codice di uscita.
    final stdout = process.stdout.transform(utf8.decoder).join();
    final stderr = process.stderr.transform(utf8.decoder).join();

    var timedOut = false;
    final timer = Timer(timeout, () {
      timedOut = true;
      process.kill();
    });

    try {
      final exitCode = await process.exitCode;
      return ProcessRunOutcome(
        exitCode: exitCode,
        stdout: await stdout,
        stderr: await stderr,
        timedOut: timedOut,
      );
    } finally {
      timer.cancel();
      if (onFinished != null) {
        await onFinished();
      }
    }
  }

  /// Rende il messaggio di un errore adatto a un singolo riga di log.
  static String sanitize(String message) =>
      message.replaceAll('\n', ' ').replaceAll('\r', ' ').replaceAll(':', ';');
}

class ProcessRunOutcome {
  const ProcessRunOutcome({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.timedOut,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
  final bool timedOut;

  bool get succeeded => exitCode == 0 && !timedOut;

  /// Messaggio d'errore: stderr se presente, altrimenti stdout, altrimenti
  /// il codice di uscita.
  String get errorMessage {
    final message = stderr.trim().isNotEmpty ? stderr.trim() : stdout.trim();
    if (message.isEmpty) return 'Exit code: $exitCode';
    return ProcessRunner.sanitize(message);
  }
}
