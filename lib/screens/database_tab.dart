import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/video.dart';
import 'edit_video_dialog.dart';
import '../database/database_helper.dart';

import '../services/metadata_service.dart';
import '../utils/nfo_parser.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class DatabaseTab extends StatefulWidget {
  const DatabaseTab({super.key});

  @override
  State<DatabaseTab> createState() => _DatabaseTabState();
}

class _DatabaseTabState extends State<DatabaseTab> {
  final TextEditingController _searchController = TextEditingController();

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

    for (final video in allVideos) {
      if (isCancelled) break;

      current++;
      progressNotifier.value = {
        'value': current,
        'title': video.title.isNotEmpty ? video.title : p.basename(video.path),
      };
      
      try {
        final nfoPath = p.setExtension(video.path, '.nfo');
        final nfoFile = File(nfoPath);

        if (!await nfoFile.exists()) {
          skippedCount++;
          continue;
        }

        final metadata = await NfoParser.parseNfo(nfoPath);
        if (metadata == null) {
          skippedCount++;
          continue;
        }

        final nfoTitle = metadata['title'];
        final nfoYear = metadata['year'];

        if (nfoTitle == null || nfoTitle.isEmpty) {
          skippedCount++;
          continue;
        }

        String newTitle = nfoTitle;
        if (nfoYear != null && nfoYear.isNotEmpty) {
          newTitle = '$nfoTitle ($nfoYear)';
        }

        // Robust comparison: check if the title (which should already include the year if present) matches.
        // We use case-insensitive comparison and trim to be as flexible as possible.
        final String currentTitle = video.title.trim().toLowerCase();
        final String targetTitle = newTitle.trim().toLowerCase();

        if (currentTitle == targetTitle) {
          skippedCount++;
          continue;
        }

        final updatedVideo = Video(
          id: video.id,
          path: video.path,
          mtime: video.mtime,
          duration: video.duration,
          title: newTitle,
          year: (nfoYear != null && nfoYear.isNotEmpty) ? nfoYear : video.year, 
          genres: metadata['genres'] ?? video.genres,
          directors: metadata['directors'] ?? video.directors,
          actors: metadata['actors'] ?? video.actors,
          plot: metadata['plot'] ?? video.plot,
          rating: metadata['rating'] ?? video.rating,
          posterPath: metadata['poster'] ?? video.posterPath,
        );

        // Optimization: Use DatabaseHelper directly here to avoid full refresh on every item.
        // The provider refresh is called once at the end of the loop.
        await DatabaseHelper.instance.updateVideo(updatedVideo);

        await MetadataService().updateFileMetadata(updatedVideo);
        updatedCount++;
        
      } catch (e) {
        errorCount++;
        debugPrint('Error renaming video ${video.path}: $e');
      }
      
      await Future.delayed(Duration.zero);
    }

    if (mounted && !isCancelled) Navigator.pop(context);

    if (isCancelled && allVideos.isNotEmpty && mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annullamento... Pulizia file temporanei in corso...')));
       final dir = p.dirname(allVideos.first.path);
       await MetadataService().cleanupTempFiles(dir);
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
                    decoration: const InputDecoration(
                      labelText: 'Cerca video...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFF3C3C3C),
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
                              dataRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFF3C3C3C)),
                              columns: const [
                                DataColumn(label: Text('#')),
                                DataColumn(label: Text('Titolo')),
                                DataColumn(label: Text('Anno')),
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
                                  DataCell(Text(video.duration)),
                                  DataCell(SizedBox(width: 150, child: Text(video.directors, overflow: TextOverflow.ellipsis))),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editVideo(video),
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
