import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

class NfoParser {
  static Future<Map<String, dynamic>?> parseNfo(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;

      String content = await file.readAsString();
      
      // Clean content: find first '<' to skip any ASCII art preamble
      final startIndex = content.indexOf('<');
      if (startIndex == -1) {
        print('DEBUG: NFO file at $path does not contain XML.');
        return null;
      }
      content = content.substring(startIndex);

      final document = XmlDocument.parse(content);
      
      String clean(String s) {
        return s.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '') // Zero-width characters and BOM
                .trim();
      }

      String? getString(String tag) {
        final nodes = document.findAllElements(tag);
        return nodes.isEmpty ? null : clean(nodes.first.innerText);
      }

      List<String> getList(String tag) {
        return document.findAllElements(tag)
            .map((e) => clean(e.innerText))
            .where((s) => s.isNotEmpty)
            .toList();
      }

      final title = getString('title') ?? getString('originaltitle');
      final year = getString('year') ?? getString('premiered')?.split('-').firstOrNull;
      final genres = getList('genre');
      final directors = getList('director');
      final plot = getString('plot') ?? getString('outline');
      
      final safeActors = <String>[];
      for (final actorNode in document.findAllElements('actor')) {
         try {
           final nameNode = actorNode.findElements('name').firstOrNull;
           if (nameNode != null && nameNode.innerText.trim().isNotEmpty) {
             safeActors.add(nameNode.innerText.trim());
           }
         } catch (_) {}
      }

      String? rating;
      // 1. Try userrating first
      rating = getString('userrating');
      if (rating != null && rating.isNotEmpty) {
        print('DEBUG [NfoParser]: Found userrating: $rating for $title');
      }

      // 2. Try complex rating tags (Kodi standard)
      if (rating == null || rating.isEmpty) {
        final ratingNodes = document.findAllElements('rating');
        XmlElement? bestNode;

        for (final node in ratingNodes) {
          final nameLabel = node.getAttribute('name') ?? 'unknown';
          final isDefault = node.getAttribute('default') == 'true';
          print('DEBUG [NfoParser]: XML Node found: name=$nameLabel, default=$isDefault');

          if (isDefault) {
            bestNode = node;
            break;
          }
          bestNode ??= node;
        }

        if (bestNode != null) {
          final valueNode = bestNode.findElements('value').firstOrNull;
          if (valueNode != null) {
            rating = valueNode.innerText.trim();
            print('DEBUG [NfoParser]: Extracted value from XML <value> tag: $rating');
          } else {
            final nodeText = bestNode.innerText.trim();
            if (double.tryParse(nodeText.replaceAll(',', '.')) != null) {
              rating = nodeText;
              print('DEBUG [NfoParser]: Extracted value from XML <rating> text: $rating');
            }
          }
        }
      }

      // 3. REGEX FALLBACK (Aggressive)
      if (rating == null || rating.isEmpty || rating == '0' || rating == '0.0') {
        print('DEBUG [NfoParser]: XML parsing returned 0 or null. Trying REGEX fallback...');
        
        // Try to find rating with default="true" and its <value>
        final defaultRegex = RegExp(r'<rating[^>]*default="true"[^>]*>.*?<value>(.*?)<\/value>', dotAll: true, caseSensitive: false);
        final defaultMatch = defaultRegex.firstMatch(content);
        if (defaultMatch != null) {
          rating = defaultMatch.group(1)?.trim();
          print('DEBUG [NfoParser]: REGEX found default rating: $rating');
        } else {
          // Try any <rating> with <value>
          final valueRegex = RegExp(r'<rating[^>]*>.*?<value>(.*?)<\/value>', dotAll: true, caseSensitive: false);
          final valueMatch = valueRegex.firstMatch(content);
          if (valueMatch != null) {
            rating = valueMatch.group(1)?.trim();
            print('DEBUG [NfoParser]: REGEX found any rating value: $rating');
          } else {
            // Try simple <rating>1.2</rating>
            final simpleRegex = RegExp(r'<rating[^>]*>([^<]+)<\/rating>', caseSensitive: false);
            final simpleMatch = simpleRegex.firstMatch(content);
            if (simpleMatch != null) {
              rating = simpleMatch.group(1)?.trim();
              print('DEBUG [NfoParser]: REGEX found simple rating text: $rating');
            }
          }
        }
      }

      // 4. Final cleaning and check
      if (rating == null || rating.isEmpty) {
        rating = getString('rating'); // Final XML attempt
      }

      final duration = getString('runtime');
      final thumb = getString('thumb');
      
      // Extract Saga (Set)
      String? saga;
      final setNode = document.findAllElements('set').firstOrNull;
      if (setNode != null) {
        final nameNode = setNode.findElements('name').firstOrNull;
        if (nameNode != null) {
          saga = clean(nameNode.innerText);
        } else {
          // Fallback if <set> contains the name directly
          saga = clean(setNode.innerText);
        }
      }

      final finalRating = double.tryParse((rating ?? '').replaceAll(',', '.')) ?? 0.0;
      print('DEBUG [NfoParser]: FINAL RATING for "$title" is: $finalRating (from raw: $rating)');

      return {
        'title': title,
        'genres': genres.join(', '),
        'year': year,
        'directors': directors.join(', '),
        'plot': plot,
        'actors': safeActors.join(', '),
        'rating': finalRating,
        'duration': duration,
        'poster': thumb,
        'saga': saga,
      };
    } catch (e) {
      debugPrint('Error parsing NFO ($path): $e');
      return null;
    }
  }
}
