import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as p;

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
        final nodes = document.rootElement.findElements(tag);
        if (nodes.isEmpty) return null;
        final res = clean(nodes.first.innerText);
        return res.isEmpty ? null : res;
      }

      List<String> getList(String tag) {
        return document.rootElement.findElements(tag)
            .map((e) => clean(e.innerText))
            .where((s) => s.isNotEmpty)
            .toList();
      }

      final title = getString('title') ?? getString('originaltitle');
      final year = getString('year') ?? getString('premiered')?.split('-').firstOrNull;
      final genres = getList('genre');
      final directors = <String>[];
      final directorThumbs = <String>[];
      final nfoDir = File(path).parent.path;

      for (final directorNode in document.rootElement.findElements('director')) {
        String? name;
        String? thumb;

        final nameNode = directorNode.findElements('name').firstOrNull;
        if (nameNode != null) {
          name = clean(nameNode.innerText);
          thumb = directorNode.findElements('thumb').firstOrNull?.innerText ??
              directorNode.findElements('thumbnail').firstOrNull?.innerText ??
              directorNode.getAttribute('thumb') ??
              directorNode.getAttribute('thumbnail');
        } else {
          name = clean(directorNode.children
              .whereType<XmlText>()
              .map((e) => e.value)
              .join(''));
          thumb = directorNode.getAttribute('thumb') ??
              directorNode.getAttribute('thumbnail') ??
              directorNode.findElements('thumb').firstOrNull?.innerText ??
              directorNode.findElements('thumbnail').firstOrNull?.innerText;
        }

        if (name != null && name.isNotEmpty) {
          directors.add(name);
          if (thumb != null && thumb.isNotEmpty && !thumb.startsWith('http') && !thumb.startsWith('/')) {
             thumb = p.join(nfoDir, thumb);
          }
          directorThumbs.add(thumb ?? '');
          print('DEBUG [NfoParser]: Found director: $name, thumb: $thumb');
        }
      }

      final plot = getString('plot') ?? getString('outline');
      
      final safeActors = <String>[];
      final actorThumbs = <String>[];
      for (final actorNode in document.rootElement.findElements('actor')) {
         try {
           final nameNode = actorNode.findElements('name').firstOrNull;
           if (nameNode != null && nameNode.innerText.trim().isNotEmpty) {
             final name = nameNode.innerText.trim();
             safeActors.add(name);
             
             final thumbNode = actorNode.findElements('thumb').firstOrNull ?? 
                               actorNode.findElements('thumbnail').firstOrNull;
             String? thumb = thumbNode?.innerText.trim();
             if (thumb != null && thumb.isNotEmpty && !thumb.startsWith('http') && !thumb.startsWith('/')) {
                thumb = p.join(nfoDir, thumb);
             }
             actorThumbs.add(thumb ?? '');
             print('DEBUG [NfoParser]: Found actor: $name, thumb: $thumb');
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
        final ratingNodes = document.rootElement.findElements('rating');
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
      final setNode = document.rootElement.findElements('set').firstOrNull;
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

      // Handle NaN or Infinity
      final safeRating = (finalRating.isNaN || finalRating.isInfinite) ? 0.0 : finalRating;
      print('DEBUG [NfoParser]: FINAL RATING for "$title" is: $safeRating (from raw: $rating)');

      return {
        'title': title,
        'genres': genres.join(', '),
        'year': year,
        'directors': directors.join(', '),
        'directorThumbs': directorThumbs.join('|'),
        'plot': plot,
        'actors': safeActors.join(', '),
        'actorThumbs': actorThumbs.join('|'),
        'rating': safeRating,
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
