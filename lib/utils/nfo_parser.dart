import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

class NfoParser {
  static Future<Map<String, dynamic>?> parseNfo(String path) async {
    try {
      // ignore: avoid_print
      print('DEBUG: Parsing NFO at $path');

      final file = File(path); // Re-added file declaration
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final document = XmlDocument.parse(content);
      
      final root = document.rootElement;

      // Helper for case-insensitive lookup
      XmlElement? findElement(String name) {
        return root.children
            .whereType<XmlElement>()
            .firstWhere((e) => e.name.local.toLowerCase() == name.toLowerCase(), orElse: () => throw StateError('Not found'));
      }
      
      // Safe version returning null
      XmlElement? findElementOrNull(String name) {
        try {
           return root.children
            .whereType<XmlElement>()
            .firstWhere((e) => e.name.local.toLowerCase() == name.toLowerCase());
        } catch (_) {
          return null;
        }
      }

      Iterable<XmlElement> findElements(String name) {
         return root.children
            .whereType<XmlElement>()
            .where((e) => e.name.local.toLowerCase() == name.toLowerCase());
      }

      String? getString(String tag) => findElementOrNull(tag)?.innerText.trim();
      List<String> getList(String tag) => findElements(tag).map((e) => e.innerText.trim()).where((s) => s.isNotEmpty).toList();

      final title = getString('title') ?? getString('originaltitle');
      
      final genres = getList('genre');
      
      final year = getString('year') ?? getString('premiered')?.split('-').firstOrNull; // Handle premiered date
      
      final directors = getList('director');
      final plot = getString('plot') ?? getString('outline');
      
      // Actors: case insensitive <actor> -> <name>
      final safeActors = <String>[];
      for (final actorNode in findElements('actor')) {
         try {
           final nameNode = actorNode.children.whereType<XmlElement>().firstWhere(
             (c) => c.name.local.toLowerCase() == 'name'
           );
           if (nameNode.innerText.trim().isNotEmpty) {
             safeActors.add(nameNode.innerText.trim());
           }
         } catch (_) {}
      }

      String? rating;
      // Look for rating
      final ratingNode = findElementOrNull('rating');
      if (ratingNode != null) {
         final valueNode = ratingNode.children.whereType<XmlElement>().firstWhere((c) => c.name.local.toLowerCase() == 'value', orElse: () => ratingNode /* fallback to self if no value child */);
         rating = valueNode.innerText.trim();
      }

      final duration = getString('runtime');
      final thumb = getString('thumb');

      // ignore: avoid_print
      print('DEBUG: Extracted -> Title: $title, Genres: ${genres.length}, Actors: ${safeActors.length}');

      return {
        'title': title,
        'genres': genres.join(', '),
        'year': year,
        'directors': directors.join(', '),
        'plot': plot,
        'actors': safeActors.join(', '),
        'rating': double.tryParse(rating ?? '') ?? 0.0,
        'duration': duration,
        'poster': thumb,
      };
    } catch (e) {
      debugPrint('Error parsing NFO ($path): $e');
      return null;
    }
  }
}
