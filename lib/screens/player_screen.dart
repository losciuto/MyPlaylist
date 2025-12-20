import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/video.dart' as model;

class PlayerScreen extends StatefulWidget {
  final List<model.Video> playlist;
  const PlayerScreen({super.key, required this.playlist});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player player;
  late final VideoController controller;

  @override
  void initState() {
    super.initState();
    player = Player(
       configuration: const PlayerConfiguration(
          logLevel: MPVLogLevel.info,
       ),
    );
    controller = VideoController(player);
    
    // Create Media list
    final mediaList = widget.playlist.map((v) => Media(v.path)).toList();
    
    // Open playlist
    player.open(Playlist(mediaList));

    // Listen for errors
    player.stream.error.listen((event) {
      debugPrint('Player Error: $event');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore Player: $event')));
      }
    });
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
            child: Video(controller: controller),
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
