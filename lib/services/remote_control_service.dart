import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import '../providers/playlist_provider.dart';
import 'settings_service.dart';

class RemoteCommandLog {
  final String command;
  final Map<String, dynamic> args;
  final DateTime timestamp;

  RemoteCommandLog({
    required this.command,
    required this.args,
    required this.timestamp,
  });
}

class RemoteControlService with ChangeNotifier {
  final PlaylistProvider playlistProvider;
  final SettingsService settingsService;

  ServerSocket? _server;
  bool _isRunning = false;
  int? _currentPort;
  String? _currentSecret;
  String? _currentInterface;
  
  final List<RemoteCommandLog> _commandLogs = [];
  List<RemoteCommandLog> get commandLogs => List.unmodifiable(_commandLogs);

  bool get isRunning => _isRunning;

  RemoteControlService({
    required this.playlistProvider,
    required this.settingsService,
  }) {
    _currentPort = settingsService.remoteServerPort;
    _currentSecret = settingsService.remoteServerSecret;
    _currentInterface = settingsService.serverInterface;
    settingsService.addListener(_handleSettingsChange);
    if (settingsService.remoteServerEnabled) {
      start();
    }
  }

  void _handleSettingsChange() {
    final bool shouldBeRunning = settingsService.remoteServerEnabled;
    final int newPort = settingsService.remoteServerPort;
    final String newSecret = settingsService.remoteServerSecret;
    final String newInterface = settingsService.serverInterface;

    bool needsRestart = false;

    if (_isRunning && shouldBeRunning) {
      if (newPort != _currentPort || newSecret != _currentSecret || newInterface != _currentInterface) {
        debugPrint('Remote Server settings changed (Port: $_currentPort -> $newPort, Interface: $_currentInterface -> $newInterface, Secret: [REDACTED]). Restarting...');
        needsRestart = true;
      }
    }

    if (needsRestart) {
      restart();
    } else if (shouldBeRunning && !_isRunning) {
      start();
    } else if (!shouldBeRunning && _isRunning) {
      stop();
    }

    _currentPort = newPort;
    _currentSecret = newSecret;
    _currentInterface = newInterface;
  }

  Future<void> restart() async {
    await stop();
    await start();
  }

  Future<void> start() async {
    if (_isRunning) return;

    try {
      final address = settingsService.serverInterface == '0.0.0.0' 
          ? InternetAddress.anyIPv4 
          : InternetAddress(settingsService.serverInterface);
      _server = await ServerSocket.bind(address, settingsService.remoteServerPort);
      _isRunning = true;
      notifyListeners();

      _server!.listen((client) {
        _handleClient(client);
      });
      debugPrint('Remote Server started on port ${settingsService.remoteServerPort}');
    } catch (e) {
      debugPrint('Error starting remote server: $e');
      _isRunning = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    await _server?.close();
    _server = null;
    _isRunning = false;
    notifyListeners();
    debugPrint('Remote Server stopped');
  }

  void _handleClient(Socket client) async {
    debugPrint('Remote Client connected: ${client.remoteAddress.address}');
    
    final List<int> data = [];
    int? expectedLength;

    try {
      // Stream helper to read data
      await for (final chunk in client.timeout(const Duration(seconds: 5))) {
        data.addAll(chunk);
        
        // Se non abbiamo ancora la lunghezza, prova a leggerla dai primi 4 byte
        if (expectedLength == null && data.length >= 4) {
          final header = Uint8List.fromList(data.sublist(0, 4));
          expectedLength = ByteData.view(header.buffer).getUint32(0);
          debugPrint('Expecting $expectedLength bytes of payload');
        }
        
        // Se abbiamo letto tutto il messaggio (4 byte header + payload), usciamo
        if (expectedLength != null && data.length >= 4 + expectedLength) {
          break; 
        }
      }
      
      if (data.length < 4) {
        throw Exception('Incomplete header');
      }
      
      // Il payload effettivo inizia dopo i 4 byte dell'header
      final payload = data.sublist(4, 4 + expectedLength!);
      
      if (payload.length < 12 + 16) {
        throw Exception('Message too short');
      }

      final nonce = payload.sublist(0, 12);
      final mac = payload.sublist(12, 28);
      final ciphertext = payload.sublist(28);

      final cleartext = await _decrypt(ciphertext, nonce, mac);
      final jsonCommand = jsonDecode(utf8.decode(cleartext));
      
      final responseData = await _processCommand(jsonCommand);
      
      client.write(jsonEncode(responseData));
    } catch (e) {
      debugPrint('Error processing remote command: $e');
      client.write(jsonEncode({
        'status': 'error',
        'message': e.toString(),
      }));
    } finally {
      await client.close();
    }
  }

  Future<List<int>> _decrypt(List<int> ciphertext, List<int> nonce, List<int> mac) async {
    final algorithm = AesGcm.with256bits();
    
    // Ensure key is 32 bytes
    final keyBytes = utf8.encode(settingsService.remoteServerSecret);
    final paddedKey = Uint8List(32);
    for (int i = 0; i < keyBytes.length && i < 32; i++) {
        paddedKey[i] = keyBytes[i];
    }

    final secretKey = await algorithm.newSecretKeyFromBytes(paddedKey);
    final secretBox = SecretBox(ciphertext, nonce: nonce, mac: Mac(mac));
    
    return await algorithm.decrypt(secretBox, secretKey: secretKey);
  }

  Future<Map<String, dynamic>> _processCommand(dynamic json) async {
    final command = json['command'] as String?;
    final args = json['args'] as Map<String, dynamic>? ?? {};

    debugPrint('Executing remote command: $command with args: $args');

    // Log the command
    _commandLogs.insert(0, RemoteCommandLog(
      command: command ?? 'unknown',
      args: args,
      timestamp: DateTime.now(),
    ));
    if (_commandLogs.length > 50) {
      _commandLogs.removeLast();
    }
    notifyListeners();

    String message = 'Comando eseguito con successo';

    switch (command) {
      case 'generate_random':
        final count = args['count'] as int? ?? settingsService.defaultPlaylistSize;
        final preview = args['preview'] as bool? ?? false;
        final titles = await playlistProvider.generateRandom(
          count: count,
          launchPlayer: !preview,
        );
        message = preview 
            ? 'Anteprima generata ($count video)' 
            : 'Generata playlist casuale di $count video';
        break;
      case 'generate_recent':
        final count = args['count'] as int? ?? settingsService.defaultPlaylistSize;
        final preview = args['preview'] as bool? ?? false;
        final titles = await playlistProvider.generateRecentPlaylist(
          count: count,
          launchPlayer: !preview,
        );
        message = preview 
            ? 'Anteprima generata ($count video recenti)' 
            : 'Visualizzati i $count video più recenti';
        break;
      case 'generate_filtered':
        final preview = args['preview'] as bool? ?? false;
        final titles = await playlistProvider.generateFilteredPlaylist(
          genres: (args['genres'] as List?)?.cast<String>(),
          years: (args['years'] as List?)?.cast<String>(),
          minRating: (args['min_rating'] as num?)?.toDouble(),
          actors: (args['actors'] as List?)?.cast<String>(),
          directors: (args['directors'] as List?)?.cast<String>(),
          limit: args['limit'] as int? ?? settingsService.defaultPlaylistSize,
          launchPlayer: !preview,
        );
        message = preview 
            ? 'Anteprima generata con i filtri richiesti' 
            : 'Generata playlist con i filtri richiesti';
        break;
      case 'play':
        final path = await playlistProvider.createTempPlaylistFile();
        await playlistProvider.launchPlayer(settingsService.playerPath, path);
        message = 'Playlist avviata su VLC';
        break;
      case 'stop':
        await playlistProvider.stopPlayer();
        message = 'Riproduzione fermata';
        break;
      default:
        throw Exception('Unknown command: $command');
    }

    return {
      'status': 'success',
      'message': message,
      'command': command,
      'playlist': playlistProvider.playlist.map((v) => v.toMap()).toList(),
    };
  }

  @override
  void dispose() {
    stop();
    settingsService.removeListener(_handleSettingsChange);
    super.dispose();
  }
}
