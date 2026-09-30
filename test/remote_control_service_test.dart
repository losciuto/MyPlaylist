import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/models/video.dart';
import 'package:my_playlist/providers/playlist_provider.dart';
import 'package:my_playlist/services/remote_control_service.dart';
import 'package:my_playlist/services/settings_service.dart';

class FakeSettingsService implements SettingsService {
  FakeSettingsService({
    required this.port,
    required this.secret,
    this.interface = '127.0.0.1',
    this.enabled = false,
    this.defaultSize = 20,
    this.configuredPlayerPath = '/usr/bin/vlc',
  });

  int port;
  final String secret;
  String interface;
  bool enabled;
  int defaultSize;
  String configuredPlayerPath;

  final List<VoidCallback> _listeners = [];

  void notifySettingsChanged() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  @override
  bool get remoteServerEnabled => enabled;

  @override
  int get remoteServerPort => port;

  @override
  String get remoteServerSecret => secret;

  @override
  String get serverInterface => interface;

  @override
  int get defaultPlaylistSize => defaultSize;

  @override
  String get playerPath => configuredPlayerPath;

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RecordedCall {
  const RecordedCall(this.name, this.arguments);

  final String name;
  final Map<String, Object?> arguments;
}

class FakePlaylistProvider implements PlaylistProvider {
  final List<RecordedCall> calls = [];

  void _record(String name, [Map<String, Object?> arguments = const {}]) {
    calls.add(RecordedCall(name, arguments));
  }

  @override
  List<Video> get playlist => List<Video>.unmodifiable(_videos);

  final List<Video> _videos = [];

  @override
  Future<List<Map<String, dynamic>>> generateRandom({
    int? count,
    bool launchPlayer = true,
  }) async {
    _record('generateRandom', {'count': count, 'launchPlayer': launchPlayer});
    return <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> generateRecentPlaylist({
    int? count,
    bool launchPlayer = true,
  }) async {
    _record('generateRecent', {'count': count, 'launchPlayer': launchPlayer});
    return <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> generateFilteredPlaylist({
    List<String>? genres,
    List<String>? years,
    double? minRating,
    List<String>? actors,
    List<String>? directors,
    List<String>? excludedGenres,
    List<String>? excludedYears,
    List<String>? excludedActors,
    List<String>? excludedDirectors,
    List<String>? sagas,
    List<String>? excludedSagas,
    int? limit,
    bool launchPlayer = true,
  }) async {
    _record('generateFiltered', {'limit': limit, 'launchPlayer': launchPlayer});
    return <Map<String, dynamic>>[];
  }

  @override
  Future<String> createTempPlaylistFile() async {
    _record('createTempPlaylistFile');
    return '/tmp/playlist.m3u';
  }

  @override
  Future<void> launchPlayer(String playerPath, String playlistPath) async {
    _record('launchPlayer', {
      'playerPath': playerPath,
      'playlistPath': playlistPath,
    });
  }

  @override
  Future<void> stopPlayer() async {
    _record('stopPlayer');
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _secret = 'my_default_secret_key_32chars_long';

Future<Uint8List> _paddedKey() async {
  final keyBytes = utf8.encode(_secret);
  final paddedKey = Uint8List(32);
  for (var i = 0; i < keyBytes.length && i < 32; i++) {
    paddedKey[i] = keyBytes[i];
  }
  return paddedKey;
}

Future<List<int>> encryptPayload(String plainText) async {
  final algorithm = AesGcm.with256bits();
  final secretKey = await algorithm.newSecretKeyFromBytes(await _paddedKey());
  final secretBox = await algorithm.encrypt(
    utf8.encode(plainText),
    secretKey: secretKey,
    nonce: algorithm.newNonce(),
  );

  final result = BytesBuilder();
  result.add(secretBox.nonce);
  result.add(secretBox.mac.bytes);
  result.add(secretBox.cipherText);
  return result.toBytes();
}

/// Trova una porta libera con anche la successiva libera: il servizio remoto
/// apre un HttpServer su porta + 1 per il proxy delle immagini.
Future<int> findFreePortPair() async {
  for (var attempt = 0; attempt < 50; attempt++) {
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();

    try {
      final second = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        port + 1,
      );
      await second.close();
      return port;
    } on SocketException {
      continue;
    }
  }
  throw StateError('Nessuna coppia di porte libere trovata');
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// Il riavvio e' asincrono: isRunning resta true per qualche istante mentre il
/// vecchio server si chiude, quindi si attende che la nuova porta accetti
/// connessioni.
Future<void> _waitForListeningPort(int port) async {
  for (var i = 0; i < 100; i++) {
    try {
      final probe = await Socket.connect('127.0.0.1', port);
      await probe.close();
      return;
    } on SocketException {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }
  throw StateError("Il server non e' in ascolto sulla porta $port");
}

void main() {
  late FakeSettingsService settings;
  late FakePlaylistProvider playlist;
  late RemoteControlService service;
  late int port;

  Future<Map<String, dynamic>> sendCommand(
    Map<String, dynamic> command, {
    int? targetPort,
  }) async {
    final encrypted = await encryptPayload(jsonEncode(command));
    final header = Uint8List(4);
    ByteData.view(header.buffer).setUint32(0, encrypted.length);

    final socket = await Socket.connect('127.0.0.1', targetPort ?? port);
    socket.add(header);
    socket.add(encrypted);
    await socket.flush();

    // La risposta del server non ha header di lunghezza: arriva intera e poi
    // il socket viene chiuso.
    final response = BytesBuilder();
    await for (final chunk in socket) {
      response.add(chunk);
    }
    await socket.close();

    // La richiesta e' cifrata, la risposta del server arriva in chiaro.
    return jsonDecode(utf8.decode(response.toBytes())) as Map<String, dynamic>;
  }

  setUp(() async {
    port = await findFreePortPair();
    settings = FakeSettingsService(port: port, secret: _secret);
    playlist = FakePlaylistProvider();
    service = RemoteControlService(
      playlistProvider: playlist,
      settingsService: settings,
    );
  });

  tearDown(() async {
    await service.stop();
    service.dispose();
  });

  test('start() espone il server e isRunning riflette lo stato', () async {
    expect(service.isRunning, isFalse);

    await service.start();
    expect(service.isRunning, isTrue);

    await service.stop();
    expect(service.isRunning, isFalse);
  });

  test('start() chiamato due volte non duplica il server', () async {
    await service.start();
    await service.start();

    expect(service.isRunning, isTrue);
  });

  test('generate_random in anteprima non lancia il player', () async {
    await service.start();
    final response = await sendCommand({
      'command': 'generate_random',
      'args': {'count': 3, 'preview': true},
    });

    expect(response['status'], 'success');
    expect(response['command'], 'generate_random');
    expect(playlist.calls, hasLength(1));
    expect(playlist.calls.single.name, 'generateRandom');
    expect(playlist.calls.single.arguments['count'], 3);
    expect(playlist.calls.single.arguments['launchPlayer'], isFalse);
  });

  test('senza count il comando usa defaultPlaylistSize', () async {
    await service.start();
    final response = await sendCommand({
      'command': 'generate_random',
      'args': <String, dynamic>{},
    });

    expect(response['status'], 'success');
    expect(playlist.calls.single.arguments['count'], 20);
    expect(playlist.calls.single.arguments['launchPlayer'], isTrue);
  });

  test('generate_filtered inoltra il limite di default', () async {
    await service.start();
    final response = await sendCommand({
      'command': 'generate_filtered',
      'args': {'preview': true},
    });

    expect(response['status'], 'success');
    expect(playlist.calls.single.name, 'generateFiltered');
    expect(playlist.calls.single.arguments['limit'], 20);
    expect(playlist.calls.single.arguments['launchPlayer'], isFalse);
  });

  test(
    'il comando play crea la playlist e usa il player configurato',
    () async {
      settings.configuredPlayerPath = '/usr/bin/mpv';

      await service.start();
      final response = await sendCommand({'command': 'play'});

      expect(response['status'], 'success');
      expect(
        playlist.calls.map((c) => c.name),
        containsAll(<String>['createTempPlaylistFile', 'launchPlayer']),
      );
      final launch = playlist.calls.firstWhere((c) => c.name == 'launchPlayer');
      expect(launch.arguments['playerPath'], '/usr/bin/mpv');
    },
  );

  test('i comandi stop e kill_vlc fermano il player', () async {
    await service.start();

    await sendCommand({'command': 'stop'});
    await sendCommand({'command': 'kill_vlc'});

    expect(playlist.calls.where((c) => c.name == 'stopPlayer'), hasLength(2));
  });

  test('un comando sconosciuto risponde con status error', () async {
    await service.start();
    final response = await sendCommand({'command': 'comando_inesistente'});

    expect(response['status'], 'error');
    expect(response['message'], contains('Unknown command'));
  });

  test('ogni comando viene registrato nei log', () async {
    await service.start();
    await sendCommand({'command': 'stop'});
    await sendCommand({'command': 'stop'});

    expect(service.commandLogs, hasLength(2));
    expect(service.commandLogs.first.command, 'stop');
    expect(service.commandLogs.first.timestamp, isA<DateTime>());
  });

  test('i log non superano le 50 voci', () async {
    await service.start();
    for (var i = 0; i < 55; i++) {
      await sendCommand({'command': 'stop'});
    }

    expect(service.commandLogs, hasLength(50));
  });

  test('commandLogs espone una lista non modificabile', () async {
    await service.start();

    expect(
      () => service.commandLogs.add(
        RemoteCommandLog(
          command: 'x',
          args: const {},
          timestamp: DateTime.now(),
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('il server si riavvia da solo quando cambia la porta', () async {
    settings.enabled = true;
    await service.start();
    final firstPort = port;

    final nextPort = await findFreePortPair();
    settings.port = nextPort;
    settings.notifySettingsChanged();
    await _waitForListeningPort(nextPort);

    expect(service.isRunning, isTrue);

    final response = await sendCommand({
      'command': 'stop',
    }, targetPort: nextPort);
    expect(response['status'], 'success');

    expect(nextPort, isNot(firstPort));
  });

  test('disabilitare il server lo ferma', () async {
    settings.enabled = true;
    await service.start();
    expect(service.isRunning, isTrue);

    settings.enabled = false;
    settings.notifySettingsChanged();
    await _waitFor(() => !service.isRunning);

    expect(service.isRunning, isFalse);
  });
}
