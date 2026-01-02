
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

class DatabaseTab extends StatefulWidget {
  const DatabaseTab({super.key});

  @override
  State<DatabaseTab> createState() => _DatabaseTabState();
}

class _DatabaseTabState extends State<DatabaseTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _onlyMissingNfo = false;


  Future<void> _bulkGenerateNfo() async {
     final apiKey = context.read<SettingsService>().tmdbApiKey;
     if (apiKey.isEmpty) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key TMDB mancante! Impostala nei settings.')));
       return;
     }

     final mode = await showDialog<String>(
       context: context,
       builder: (ctx) => AlertDialog(
         title: const Text('Generazione NFO da TMDB'),
         content: StatefulBuilder(
           builder: (context, setState) {
             return Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text('Scegli la modalità di generazione:\n\n'
                   '⚡ AUTOMATICO: Scarica il primo risultato trovato (più veloce).\n'
                   '🖐️ INTERATTIVO: Ti chiede di confermare il film per ogni video trovato.'),
                 const SizedBox(height: 20),
                 CheckboxListTile(
                   title: const Text('Genera solo se manca il file .nfo'),
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
           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
           ElevatedButton(onPressed: () => Navigator.pop(ctx, 'auto'), child: const Text('⚡ Automatico')),
           ElevatedButton(onPressed: () => Navigator.pop(ctx, 'interactive'), child: const Text('🖐️ Interattivo')),
         ],
       ),
     );
     
     if (mode == null) return;
     if (!mounted) return;

     final provider = context.read<DatabaseProvider>();
     final allVideos = List<Video>.from(provider.videos);
     final total = allVideos.length;

     if (total == 0) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessun video nel database.')));
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
                     const Text('Scaricamento Info...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              TextButton(onPressed: () { isCancelled = true; Navigator.pop(ctx); }, child: const Text('Stop'))
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
           for (var q in queriesToTry) {
             results = await tmdb.searchMovie(q, year: year);
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
                  title: 'Seleziona per: ${p.basename(video.path)}',
                  results: results,
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
                      // Process
            final details = await tmdb.getMovieDetails(selectedMovie['id']);
            final nfoContent = NfoGenerator.generateMovieNfo(details);
            
            // 1. Write NFO
            final nfoPath = p.setExtension(video.path, '.nfo');
            await File(nfoPath).writeAsString(nfoContent);
            
            String localPosterPath = video.posterPath;
            final baseDir = p.dirname(video.path);
            final baseFileName = p.basenameWithoutExtension(video.path);

            // 2. Download Poster
            if (details['poster_path'] != null) {
               final posterUrl = 'https://image.tmdb.org/t/p/original${details['poster_path']}';
               final posterPath = '$baseDir/$baseFileName-poster.jpg';
               final resp = await http.get(Uri.parse(posterUrl));
               if (resp.statusCode == 200) {
                  await File(posterPath).writeAsBytes(resp.bodyBytes);
                  localPosterPath = posterPath;
               }
            }

            // 3. Download Fanart (Backdrop)
            if (details['backdrop_path'] != null) {
              final fanartUrl = 'https://image.tmdb.org/t/p/original${details['backdrop_path']}';
              final fanartPath = '$baseDir/$baseFileName-fanart.jpg';
              final resp = await http.get(Uri.parse(fanartUrl));
              if (resp.statusCode == 200) {
                await File(fanartPath).writeAsBytes(resp.bodyBytes);
              }
            }

            // 4. Download Logo (Clearlogo)
            if (details['images'] != null && details['images']['logos'] != null) {
              final logos = details['images']['logos'] as List;
              if (logos.isNotEmpty) {
                // Try to find a logo in preferred language or just the first one
                final logoPathTail = logos.first['file_path'];
                final logoUrl = 'https://image.tmdb.org/t/p/original$logoPathTail';
                final logoPath = '$baseDir/$baseFileName-clearlogo.png';
                final resp = await http.get(Uri.parse(logoUrl));
                if (resp.statusCode == 200) {
                  await File(logoPath).writeAsBytes(resp.bodyBytes);
                }
              }
            }

            // 5. Update Database Record
            final nfoTitle = details['title'] ?? video.title;
            final nfoYear = details['release_date']?.toString().split('-').first ?? video.year;
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
              
              final crew = (details['credits']['crew'] as List?)?.where((c) => c['job'] == 'Director').map((c) => c['name']).join(', ');
              if (crew != null) nfoDirectors = crew;
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
           title: const Text('Generazione Completata'),
           content: Text('File creati: $updated\nSaltati/Non trovati: $skipped\nErrori: $errors'),
           actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]
         )
       );
     }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video aggiornato correttamente')));
    }
  }

  Future<void> _deleteVideo(Video video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: Text('Vuoi eliminare il video "${video.title}" dal database?\nIl file fisico non verrà rimosso.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<DatabaseProvider>().deleteVideo(video);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video eliminato dal database')));
    }
  }

  Future<void> _clearDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma'),
        content: const Text('Vuoi cancellare TUTTI i dati dal database?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Si, Cancella', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<DatabaseProvider>().clearDatabase();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database pulito!')));
    }
  }

  Future<void> _bulkRenameTitles() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rinomina Titoli in Massa'),
        content: const Text(
          'Questa operazione cercherà i file .nfo per ogni video e rinominerà i video nel formato "Titolo (Anno)".\n\n'
          'Verranno aggiornati sia il database che i metadati dei file video.\n\n'
          'L\'operazione potrebbe richiedere del tempo. Continuare?'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Avvia')
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessun video da elaborare.')));
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
        title: const Text('Rinomina in corso...', style: TextStyle(color: Colors.white)),
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
                  'Elaborazione:',
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
            child: const Text('Annulla', style: TextStyle(color: Colors.redAccent))
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
        String nfoPath = p.setExtension(video.path, '.nfo');
        File nfoFile = File(nfoPath);
        
        bool nfoFound = await nfoFile.exists();
        
        // If not found directly, try case-insensitive search in the same directory
        if (!nfoFound) {
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
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annullamento... Pulizia file temporanei in corso...')));
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
          title: Text(isCancelled ? 'Operazione Annullata' : 'Operazione Completata'),
          content: Text(
            'Aggiornati: $updatedCount\n'
            'Saltati: $skippedCount\n'
            'Errori: $errorCount'
          ),
          actions: [
             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
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
                        const Text('GESTIONE DATABASE',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('🎬 Video nel database: ${provider.filteredVideos.length}',
                      style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                  
                  const SizedBox(height: 10),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Cerca video...',
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
                      ? const Center(child: Text('Nessun video trovato.'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFF4CAF50)),
                              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              // Remove dataRowColor to let it follow theme
                              columns: const [
                                DataColumn(label: Text('#')),
                                DataColumn(label: Text('Titolo')),
                                DataColumn(label: Text('Anno')),
                                DataColumn(label: Text('Rating')),
                                DataColumn(label: Text('Durata')),
                                DataColumn(label: Text('Registi')),
                                DataColumn(label: Text('Azioni')),
                              ],
                              rows: provider.filteredVideos.asMap().entries.map((entry) {
                                final i = entry.key + 1;
                                final video = entry.value;
                                return DataRow(cells: [
                                  DataCell(Text('$i')),
                                  DataCell(
                                    Tooltip(
                                      message: video.title,
                                      child: SizedBox(
                                        width: 200, 
                                        child: Text(
                                          video.title.isNotEmpty ? video.title : 'N/A', 
                                          overflow: TextOverflow.ellipsis
                                        )
                                      ),
                                    )
                                  ),
                                   DataCell(Text(video.year)),
                                   DataCell(
                                     Row(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         const Icon(Icons.star, color: Colors.orange, size: 14),
                                         const SizedBox(width: 4),
                                         Text(video.rating.toStringAsFixed(1)),
                                       ],
                                     ),
                                   ),
                                   DataCell(Text(video.duration)),
                                  DataCell(SizedBox(width: 150, child: Text(video.directors, overflow: TextOverflow.ellipsis))),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _editVideo(video),
                                          tooltip: 'Modifica',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteVideo(video),
                                          tooltip: 'Elimina riga',
                                        ),
                                      ],
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _clearDatabase,
                    icon: const Icon(Icons.delete),
                    label: const Text('Pulisci Database'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () => provider.refreshVideos(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Aggiorna'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _bulkRenameTitles,
                    icon: const Icon(Icons.drive_file_rename_outline),
                    label: const Text('Rinomina Titoli'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _bulkGenerateNfo,
                    icon: const Icon(Icons.movie_creation),
                    label: const Text('Genera NFO (TMDB)'),
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
}
