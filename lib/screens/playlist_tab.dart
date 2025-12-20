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
    await provider.generateRandom(count);
    _checkResult(provider.playlist);
  }
  
  Future<void> _generateRecent(PlaylistProvider provider) async {
    final count = await _inputCount();
    if (count == null) return;
    await provider.generateRecent(count);
    _checkResult(provider.playlist);
  }

  Future<void> _generateFiltered(PlaylistProvider provider) async {
    final settings = await showDialog(
      context: context,
      builder: (ctx) => const FilterDialog(),
    );

    if (settings != null) {
      try {
        await provider.generateFiltered(
          genres: settings.genres,
          years: settings.years,
          minRating: settings.ratingMin,
          actors: settings.actors,
          directors: settings.directors,
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
                       child: v.posterPath.isNotEmpty 
                          ? (v.posterPath.startsWith('http') 
                             ? Image.network(v.posterPath, fit: BoxFit.cover) 
                             : Image.file(File(v.posterPath), fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.movie, size: 50)))
                          : const Icon(Icons.movie, size: 50),
                     ),
                     Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
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
              Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(5)),
                 child: Text(
                   !provider.hasPlaylist ? 'Nessuna playlist generata' : 'Playlist corrente: ${provider.playlist.length} video',
                   style: const TextStyle(color: Colors.white),
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
