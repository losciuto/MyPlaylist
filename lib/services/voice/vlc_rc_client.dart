import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Errore nell'invio di un comando all'interfaccia RC del VLC.
class VlcRcException implements Exception {
  const VlcRcException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Client TCP per l'interfaccia RC di VLC.
///
/// Il player viene avviato da MyPlaylist con `--extraintf rc`, quindi la
/// porta configurata in Impostazioni accetta i comandi testuali.
class VlcRcClient {
  VlcRcClient({this.host = '127.0.0.1', required this.port});

  /// Valore di volume che corrisponde al 100%.
  static const int fullVolume = 256;

  /// Quanti passi di volume vale un comando "alza/abbassa il volume".
  static const int volumeStep = 2;

  final String host;
  final int port;

  /// Invia [command] al VLC esterno e restituisce la risposta pulita.
  Future<String> send(String command) async {
    Socket socket;
    try {
      socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 3),
      );
    } on SocketException catch (e) {
      throw VlcRcException(
        'VLC non raggiungibile su $host:$port (${e.osError?.message ?? e.message})',
      );
    } on TimeoutException {
      throw VlcRcException('VLC non raggiungibile su $host:$port');
    }

    final buffer = StringBuffer();
    var waiter = Completer<void>();

    final subscription = socket.listen(
      (data) {
        buffer.write(utf8.decode(data, allowMalformed: true));
        if (!waiter.isCompleted) waiter.complete();
      },
      onError: (_) {
        if (!waiter.isCompleted) waiter.complete();
      },
      onDone: () {
        if (!waiter.isCompleted) waiter.complete();
      },
    );

    try {
      await _waitForData(waiter, const Duration(milliseconds: 600));
      final banner = buffer.toString();
      if (banner.toLowerCase().contains('password')) {
        throw const VlcRcException(
          "L'interfaccia RC di VLC chiede una password: toglila dalla "
          'configurazione di VLC per usare i comandi vocali',
        );
      }

      buffer.clear();
      waiter = Completer<void>();
      socket.write('$command\n');
      await socket.flush();

      await _waitForData(waiter, const Duration(seconds: 2));
      final response = _clean(buffer.toString());

      if (response.toLowerCase().contains('not found')) {
        throw VlcRcException("VLC non conosce il comando '$command'");
      }

      return response;
    } on SocketException catch (e) {
      throw VlcRcException(
        'Comunicazione con VLC interrotta (${e.osError?.message ?? e.message})',
      );
    } finally {
      await subscription.cancel();
      socket.destroy();
    }
  }

  /// Stato corrente della riproduzione: playing, paused, stopped.
  Future<String> playbackState() async {
    final response = await send('status');
    final match = RegExp(r'state\s+(\w+)').firstMatch(response);
    return match?.group(1)?.toLowerCase() ?? '';
  }

  /// True quando la riproduzione e' in pausa.
  Future<bool> isPaused() async => await playbackState() == 'paused';

  /// Secondi trascorsi dall'inizio del brano corrente.
  Future<int> currentTime() async {
    final response = await send('get_time');
    final match = RegExp(r'\d+').firstMatch(response);
    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }

  /// Imposta il volume a una percentuale (0-200).
  Future<void> setVolumePercent(int percent) async {
    final value = (percent * fullVolume / 100).round().clamp(0, 512);
    await send('volume $value');
  }

  /// Verifica che il VLC esterno stia rispondendo sulla porta RC.
  Future<bool> isReachable() async {
    try {
      await send('status');
      return true;
    } on VlcRcException {
      return false;
    }
  }

  /// Toglie il prompt finale e i ritorni a capo dal testo ricevuto.
  String _clean(String raw) {
    var text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    text = text.replaceAll(RegExp(r'>\s*$'), '');
    return text.trim();
  }

  Future<void> _waitForData(Completer<void> waiter, Duration timeout) async {
    try {
      await waiter.future.timeout(timeout);
    } on TimeoutException {
      // Nessun dato nel tempo previsto: si continua con quello raccolto.
    }
  }
}
