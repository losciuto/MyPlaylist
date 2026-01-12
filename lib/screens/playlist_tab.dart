import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../providers/playlist_provider.dart'; // Import Provider
import '../models/video.dart';
import '../services/settings_service.dart';
import 'player_screen.dart';
import 'filter_dialog.dart';
import 'video_details_dialog.dart';

import 'manual_selection_dialog.dart';
import '../services/remote_control_service.dart';

class PlaylistTab extends StatefulWidget {
  const PlaylistTab({super.key});

  @override
  State<PlaylistTab> createState() => _PlaylistTabState();
}

class _PlaylistTabState extends State<PlaylistTab> {

  @override
  void initState() {
    super.initState();
    // Refresh video count when tab is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
       context.read<PlaylistProvider>().updateVideoCount();
    });
  }

  Future<void> _generateRandom(PlaylistProvider provider) async {
    final count = await _inputCount();
    if (count == null) return;
    await provider.generateRandom(count: count);
    _checkResult(provider.playlist);
  }
  
  Future<void> _generateRecent(PlaylistProvider provider) async {
    final count = await _inputCount();
    if (count == null) return;
    await provider.generateRecentPlaylist(count: count);
    _checkResult(provider.playlist);
  }

  Future<void> _generateFiltered(PlaylistProvider provider) async {
    final settings = await showDialog(
      context: context,
      builder: (ctx) => const FilterDialog(),
    );

    if (settings != null) {
      try {
        await provider.generateFilteredPlaylist(
          genres: settings.genres,
          years: settings.years,
          minRating: settings.ratingMin,
          actors: settings.actors,
          directors: settings.directors,
          excludedGenres: settings.excludedGenres,
          excludedYears: settings.excludedYears,
          excludedActors: settings.excludedActors,
          excludedDirectors: settings.excludedDirectors,
          sagas: settings.sagas,
          excludedSagas: settings.excludedSagas,
          limit: settings.limit
        );
        _checkResult(provider.playlist);
      } catch (e) {
        debugPrint('Error generating playlist: $e');
        _showSnack('Errore generazione playlist: $e');
      }
    }
  }

  Future<void> _generateManual(PlaylistProvider provider) async {
    final List<Video>? selectedVideos = await showDialog<List<Video>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ManualSelectionDialog(),
    );

    if (selectedVideos != null && selectedVideos.isNotEmpty) {
      await provider.setPlaylist(selectedVideos);
      _checkResult(provider.playlist);
    }
  }

  void _checkResult(List<Video> videos) {
    if (videos.isEmpty) {
      _showSnack('Nessun video trovato!');
    } else {
      _showSnack('Generata playlist di ${videos.length} video.');
    }
  }

  Future<int?> _inputCount() async {
    final defaultSize = context.read<SettingsService>().defaultPlaylistSize;
    final controller = TextEditingController(text: defaultSize.toString());
    return showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Numero di video'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quanti video vuoi includere?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _playPlaylist(PlaylistProvider provider) async {
    if (!provider.hasPlaylist) return;

    final settings = context.read<SettingsService>();
    final playerPath = settings.playerPath;

    if (playerPath.isNotEmpty) {
      try {
        final playlistPath = await provider.createTempPlaylistFile();
        
        // Launch player process via provider
        await provider.launchPlayer(playerPath, playlistPath);
        _showSnack('Avviato player esterno: ${p.basename(playerPath)}');

      } catch (e) {
        _showSnack('Errore avvio player esterno: $e');
        debugPrint('External player error: $e');
      }
    } else {
      // Use internal player
      Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(playlist: provider.playlist)));
    }
  }

  Future<void> _openTempPlaylistFolder(PlaylistProvider provider) async {
    if (provider.lastTempPlaylistPath != null) {
      final dir = p.dirname(provider.lastTempPlaylistPath!);
      try {
        if (Platform.isLinux) {
           await Process.run('xdg-open', [dir]);
        } else if (Platform.isWindows) {
           await Process.run('explorer', [dir]);
        }
      } catch (e) {
         _showSnack('Impossibile aprire la cartella: $e');
      }
    }
  }
  
  void _showVideoDetails(Video video) {
    showDialog(
      context: context,
      builder: (ctx) => VideoDetailsDialog(video: video),
    );
  }

  void _showPosters(PlaylistProvider provider) {
     if (!provider.hasPlaylist) return;
     showDialog(
       context: context,
       builder: (ctx) => Dialog(
         child: Container(
           width: 800,
           height: 600,
           padding: const EdgeInsets.all(20),
           child: GridView.builder(
             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
               crossAxisCount: 4,
               childAspectRatio: 0.7,
               crossAxisSpacing: 10,
               mainAxisSpacing: 10,
             ),
             itemCount: provider.playlist.length,
             itemBuilder: (ctx, index) {
               final v = provider.playlist[index];
               return GestureDetector(
                 onTap: () => _showVideoDetails(v),
                 child: Column(
                   children: [
                     Expanded(
                       child: Stack(
                         fit: StackFit.expand,
                         children: [
                           v.posterPath.isNotEmpty 
                             ? (v.posterPath.startsWith('http') 
                                ? Image.network(v.posterPath, fit: BoxFit.cover) 
                                : Image.file(File(v.posterPath), fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.movie, size: 50)))
                             : const Icon(Icons.movie, size: 50),
                           if (v.isSeries)
                             Positioned(
                               top: 5,
                               right: 5,
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                 decoration: BoxDecoration(
                                   color: Colors.blueAccent,
                                   borderRadius: BorderRadius.circular(4),
                                 ),
                                 child: const Text('SERIE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                               ),
                             ),
                         ],
                       ),
                     ),
                     Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         const Icon(Icons.star, color: Colors.orange, size: 10),
                         const SizedBox(width: 2),
                         Text(v.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: Colors.white70)),
                       ],
                     ),
                    ],
                  ),
               );
             },
           ),
         ),
       ),
     );
  }

  void _exportPlaylist(PlaylistProvider provider) async {
    final path = await provider.exportPlaylist();
    if (path != null) {
      _showSnack('Playlist esportata in $path');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('GENERA PLAYLIST (video presenti: ${provider.totalVideoCount})',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
              const SizedBox(height: 20),
              
              // Generation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBtn('🎲 Playlist Casuale', Colors.orange, () => _generateRandom(provider)),
                  _buildBtn('🕒 Più Recenti', Colors.blue, () => _generateRecent(provider)),
                ],
              ),
              const SizedBox(height: 20),
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _buildBtn('🎲 Playlist\ncon Filtri', Colors.purple, () => _generateFiltered(provider)),
                   _buildBtn('✏️ Selezione\nManuale', Colors.blueGrey, () => _generateManual(provider)),
                ],
              ),
              if (provider.proposedVideoCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextButton.icon(
                    onPressed: () => provider.resetProposedVideos(),
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.orange),
                    label: Text('Resetta cronologia sessione (${provider.proposedVideoCount} visti)', 
                      style: const TextStyle(fontSize: 11, color: Colors.orange)),
                  ),
                ),
              
              const Divider(height: 40, color: Colors.grey),
              
              // Action Buttons
              const Text('Azioni Playlist', style: TextStyle(fontSize: 16, color: Color(0xFF4CAF50))),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBtn('🎨 Mostra Poster', Colors.pink, provider.hasPlaylist ? () => _showPosters(provider) : null),
                  _buildBtn('▶️ Riproduci', const Color(0xFF4CAF50), provider.hasPlaylist ? () => _playPlaylist(provider) : null),
                  _buildBtn('💾 Esporta', Colors.orange, provider.hasPlaylist ? () => _exportPlaylist(provider) : null),
                ],
              ),
              const SizedBox(height: 10),
              if (provider.lastTempPlaylistPath != null)
                 Center(
                   child: TextButton.icon(
                     onPressed: () => _openTempPlaylistFolder(provider),
                     icon: const Icon(Icons.folder_open, color: Colors.grey),
                     label: const Text('Apri cartella file temporaneo', style: TextStyle(color: Colors.grey)),
                   ),
                 ),
              
              const Spacer(),
              
              // Remote Command Logs Section
              Consumer<RemoteControlService>(
                builder: (context, remoteService, _) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600), // Limita la larghezza a 600px
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          leading: const Icon(Icons.history, color: Colors.blue, size: 20),
                          title: const Text('Log Comandi Remoti', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            remoteService.commandLogs.isEmpty 
                              ? 'In attesa...' 
                              : 'Ultimo: ${remoteService.commandLogs.first.command}', 
                            style: const TextStyle(fontSize: 11, color: Colors.grey)
                          ),
                          children: [
                            if (remoteService.commandLogs.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text('Nessun comando ricevuto.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              )
                            else
                              SizedBox(
                                height: 180,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: remoteService.commandLogs.length,
                                  itemBuilder: (context, index) {
                                    final log = remoteService.commandLogs[index];
                                    final timeStr = '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';
                                    
                                    return ListTile(
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                      title: Text(log.command, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                                      subtitle: Text(log.args.isEmpty ? 'Nessun parametro' : 'Parametri: ${log.args}', style: const TextStyle(fontSize: 10)),
                                      trailing: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(5)),
                 child: Text(
                   !provider.hasPlaylist ? 'Nessuna playlist generata' : 'Playlist corrente: ${provider.playlist.length} video',
                   style: TextStyle(color: Theme.of(context).listTileTheme.textColor ?? Theme.of(context).textTheme.bodyMedium?.color),
                 ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBtn(String label, Color color, VoidCallback? onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        fixedSize: const Size(150, 60),
      ),
      child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
    );
  }
}
