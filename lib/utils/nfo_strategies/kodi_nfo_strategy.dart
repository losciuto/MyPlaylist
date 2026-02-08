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

    // Helper per un parsing robusto dei decimali (Power Parser)
    double robustParse(String? val) {
      if (val == null || val.isEmpty) return 0.0;
      // Estrae la prima parte numerica (es. "8.5/10" -> "8.5")
      // Gestisce sia il punto che la virgola
      final match = RegExp(r'(\d+[.,]?\d*)').firstMatch(val.replaceAll(',', '.'));
      if (match != null) {
        return double.tryParse(match.group(1)!) ?? 0.0;
      }
      return 0.0;
    }

    // Logica di estrazione Rating
    String? ratingStr = getString('userrating');
    // Se userrating manca o è zero, cerchiamo un rating più significativo
    if (ratingStr == null || ratingStr.isEmpty || ratingStr == '0' || ratingStr == '0.0') {
      // Cerca prima nel blocco <ratings> (plurale)
      final ratingsBlock = document.rootElement.findElements('ratings').firstOrNull;
      final ratingNodes = ratingsBlock != null 
          ? ratingsBlock.findElements('rating') 
          : document.rootElement.findElements('rating');
          
      XmlElement? bestNode;
      for (final node in ratingNodes) {
        // Priorità: default="true"
        if (node.getAttribute('default') == 'true') {
          bestNode = node;
          break;
        }
        // Fallback: il primo che capita (se è caricato da Kodi, solitamente è quello principale)
        bestNode ??= node;
      }

      if (bestNode != null) {
        final valueNode = bestNode.findElements('value').firstOrNull;
        ratingStr = valueNode != null ? valueNode.innerText.trim() : bestNode.innerText.trim();
      }
    }

    // Fallback con Regex se ancora vuoto o zero
    if (ratingStr == null || ratingStr.isEmpty || ratingStr == '0' || ratingStr == '0.0') {
      final simpleRegex = RegExp(r'<rating[^>]*>([^<]+)<\/rating>', caseSensitive: false);
      final simpleMatch = simpleRegex.firstMatch(content);
      if (simpleMatch != null) ratingStr = simpleMatch.group(1)?.trim();
    }

    final safeRating = robustParse(ratingStr);

    // Saga (Set)
    String? saga;
    final setNode = document.rootElement.findElements('set').firstOrNull;
    if (setNode != null) {
      final nameNode = setNode.findElements('name').firstOrNull;
      saga = nameNode != null ? clean(nameNode.innerText) : clean(setNode.innerText);
    }

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
