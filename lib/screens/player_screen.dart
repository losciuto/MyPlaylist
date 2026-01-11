import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;
import '../models/video.dart' as model;
import '../services/scan_service.dart';

class PlayerScreen extends StatefulWidget {
  final List<model.Video> playlist;
  const PlayerScreen({super.key, required this.playlist});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player player;
  late final VideoController controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    player = Player(
       configuration: const PlayerConfiguration(
          logLevel: MPVLogLevel.info,
       ),
    );
    controller = VideoController(player);
    
    _initPlaylist();

    // Listen for errors
    player.stream.error.listen((event) {
      debugPrint('Player Error: $event');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore Player: $event')));
      }
    });
  }

  Future<void> _initPlaylist() async {
    List<Media> mediaList = [];

    for (final video in widget.playlist) {
      if (video.isSeries) {
        final dir = Directory(video.path);
        if (await dir.exists()) {
          final List<File> episodes = [];
          try {
            // Recursive scan for video files
            await for (final entity in dir.list(recursive: true, followLinks: false)) {
              if (entity is File) {
                final ext = p.extension(entity.path).toLowerCase();
                if (ScanService.videoExtensions.contains(ext)) {
                  episodes.add(entity);
                }
              }
            }
            // Sort episodes alphabetically to ensure correct order
            episodes.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
            
            mediaList.addAll(episodes.map((e) => Media(e.path)));
          } catch (e) {
             debugPrint('Error scanning series folder: $e');
          }
        }
      } else {
        mediaList.add(Media(video.path));
      }
    }

    if (mounted) {
      if (mediaList.isNotEmpty) {
        await player.open(Playlist(mediaList));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessun file video trovato per la riproduzione.'))
        );
      }
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _isLoading 
              ? const CircularProgressIndicator()
              : Video(controller: controller),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
