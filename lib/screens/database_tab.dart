
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/video.dart';
import 'edit_video_dialog.dart';
import '../database/database_helper.dart';

import '../services/metadata_service.dart';
import '../utils/nfo_parser.dart';
import '../widgets/movie_selection_dialog.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../services/settings_service.dart';
import '../services/tmdb_service.dart';
import '../utils/nfo_generator.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

class DatabaseTab extends StatefulWidget {
  const DatabaseTab({super.key});

  @override
  State<DatabaseTab> createState() => _DatabaseTabState();
}

class _DatabaseTabState extends State<DatabaseTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  
  bool _onlyMissingNfo = false;
  
  // Sorting state
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  // Column widths
  static const double _colIdxWidth = 50;
  static const double _colTitleWidth = 350;
  static const double _colYearWidth = 80;
  static const double _colRatingWidth = 80;
  static const double _colDurationWidth = 100;
  static const double _colSagaWidth = 180;
  static const double _colDirectorsWidth = 200;
  static const double _colActionsWidth = 120;
  static const double _totalTableWidth = _colIdxWidth + _colTitleWidth + _colYearWidth + 
                                       _colRatingWidth + _colDurationWidth + _colSagaWidth + 
                                       _colDirectorsWidth + _colActionsWidth;


  Future<void> _bulkGenerateNfo() async {
     final apiKey = context.read<SettingsService>().tmdbApiKey;
     if (apiKey.isEmpty) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.tmdbApiKeyMissing)));
       return;
     }

     final mode = await showDialog<String>(
       context: context,
       builder: (ctx) => AlertDialog(
         title: Text(AppLocalizations.of(context)!.tmdbGenTitle),
         content: StatefulBuilder(
           builder: (context, setState) {
             return Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(AppLocalizations.of(context)!.tmdbGenModeMsg),
                 const SizedBox(height: 20),
                 CheckboxListTile(
                   title: Text(AppLocalizations.of(context)!.onlyMissingNfo),
                   value: _onlyMissingNfo,
                   onChanged: (val) {
                     setState(() {
                        _onlyMissingNfo = val ?? false;
                     });
                   },
                   contentPadding: EdgeInsets.zero,
                   controlAffinity: ListTileControlAffinity.leading,
                 ),
               ],
             );
           }
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
           ElevatedButton(onPressed: () => Navigator.pop(ctx, 'auto'), child: Text(AppLocalizations.of(context)!.tmdbClickAuto)),
           ElevatedButton(onPressed: () => Navigator.pop(ctx, 'interactive'), child: Text(AppLocalizations.of(context)!.tmdbClickInteractive)),
         ],
       ),
     );
     
     if (mode == null) return;
     if (!mounted) return;

     final provider = context.read<DatabaseProvider>();
     final allVideos = List<Video>.from(provider.videos);
     final total = allVideos.length;

     if (total == 0) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noVideoInDb)));
       return;
     }

     final progressNotifier = ValueNotifier<Map<String, dynamic>>({'value': 0, 'title': '-'});
     bool isCancelled = false;
     
     // Progress Dialog (Non-blocking for interactive, but blocking interaction with main UI)
     // Issue: If interactive, we need to show ANOTHER dialog on top. 
     // Solution: Don't use a modal progress dialog for interactive mode? 
     // OR: Use a custom overlay?
     // OR: Just update a variable and show the selection dialog.
     
     // Let's use the same Progress Dialog pattern but careful with context.
     // Actually, for Interactive mode, better NOT to show a blocking progress dialog that covers the screen, 
     // because we need to show the Selection Dialog.
     // Simplified approach: Show Progress Dialog ONLY for Automatic. 
     // For Interactive, show a persistent bottom sheet or just iterate with dialogs.
     // Let's stick to simple "Status" updates via SnackBar or minimal UI for Interactive?
     // No, let's try to keep it consistent.
     // Actually, we can pop the progress dialog to show the selection dialog and then show it again? No, flickery.
     
     // Better Design for Interactive: 
     // Iterate. If match found, show Dialog "Select Movie for [Filename]". 
     // Inside that dialog, show "Progress: X/Y".
     
     // Let's proceed with valid implementation:
     
     int updated = 0;
     int skipped = 0;
     int errors = 0;
     
     final tmdb = TmdbService(apiKey);
     
     // Quick overlay/snackbar for start
     if (mode == 'auto') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF3C3C3C),
            content: ValueListenableBuilder<Map<String, dynamic>>(
              valueListenable: progressNotifier,
              builder: (ctx, state, _) {
                 return Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(AppLocalizations.of(context)!.downloadingInfo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 10),
                     Text(state['title'], style: const TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                     const SizedBox(height: 10),
                     LinearProgressIndicator(value: state['value'] / total, color: Colors.blue),
                     Text('${state['value']} / $total', style: const TextStyle(color: Colors.white54)),
                   ],
                 );
              }
            ),
            actions: [
              TextButton(onPressed: () { isCancelled = true; Navigator.pop(ctx); }, child: Text(AppLocalizations.of(context)!.stopAllButtonLabel))
            ],
          )
        );
     }

      for (int i = 0; i < total; i++) {
        if (isCancelled) break;
        
        final video = allVideos[i];
        
        // Skip found videos in interactive mode
        if (mode == 'interactive' && video.title.isNotEmpty && video.year.isNotEmpty) {
           skipped++;
           continue;
        }

        // Check for missing NFO if filter is active
        if (_onlyMissingNfo) {
           final nfoPath = p.setExtension(video.path, '.nfo');
           if (await File(nfoPath).exists()) {
             skipped++;
             continue;
           }
        }

        progressNotifier.value = {'value': i + 1, 'title': video.title.isNotEmpty ? video.title : p.basename(video.path)};
        
        try {
           // Tiered Search Logic
           String baseQuery = p.basenameWithoutExtension(video.path)
               .replaceAll('.', ' ')
               .replaceAll('_', ' ')
               .replaceAll(RegExp(r'\(\d{4}\)'), '')
               .trim();
           
           // List of queries to try: 1. Full, 2. First 2 words, 3. First 1 word
           List<String> queriesToTry = [baseQuery];
           final words = baseQuery.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
           
           if (words.length >= 3) {
             queriesToTry.add(words.take(2).join(' '));
           }
           if (words.isNotEmpty) {
             queriesToTry.add(words.first);
           }
           
           // Remove duplicates and maintain order
           queriesToTry = queriesToTry.toSet().toList();

           // Try to extract year from filename or existing title
           final yearMatch = RegExp(r'\((\d{4})\)').firstMatch(video.title) ?? RegExp(r'\((\d{4})\)').firstMatch(p.basename(video.path));
           final int? year = yearMatch != null ? int.tryParse(yearMatch.group(1)!) : null;

           List<Map<String, dynamic>> results = [];
           final isSeries = video.isSeries;

           for (var q in queriesToTry) {
             if (isSeries) {
               results = await tmdb.searchTvShow(q, year: year);
             } else {
               results = await tmdb.searchMovie(q, year: year);
             }
             if (results.isNotEmpty) break;
           }
           
           Map<String, dynamic>? selectedMovie;
           
           if (results.isEmpty) {
              skipped++;
              continue;
           }
           
           if (mode == 'auto') {
              selectedMovie = results.first;
           } else {
              // Interactive Mode: Show Pageable Dialog with posters
              if (!mounted) break;
              final choice = await showDialog<dynamic>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => MovieSelectionDialog(
                  title: AppLocalizations.of(context)!.selectMovieTitle,
                  results: results.map((r) => {
                    'id': r['id'],
                    'title': isSeries ? r['name'] : r['title'],
                    'release_date': isSeries ? r['first_air_date'] : r['release_date'],
                    'poster_path': r['poster_path'],
                    'overview': r['overview'],
                  }).toList(),
                  isBulkMode: true,
                ),
              );

              if (choice is Map<String, dynamic> && choice['action'] == 'cancel') {
                isCancelled = true;
                selectedMovie = null;
              } else {
                selectedMovie = choice as Map<String, dynamic>?;
              }
           }
           
           if (selectedMovie == null) {
              if (isCancelled) break;
              skipped++;
              continue;
           }
           
            // Process Details
            Map<String, dynamic> details;
            String nfoContent;
            String nfoPath;
            if (isSeries) {
              details = await tmdb.getTvShowDetails(selectedMovie['id']);
              nfoContent = NfoGenerator.generateTvShowNfo(details);
              nfoPath = p.join(video.path, 'tvshow.nfo');
            } else {
              details = await tmdb.getMovieDetails(selectedMovie['id']);
              nfoContent = NfoGenerator.generateMovieNfo(details);
              nfoPath = p.setExtension(video.path, '.nfo');
            }

            // 1. Write NFO
            await File(nfoPath).writeAsString(nfoContent);
            
            String localPosterPath = video.posterPath;
            final baseDir = isSeries ? video.path : p.dirname(video.path);
            final baseFileName = p.basenameWithoutExtension(video.path);

            // 2. Download Poster
            if (details['poster_path'] != null) {
               final posterUrl = 'https://image.tmdb.org/t/p/original${details['poster_path']}';
               final posterPath = isSeries 
                  ? p.join(baseDir, 'poster.jpg')
                  : '$baseDir/$baseFileName-poster.jpg';
                  
               final resp = await http.get(Uri.parse(posterUrl));
               if (resp.statusCode == 200) {
                  await File(posterPath).writeAsBytes(resp.bodyBytes);
                  localPosterPath = posterPath;
               }
            }

            // 3. Download Fanart (Backdrop)
            if (details['backdrop_path'] != null) {
              final fanartUrl = 'https://image.tmdb.org/t/p/original${details['backdrop_path']}';
              final fanartPath = isSeries
                  ? p.join(baseDir, 'fanart.jpg')
                  : '$baseDir/$baseFileName-fanart.jpg';
                  
              final resp = await http.get(Uri.parse(fanartUrl));
              if (resp.statusCode == 200) {
                await File(fanartPath).writeAsBytes(resp.bodyBytes);
              }
            }

            // 4. Download Logo (Clearlogo)
            if (details['images'] != null && details['images']['logos'] != null) {
              final logos = details['images']['logos'] as List;
              if (logos.isNotEmpty) {
                final logoPathTail = logos.first['file_path'];
                final logoUrl = 'https://image.tmdb.org/t/p/original$logoPathTail';
                final logoPath = isSeries
                    ? p.join(baseDir, 'clearlogo.png')
                    : '$baseDir/$baseFileName-clearlogo.png';
                    
                final resp = await http.get(Uri.parse(logoUrl));
                if (resp.statusCode == 200) {
                  await File(logoPath).writeAsBytes(resp.bodyBytes);
                }
              }
            }

            // 5. Update Database Record
            final nfoTitle = isSeries ? details['name'] : (details['title'] ?? video.title);
            final nfoYear = (isSeries ? details['first_air_date'] : details['release_date'])?.toString().split('-').first ?? video.year;
            
            final gList = details['genres'] != null 
                ? (details['genres'] as List).map((g) => g['name']).join(', ')
                : video.genres;
            final nfoPlot = details['overview'] ?? video.plot;
            final nfoRating = (details['vote_average'] as num?)?.toDouble() ?? video.rating;
            
            String nfoActors = video.actors;
            String nfoDirectors = video.directors;
            if (details['credits'] != null) {
              final cast = (details['credits']['cast'] as List?)?.take(5).map((c) => c['name']).join(', ');
              if (cast != null) nfoActors = cast;
              
              if (isSeries) {
                if (details['created_by'] != null) {
                  nfoDirectors = (details['created_by'] as List).map((c) => c['name']).join(', ');
                }
              } else {
                final crew = (details['credits']['crew'] as List?)?.where((c) => c['job'] == 'Director').map((c) => c['name']).join(', ');
                if (crew != null) nfoDirectors = crew;
              }
            }

            final updatedVideo = Video(
              id: video.id,
              path: video.path,
              mtime: video.mtime,
              duration: video.duration,
              title: nfoYear.isNotEmpty ? '$nfoTitle ($nfoYear)' : nfoTitle,
              year: nfoYear,
              genres: gList,
              directors: nfoDirectors,
              actors: nfoActors,
              plot: nfoPlot,
              rating: nfoRating,
              posterPath: localPosterPath,
              isSeries: video.isSeries,
              saga: (details['belongs_to_collection'] != null) ? details['belongs_to_collection']['name'] : video.saga,
            );

            await DatabaseHelper.instance.updateVideo(updatedVideo);
            updated++;

        } catch (e) {
           errors++;
           debugPrint('Error TMDB processing ${video.path}: $e');
        }
        
        // Small delay to behave
        await Future.delayed(const Duration(milliseconds: 50));
     }

     if (mode == 'auto' && mounted && !isCancelled) Navigator.pop(context); // Close progress
     
     if (mounted) {
       await provider.refreshVideos();
       showDialog(
         context: context, 
         builder: (ctx) => AlertDialog(
           title: Text(AppLocalizations.of(context)!.genComplete),
           content: Text(AppLocalizations.of(context)!.genStats(updated.toString(), skipped.toString(), errors.toString())),
           actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.ok))]
         )
       );
     }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _sortVideos(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
    
    final provider = context.read<DatabaseProvider>();
    final videos = List<Video>.from(provider.filteredVideos);
    
    videos.sort((a, b) {
      int comparison = 0;
      
      switch (columnIndex) {
        case 0: // # (index)
          comparison = provider.filteredVideos.indexOf(a).compareTo(provider.filteredVideos.indexOf(b));
          break;
        case 1: // Titolo
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case 2: // Anno
          comparison = a.year.compareTo(b.year);
          break;
        case 3: // Rating
          comparison = a.rating.compareTo(b.rating);
          break;
        case 4: // Durata
          // Parse duration strings like "1h 30m" for comparison
          final aDuration = _parseDuration(a.duration);
          final bDuration = _parseDuration(b.duration);
          comparison = aDuration.compareTo(bDuration);
          break;
        case 5: // Saga
          comparison = a.saga.toLowerCase().compareTo(b.saga.toLowerCase());
          break;
        case 6: // Registi
          comparison = a.directors.toLowerCase().compareTo(b.directors.toLowerCase());
          break;
      }
      
      return ascending ? comparison : -comparison;
    });
    
    // Update the provider with sorted videos
    provider.setSortedVideos(videos);
  }
  
  int _parseDuration(String duration) {
    // Parse duration like "1h 30m" or "45m" to minutes
    int totalMinutes = 0;
    final hourMatch = RegExp(r'(\d+)h').firstMatch(duration);
    final minMatch = RegExp(r'(\d+)m').firstMatch(duration);
    
    if (hourMatch != null) {
      totalMinutes += int.parse(hourMatch.group(1)!) * 60;
    }
    if (minMatch != null) {
      totalMinutes += int.parse(minMatch.group(1)!);
    }
    
    return totalMinutes;
  }

  // Wrappers to keep UI clean
  void _filterVideos(String query) {
    context.read<DatabaseProvider>().filterVideos(query);
  }

  Future<void> _editVideo(Video video) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditVideoDialog(video: video),
    );

    if (result == true && mounted) {
      await context.read<DatabaseProvider>().refreshVideos();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.videoUpdated)));
    }
  }

  Future<void> _deleteVideo(Video video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeleteTitle),
        content: Text(AppLocalizations.of(context)!.confirmDeleteMsg(video.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<DatabaseProvider>().deleteVideo(video);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.videoDeleted)));
    }
  }

  Future<void> _clearDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirm),
        content: Text(AppLocalizations.of(context)!.confirmClearDb),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.no)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context)!.yesDelete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<DatabaseProvider>().clearDatabase();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.dbCleared)));
    }
  }

  Future<void> _bulkRenameTitles() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.bulkRenameTitle),
        content: Text(AppLocalizations.of(context)!.bulkRenameMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(AppLocalizations.of(context)!.start)
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    // Access Provider
    final provider = context.read<DatabaseProvider>();
    final allVideos = List<Video>.from(provider.videos); // Snapshot
    final total = allVideos.length;

    if (total == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noVideoFound)));
      }
      return;
    }

    final progressNotifier = ValueNotifier<Map<String, dynamic>>({
      'value': 0,
      'title': '-',
    });
    bool isCancelled = false;
    
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF3C3C3C),
        title: Text(AppLocalizations.of(context)!.renaming, style: const TextStyle(color: Colors.white)),
        content: ValueListenableBuilder<Map<String, dynamic>>(
          valueListenable: progressNotifier,
          builder: (context, state, child) {
            final int value = state['value'];
            final String title = state['title'];
            final percent = (value / total * 100).toStringAsFixed(1);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.processing,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: value / total, 
                  backgroundColor: Colors.white10,
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 15),
                Text('$value / $total ($percent%)', style: const TextStyle(color: Colors.white70)),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              isCancelled = true;
              Navigator.pop(ctx);
            }, 
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );

    int updatedCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    int current = 0;
    final List<String> skippedReasons = [];
    final Set<String> processedDirs = {};

    for (final video in allVideos) {
      if (isCancelled) break;

      current++;
      progressNotifier.value = {
        'value': current,
        'title': video.title.isNotEmpty ? video.title : p.basename(video.path),
      };
      
      // Track directory for cleanup
      processedDirs.add(p.dirname(video.path));
      
      try {
        // Robust NFO lookup
        String nfoPath = video.isSeries 
            ? p.join(video.path, 'tvshow.nfo')
            : p.setExtension(video.path, '.nfo');
            
        File nfoFile = File(nfoPath);
        
        bool nfoFound = await nfoFile.exists();
        
        // If not found directly, try case-insensitive search in the same directory (only for movies)
        if (!nfoFound && !video.isSeries) {
           try {
             final parentDir = Directory(p.dirname(video.path));
             if (await parentDir.exists()) {
               final videoBasenameNoExt = p.basenameWithoutExtension(video.path).toLowerCase();
               
               // List files in directory to find a match
               final siblings = parentDir.listSync(); // Sync is okay for local simple dirs, or use await parentDir.list().toList()
               for (final entity in siblings) {
                 if (entity is File) {
                   final entityPath = entity.path;
                   final entityExt = p.extension(entityPath).toLowerCase();
                   if (entityExt == '.nfo') {
                     final entityBasenameNoExt = p.basenameWithoutExtension(entityPath).toLowerCase();
                     if (entityBasenameNoExt == videoBasenameNoExt) {
                       nfoPath = entityPath;
                       nfoFile = File(nfoPath);
                       nfoFound = true;
                       debugPrint('MATCH [${p.basename(video.path)}]: Found case-insensitive NFO: ${p.basename(nfoPath)}');
                       break;
                     }
                   }
                 }
               }
             }
           } catch (e) {
             debugPrint('Error searching for NFO: $e');
           }
        }

        if (!nfoFound) {
          skippedCount++;
          skippedReasons.add('${p.basename(video.path)}: NFO non trovato');
          debugPrint('SKIP [${p.basename(video.path)}]: NFO file not found (tried $nfoPath and case-insensitive)');
          continue;
        }

        final metadata = await NfoParser.parseNfo(nfoPath);
        if (metadata == null) {
          skippedCount++;
          skippedReasons.add('${p.basename(video.path)}: NFO non valido');
          debugPrint('SKIP [${p.basename(video.path)}]: NFO parsing failed');
          continue;
        }

        final nfoTitle = metadata['title'];
        final nfoYear = metadata['year'];

        if (nfoTitle == null || nfoTitle.isEmpty) {
          skippedCount++;
          skippedReasons.add('${p.basename(video.path)}: Titolo mancante in NFO');
          debugPrint('SKIP [${p.basename(video.path)}]: No title in NFO');
          continue;
        }

        // 3-Way Comparison Logic: Database vs NFO vs File Metadata
        
        // 1. Get File Metadata using ffprobe
        final fileMetadata = await MetadataService().getFileMetadata(video.path);
        final fileTitle = fileMetadata['title'] ?? '';
        
        // Robust normalization
        String norm(String? s) {
          if (s == null) return '';
          return s.trim()
                  .toLowerCase()
                  .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '') // Zero-width characters
                  .replaceAll(RegExp(r'\s+'), ' '); // Collapse spaces
        }

        // Construct STRICT Target Title: "Title (Year)"
        String targetTitle = nfoTitle;
        if (nfoYear != null && nfoYear.isNotEmpty) {
           targetTitle = '$nfoTitle ($nfoYear)';
        }

        final nfoGenres = metadata['genres'] ?? '';
        final nfoDirectors = metadata['directors'] ?? '';
        final nfoActors = metadata['actors'] ?? '';
        final nfoPlot = metadata['plot'] ?? '';
        final nfoRating = metadata['rating'] ?? 0.0;
        final nfoPoster = metadata['poster'] ?? '';

        // Strict & Independent Update Logic
        bool dbMismatch = norm(video.title) != norm(targetTitle);
        bool fileMismatch = norm(fileTitle) != norm(targetTitle);

        if (!dbMismatch && !fileMismatch) {
          skippedCount++;
          skippedReasons.add('${p.basename(video.path)}: Già allineato');
          debugPrint('SKIP [${p.basename(video.path)}]: Aligned. DB="${video.title}", File="${fileTitle}"');
          continue;
        }

        // Create the "Perfect" video object from NFO data
        final updatedVideo = Video(
          id: video.id,
          path: video.path,
          mtime: video.mtime,
          duration: video.duration,
          title: targetTitle,
          year: (nfoYear != null && nfoYear.isNotEmpty) ? nfoYear : video.year, 
          genres: nfoGenres.isNotEmpty ? nfoGenres : video.genres,
          directors: nfoDirectors.isNotEmpty ? nfoDirectors : video.directors,
          actors: nfoActors.isNotEmpty ? nfoActors : video.actors,
          plot: nfoPlot.isNotEmpty ? nfoPlot : video.plot,
          rating: nfoRating > 0 ? nfoRating : video.rating,
          posterPath: nfoPoster.isNotEmpty ? nfoPoster : video.posterPath,
          isSeries: video.isSeries,
          saga: (metadata['saga'] != null && metadata['saga'].toString().isNotEmpty) ? metadata['saga'] : video.saga,
        );

        debugPrint('UPDATE [${p.basename(video.path)}]: Action required');
        
        // Action 1: Update Database if needed
        if (dbMismatch) {
           debugPrint('  -> Updating Database (Title Mismatch: "${video.title}" vs "$targetTitle")');
           await DatabaseHelper.instance.updateVideo(updatedVideo);
        }

        // Action 2: Update File Metadata if needed
        if (fileMismatch) {
           debugPrint('  -> Updating File Metadata (Title Mismatch: "${fileTitle}" vs "$targetTitle")');
           await MetadataService().updateFileMetadata(updatedVideo);
        }

        updatedCount++;
        
      } catch (e) {
        errorCount++;
        skippedReasons.add('${p.basename(video.path)}: Errore - $e');
        debugPrint('ERROR renaming video ${video.path}: $e');
      }
      
      await Future.delayed(Duration.zero);
    }

    if (mounted && !isCancelled) Navigator.pop(context);

    if (isCancelled && processedDirs.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.cancelling)));
       // Clean temp files in all processed directories
       for (final dir in processedDirs) {
         try {
           await MetadataService().cleanupTempFiles(dir);
         } catch (e) {
           debugPrint('Error cleaning temp files in $dir: $e');
         }
       }
    }

    if (mounted) {
       await context.read<DatabaseProvider>().refreshVideos();
       
       showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isCancelled ? AppLocalizations.of(context)!.opCancelled : AppLocalizations.of(context)!.opCompleted),
          content: Text(
            AppLocalizations.of(context)!.bulkOpStats(updatedCount.toString(), skippedCount.toString(), errorCount.toString())
          ),
          actions: [
             TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.ok)),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLocalizations.of(context)!.databaseManagementTitle,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(AppLocalizations.of(context)!.videosInDatabase(provider.filteredVideos.length),
                      style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                  
                  const SizedBox(height: 10),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.searchVideosPlaceholder,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF3C3C3C) 
                          : Colors.grey[200],
                    ),
                    onChanged: _filterVideos, // Calls wrapper
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.filteredVideos.isEmpty
                      ? Center(child: Text(AppLocalizations.of(context)!.noVideosFound))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _horizontalScrollController,
                              child: SizedBox(
                                width: _totalTableWidth,
                                child: Column(
                                  children: [
                                    // Unified Header
                                    _buildTableHeader(),
                                    // Scrollable Body
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: provider.filteredVideos.length,
                                        itemBuilder: (context, index) {
                                          return _buildTableRow(provider.filteredVideos[index], index);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _clearDatabase,
                    icon: const Icon(Icons.delete),
                    label: Text(AppLocalizations.of(context)!.clearDatabaseButton),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () => provider.refreshVideos(),
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)!.refreshButton),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _bulkRenameTitles,
                    icon: const Icon(Icons.drive_file_rename_outline),
                    label: Text(AppLocalizations.of(context)!.renameTitlesButton),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _bulkGenerateNfo,
                    icon: const Icon(Icons.movie_creation),
                    label: Text(AppLocalizations.of(context)!.generateNfoTmdbLabel),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  Widget _buildTableHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: const Color(0xFF4CAF50),
      height: 48,
      child: Row(
        children: [
          _buildHeaderColumn('#', _colIdxWidth, 0),
          _buildHeaderColumn(l10n.colTitle, _colTitleWidth, 1),
          _buildHeaderColumn(l10n.colYear, _colYearWidth, 2),
          _buildHeaderColumn(l10n.colRating, _colRatingWidth, 3),
          _buildHeaderColumn(l10n.colDuration, _colDurationWidth, 4),
          _buildHeaderColumn(l10n.colSaga, _colSagaWidth, 5),
          _buildHeaderColumn(l10n.colDirectors, _colDirectorsWidth, 6),
          SizedBox(width: _colActionsWidth, child: Center(child: Text(l10n.colActions, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _buildHeaderColumn(String label, double width, int index) {
    return InkWell(
      onTap: () => _sortVideos(index, _sortColumnIndex == index ? !_sortAscending : true),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              if (_sortColumnIndex == index)
                Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(Video video, int index) {
    final bgColor = index % 2 == 0 
        ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white)
        : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF333333) : Colors.grey[50]);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          _buildTableCell(Text('${index + 1}'), _colIdxWidth),
          _buildTableCell(
            Tooltip(
              message: video.title,
              child: Row(
                children: [
                  if (video.isSeries) 
                    const Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Icon(Icons.tv, color: Colors.blueAccent, size: 16),
                    ),
                  Expanded(
                    child: Text(
                      video.title.isNotEmpty ? video.title : 'N/A', 
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                ],
              ),
            ), 
            _colTitleWidth
          ),
          _buildTableCell(Text(video.year), _colYearWidth),
          _buildTableCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 14),
                const SizedBox(width: 4),
                Text(video.rating.toStringAsFixed(1)),
              ],
            ), 
            _colRatingWidth
          ),
          _buildTableCell(Text(video.duration), _colDurationWidth),
          _buildTableCell(Text(video.saga, overflow: TextOverflow.ellipsis), _colSagaWidth),
          _buildTableCell(Text(video.directors, overflow: TextOverflow.ellipsis), _colDirectorsWidth),
          _buildTableCell(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => _editVideo(video),
                  tooltip: AppLocalizations.of(context)!.editTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteVideo(video),
                  tooltip: AppLocalizations.of(context)!.deleteTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ), 
            _colActionsWidth
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(Widget child, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }
}
