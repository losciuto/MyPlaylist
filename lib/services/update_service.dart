import 'dart:async';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'github_service.dart';

/// Suffix dell'asset che contiene l'impronta SHA-256 del binario.
///
/// Convenzione uguale a quella usata da VlcRemote: `<nomefile>.sha256`, con
/// il formato `<64 caratteri esadecimali>  <nomefile>` prodotto da
/// `sha256sum`. Se il rilascio non pubblica questo asset, l'installazione
/// automatica viene rifiutata: meglio far aprire il file all'utente che
/// eseguire un binario di cui non si puo' dimostrare l'origine.
const String checksumSuffix = '.sha256';

/// Sopra questa dimensione il download viene abortito.
///
/// Un rilascio di MyPlaylist pesa pochi megabyte: oltre il limite c'e' quasi
/// certamente un errore o una risposta malformata, e continuare significherebbe
/// scrivere arbitrariamente in memoria e su disco.
const int maxDownloadBytes = 200 * 1024 * 1024;

const Duration _downloadTimeout = Duration(minutes: 15);

/// Esito dello scaricamento di un aggiornamento.
sealed class UpdateEvent {
  const UpdateEvent();
}

/// Avanzamento dello scaricamento, da 0.0 a 1.0.
class DownloadProgress extends UpdateEvent {
  const DownloadProgress(this.value);

  final double value;
}

/// Il file e' stato scaricato e verificato: [install] dice se e' stato anche
/// installato o se l'utente deve aprirlo a mano.
class UpdateFinished extends UpdateEvent {
  const UpdateFinished(
    this.file, {
    required this.verified,
    this.installed = false,
    this.message,
  });

  final File file;

  /// Vero se l'impronta SHA-256 coincideva con quella pubblicata dal
  /// rilascio. Senza verifica [installed] resta sempre falso.
  final bool verified;

  final bool installed;
  final String? message;
}

/// L'installazione automatica non e' stata tentata, perche' il rilascio non
/// pubblica un'impronta: il file e' pero' stato scaricato.
class UpdateNeedsManualAction extends UpdateEvent {
  const UpdateNeedsManualAction(this.file, {this.message});

  final File file;
  final String? message;
}

/// Errore durante il download o l'installazione.
///
/// Le eccezioni qui sono solo per i fallimenti veri: un esito che richiede
/// un'azione manuale e' un [UpdateEvent], non un'eccezione. La versione
/// precedente lanciava eccezioni anche quando l'aggiornamento era andato bene,
/// e il dialog mostrava quindi "Errore durante l'aggiornamento" dopo un
/// aggiornamento riuscito.
class UpdateFailure implements Exception {
  UpdateFailure(this.message);

  final String message;

  @override
  String toString() => 'UpdateFailure: $message';
}

class UpdateService {
  factory UpdateService() => _instance;

  UpdateService._({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? _systemTemporaryDirectory;

  /// Per i test: senza un'applicazione Flutter non esiste il binding che
  /// `path_provider` usa per trovare la directory temporanea, quindi la
  /// directory viene iniettata.
  @visibleForTesting
  factory UpdateService.forTesting(Future<Directory> Function() provider) =>
      UpdateService._(directoryProvider: provider);

  static final UpdateService _instance = UpdateService._();

  static Future<Directory> _systemTemporaryDirectory() =>
      getTemporaryDirectory();

  final Future<Directory> Function() _directoryProvider;

  /// Scarica l'asset dell'aggiornamento e, se l'impronta coincide con quella
  /// pubblicata dal rilascio, lo installa.
  ///
  /// [confirmInstall] viene chiamata prima di installare: se l'utente dice di
  /// no, il file resta su disco e l'esito e' [UpdateFinished] con
  /// `installed: false`.
  Stream<UpdateEvent> downloadAndInstall(
    UpdateInfo updateInfo, {
    Future<bool> Function()? confirmInstall,
  }) async* {
    final fileName = p.basename(updateInfo.assetName ?? updateInfo.downloadUrl);
    if (fileName.isEmpty) {
      throw UpdateFailure('Nome del file non riconoscibile nel rilascio');
    }

    final dir = await _directoryProvider();
    final target = File(p.join(dir.path, fileName));

    yield* _download(updateInfo, target);

    final expectedHash = await _fetchExpectedHash(updateInfo.downloadUrl);
    if (expectedHash == null) {
      // Non si installa: si consegna il file e si lascia decidere all'utente.
      yield UpdateNeedsManualAction(
        target,
        message:
            'Il rilascio non pubblica l\'impronta SHA-256 ($checksumSuffix), '
            'quindi l\'installazione automatica è stata saltata. '
            'Apri ${target.path} per installarlo.',
      );
      return;
    }

    final actualHash = await _sha256Of(target);
    if (actualHash != expectedHash) {
      // Il file non viene neanche conservato: tenere in giro un binario che
      // non corrisponde all'annuncio e' peggio che non avere nulla.
      await _deleteQuietly(target);
      throw UpdateFailure(
        'Impronta SHA-256 non corrispondente: attesa $expectedHash, '
        'ottenuta $actualHash. Il file è stato scartato.',
      );
    }

    if (confirmInstall != null && !await confirmInstall()) {
      yield UpdateFinished(
        target,
        verified: true,
        message: 'Aggiornamento scaricato e verificato: ${target.path}',
      );
      return;
    }

    final message = await _install(target, fileName);
    if (message == null) {
      yield UpdateFinished(target, verified: true, installed: true);
    } else {
      yield UpdateFinished(target, verified: true, message: message);
    }
  }

  /// Scrive il file su `.part` e lo rinomina solo a download completato.
  ///
  /// Il rinominamento finale e' quello che rende sicura la cache: se il
  /// download si interrompe, il file `.part` non viene mai preso per un
  /// aggiornamento valido al giro successivo.
  Stream<UpdateEvent> _download(UpdateInfo updateInfo, File target) async* {
    final client = http.Client();
    File? partial;
    try {
      final request = http.Request('GET', Uri.parse(updateInfo.downloadUrl));
      request.followRedirects = true;
      final response = await client.send(request).timeout(_downloadTimeout);

      if (response.statusCode != 200) {
        throw UpdateFailure('Download fallito: HTTP ${response.statusCode}');
      }

      final total = response.contentLength ?? 0;
      if (total > maxDownloadBytes) {
        throw UpdateFailure(
          'File troppo grande (${total ~/ (1024 * 1024)} MB)',
        );
      }

      partial = File('${target.path}.part');
      var received = 0;
      final sink = partial.openWrite();
      try {
        await for (final chunk in response.stream) {
          received += chunk.length;
          if (received > maxDownloadBytes) {
            throw UpdateFailure(
              'Download interrotto a $received byte: il file supera il limite '
              'consentito',
            );
          }
          sink.add(chunk);
          if (total > 0) yield DownloadProgress(received / total);
        }
      } finally {
        await sink.close();
      }

      if (received == 0) {
        throw UpdateFailure('Download fallito: risposta vuota');
      }

      if (target.existsSync()) target.deleteSync();
      partial.renameSync(target.path);
      partial = null;
      yield DownloadProgress(1);
    } on UpdateFailure {
      rethrow;
    } on TimeoutException catch (e) {
      throw UpdateFailure('Download scaduto: $e');
    } on SocketException catch (e) {
      throw UpdateFailure('Connessione persa durante il download: $e');
    } on http.ClientException catch (e) {
      throw UpdateFailure('Download fallito: $e');
    } finally {
      client.close();
      // Un `.part` lasciato indietro occuperebbe disco e potrebbe essere
      // scambiato per un download completo.
      if (partial != null) await _deleteQuietly(partial);
    }
  }

  /// Legge l'asset `<file>.sha256` e ne estrae l'impronta.
  Future<String?> _fetchExpectedHash(String downloadUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$downloadUrl$checksumSuffix'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      // Formato atteso: "<64 caratteri esadecimali>  <nomefile>".
      final match = RegExp(r'\b([0-9a-fA-F]{64})\b').firstMatch(response.body);
      return match?.group(1)?.toLowerCase();
    } on Object {
      // L'asset puo' non esistere: e' un esito previsto, non un errore.
      return null;
    }
  }

  /// Installa il file gia' verificato.
  ///
  /// Restituisce `null` se l'installazione e' stata eseguita, un messaggio
  /// se l'utente deve fare un passo finale a mano.
  Future<String?> _install(File file, String fileName) async {
    final name = p.basename(fileName).toLowerCase();

    if (Platform.isLinux) {
      if (name.endsWith('.appimage')) {
        await Process.run('chmod', ['+x', file.path]);
        await Process.start(file.path, [], runInShell: true);
        return null;
      }
      if (name.endsWith('.deb')) {
        final result = await Process.run('pkexec', ['dpkg', '-i', file.path]);
        if (result.exitCode != 0) {
          throw UpdateFailure('Installazione non riuscita: ${result.stderr}');
        }
        return null;
      }
      if (name.endsWith('.tar.gz')) {
        final extractDir = p.dirname(file.path);
        final result = await Process.run('tar', [
          '-xzf',
          file.path,
          '-C',
          extractDir,
        ]);
        if (result.exitCode != 0) {
          throw UpdateFailure('Estrazione non riuscita: ${result.stderr}');
        }
        return 'Estratto in $extractDir. Avvia manualmente l\'applicazione.';
      }
    } else if (Platform.isWindows) {
      if (name.endsWith('.exe')) {
        await Process.start(file.path, [], runInShell: true);
        return null;
      }
      if (name.endsWith('.msix')) {
        final result = await Process.run('powershell', [
          '-Command',
          'Add-AppxPackage -Path "${file.path}"',
        ]);
        if (result.exitCode != 0) {
          throw UpdateFailure('Installazione non riuscita: ${result.stderr}');
        }
        return null;
      }
    } else if (Platform.isAndroid) {
      if (name.endsWith('.apk')) {
        // Su Android un file in /data/data non e' installabile con un semplice
        // tocco: serve passare per il package installer.
        return 'Apri il file ${file.path} per completare l\'installazione.';
      }
    }

    return 'File scaricato e verificato: ${file.path}. '
        'Apri manualmente per aggiornare.';
  }

  /// Calcola l'impronta a blocchi, senza tenere il file in memoria: un
  /// AppImage puo' pesare piu' di quanto sia saggio caricare tutto in una
  /// volta.
  Future<String> _sha256Of(File file) async {
    final sink = Sha256().newHashSink();
    await for (final chunk in file.openRead()) {
      sink.add(chunk);
    }
    sink.close();
    return (await sink.hash()).toString();
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (file.existsSync()) file.deleteSync();
    } on FileSystemException {
      // Un file che non si riesce a cancellare non deve far fallire
      // l'operazione: l'utente vede comunque l'errore vero che l'ha causata.
    }
  }
}
