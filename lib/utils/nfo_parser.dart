import 'dart:io';
import 'package:flutter/foundation.dart';
import 'nfo_strategies/nfo_strategy.dart';
import 'nfo_strategies/kodi_nfo_strategy.dart';

class NfoParser {
  static final List<NfoStrategy> _strategies = [
    KodiNfoStrategy(),
    // Add new strategies here (e.g., PlexNfoStrategy, etc.)
  ];

  static Future<Map<String, dynamic>?> parseNfo(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      
      // Find first '<' to skip any ASCII art preamble
      final startIndex = content.indexOf('<');
      if (startIndex == -1) {
        debugPrint('DEBUG: NFO file at $path does not contain XML.');
        return null;
      }
      final cleanContent = content.substring(startIndex);

      for (final strategy in _strategies) {
        if (strategy.canParse(cleanContent)) {
          return await strategy.parse(cleanContent, path);
        }
      }

      debugPrint('No suitable strategy found for NFO: $path');
      return null;
    } catch (e) {
      debugPrint('Error parsing NFO ($path): $e');
      return null;
    }
  }
}
