import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import '../providers/playlist_provider.dart';
import 'settings_service.dart';

class RemoteControlService with ChangeNotifier {
  final PlaylistProvider playlistProvider;
  final SettingsService settingsService;

  ServerSocket? _server;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  RemoteControlService({
    required this.playlistProvider,
    required this.settingsService,
  }) {
    settingsService.addListener(_handleSettingsChange);
    if (settingsService.remoteServerEnabled) {
      start();
    }
  }

  void _handleSettingsChange() {
    if (settingsService.remoteServerEnabled && !_isRunning) {
      start();
    } else if (!settingsService.remoteServerEnabled && _isRunning) {
      stop();
    }
  }

  Future<void> start() async {
    if (_isRunning) return;

    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, settingsService.remoteServerPort);
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
    
    // Read all data from client
    final List<int> data = [];
    await for (final chunk in client) {
      data.addAll(chunk);
      // For simplicity, we assume one command per connection or end of stream
    }

    try {
      if (data.length < 12 + 16) {
        throw Exception('Message too short');
      }

      final nonce = data.sublist(0, 12);
      final mac = data.sublist(12, 28);
      final ciphertext = data.sublist(28);

      final cleartext = await _decrypt(ciphertext, nonce, mac);
      final json = jsonDecode(utf8.decode(cleartext));
      
      await _processCommand(json);
      
      client.write('OK');
    } catch (e) {
      debugPrint('Error processing remote command: $e');
      client.write('ERROR: $e');
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

  Future<void> _processCommand(dynamic json) async {
    final command = json['command'] as String?;
    final args = json['args'] as Map<String, dynamic>? ?? {};

    debugPrint('Executing remote command: $command with args: $args');

    switch (command) {
      case 'generate_random':
        final count = args['count'] as int? ?? settingsService.defaultPlaylistSize;
        await playlistProvider.generateRandom(count);
        break;
      case 'generate_recent':
        final count = args['count'] as int? ?? settingsService.defaultPlaylistSize;
        await playlistProvider.generateRecent(count);
        break;
      case 'generate_filtered':
        await playlistProvider.generateFiltered(
          genres: (args['genres'] as List?)?.cast<String>(),
          years: (args['years'] as List?)?.cast<String>(),
          minRating: (args['min_rating'] as num?)?.toDouble(),
          actors: (args['actors'] as List?)?.cast<String>(),
          directors: (args['directors'] as List?)?.cast<String>(),
          limit: args['limit'] as int? ?? settingsService.defaultPlaylistSize,
        );
        break;
      case 'play':
        // This requires player path. We should probably use settings
        final path = await playlistProvider.createTempPlaylistFile();
        await playlistProvider.launchPlayer(settingsService.playerPath, path);
        break;
      case 'stop':
        // Add stop logic to provider if needed, or just kill process
        // For now, let's assume we can just re-launch or similar
        break;
      default:
        throw Exception('Unknown command: $command');
    }
  }

  @override
  void dispose() {
    stop();
    settingsService.removeListener(_handleSettingsChange);
    super.dispose();
  }
}
