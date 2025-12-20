import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

Future<void> main() async {
  final host = '127.0.0.1';
  final port = 8080;
  final secret = 'my_default_secret_key_32chars_long';

  final command = {
    'command': 'generate_random',
    'args': {'count': 5}
  };

  print('Sending command: $command');

  try {
    final ciphertext = await encrypt(jsonEncode(command), secret);
    
    final socket = await Socket.connect(host, port);
    socket.add(ciphertext);
    await socket.flush();
    
    await for (final data in socket) {
      print('Response from server: ${utf8.decode(data)}');
    }
    
    await socket.close();
  } catch (e) {
    print('Error: $e');
  }
}

Future<List<int>> encrypt(String plainText, String secret) async {
  final algorithm = AesGcm.with256bits();
  
  // Ensure key is 32 bytes
  final keyBytes = utf8.encode(secret);
  final paddedKey = Uint8List(32);
  for (int i = 0; i < keyBytes.length && i < 32; i++) {
      paddedKey[i] = keyBytes[i];
  }

  final secretKey = await algorithm.newSecretKeyFromBytes(paddedKey);
  final nonce = algorithm.newNonce();
  
  final secretBox = await algorithm.encrypt(
    utf8.encode(plainText),
    secretKey: secretKey,
    nonce: nonce,
  );

  final result = BytesBuilder();
  result.add(secretBox.nonce);
  result.add(secretBox.mac.bytes);
  result.add(secretBox.cipherText);
  
  return result.toBytes();
}
