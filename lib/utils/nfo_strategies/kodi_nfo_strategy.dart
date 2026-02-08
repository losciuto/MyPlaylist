import 'dart:io';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as p;
import 'nfo_strategy.dart';

class KodiNfoStrategy implements NfoStrategy {
  @override
  bool canParse(String content) {
    // Kodi NFOs are XML and usually start with <movie, <tvshow, or <episodedetails
    final trimmed = content.trim();
    return trimmed.startsWith('<movie') || 
           trimmed.startsWith('<tvshow') || 
           trimmed.startsWith('<episodedetails') ||
           trimmed.startsWith('<?xml');
  }

  @override
  Future<Map<String, dynamic>?> parse(String content, String nfoPath) async {
    final document = XmlDocument.parse(content);
    final nfoDir = p.dirname(nfoPath);

    String clean(String s) {
      return s.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '').trim();
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
    final plot = getString('plot') ?? getString('outline');
    final duration = getString('runtime');
    final thumb = getString('thumb');

    // Directors
    final directors = <String>[];
    final directorThumbs = <String>[];
    for (final directorNode in document.rootElement.findElements('director')) {
      String? name;
      String? dThumb;

      final nameNode = directorNode.findElements('name').firstOrNull;
      if (nameNode != null) {
        name = clean(nameNode.innerText);
        dThumb = directorNode.findElements('thumb').firstOrNull?.innerText ??
            directorNode.findElements('thumbnail').firstOrNull?.innerText ??
            directorNode.getAttribute('thumb') ??
            directorNode.getAttribute('thumbnail');
      } else {
        name = clean(directorNode.children.whereType<XmlText>().map((e) => e.value).join(''));
        dThumb = directorNode.getAttribute('thumb') ??
            directorNode.getAttribute('thumbnail') ??
            directorNode.findElements('thumb').firstOrNull?.innerText ??
            directorNode.findElements('thumbnail').firstOrNull?.innerText;
      }

      if (name != null && name.isNotEmpty) {
        directors.add(name);
        if (dThumb != null && dThumb.isNotEmpty && !dThumb.startsWith('http') && !dThumb.startsWith('/')) {
          dThumb = p.join(nfoDir, dThumb);
        }
        directorThumbs.add(dThumb ?? '');
      }
    }

    // Actors
    final safeActors = <String>[];
    final actorThumbs = <String>[];
    for (final actorNode in document.rootElement.findElements('actor')) {
      final nameNode = actorNode.findElements('name').firstOrNull;
      if (nameNode != null && nameNode.innerText.trim().isNotEmpty) {
        final name = nameNode.innerText.trim();
        safeActors.add(name);
        final thumbNode = actorNode.findElements('thumb').firstOrNull ?? 
                          actorNode.findElements('thumbnail').firstOrNull;
        String? aThumb = thumbNode?.innerText.trim();
        if (aThumb != null && aThumb.isNotEmpty && !aThumb.startsWith('http') && !aThumb.startsWith('/')) {
          aThumb = p.join(nfoDir, aThumb);
        }
        actorThumbs.add(aThumb ?? '');
      }
    }

    // Rating logic
    String? rating = getString('userrating');
    if (rating == null || rating.isEmpty) {
      final ratingNodes = document.rootElement.findElements('rating');
      XmlElement? bestNode;
      for (final node in ratingNodes) {
        if (node.getAttribute('default') == 'true') {
          bestNode = node;
          break;
        }
        bestNode ??= node;
      }

      if (bestNode != null) {
        final valueNode = bestNode.findElements('value').firstOrNull;
        rating = valueNode != null ? valueNode.innerText.trim() : bestNode.innerText.trim();
      }
    }

    // Regex fallback if needed
    if (rating == null || rating.isEmpty || rating == '0' || rating == '0.0') {
      final simpleRegex = RegExp(r'<rating[^>]*>([^<]+)<\/rating>', caseSensitive: false);
      final simpleMatch = simpleRegex.firstMatch(content);
      if (simpleMatch != null) rating = simpleMatch.group(1)?.trim();
    }

    // Saga
    String? saga;
    final setNode = document.rootElement.findElements('set').firstOrNull;
    if (setNode != null) {
      final nameNode = setNode.findElements('name').firstOrNull;
      saga = nameNode != null ? clean(nameNode.innerText) : clean(setNode.innerText);
    }

    final finalRating = double.tryParse((rating ?? '').replaceAll(',', '.')) ?? 0.0;
    final safeRating = (finalRating.isNaN || finalRating.isInfinite) ? 0.0 : finalRating;

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
  }
}
