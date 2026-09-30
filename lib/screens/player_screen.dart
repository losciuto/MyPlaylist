import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;
import '../models/video.dart' as model;
import 'package:my_playlist/l10n/app_localizations.dart';
import '../utils/video_extensions.dart';
import '../services/logger_service.dart';
import '../services/error_reporter_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.playlist});
  final List<model.Video> playlist;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player player;
  late final VideoController controller;
  StreamSubscription<String>? _errorSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    player = Player(
      configuration: const PlayerConfiguration(logLevel: MPVLogLevel.info),
    );
    controller = VideoController(player);

    _initPlaylist();

    // Listen for errors
    _errorSubscription = player.stream.error.listen((event) {
      LoggerService().debug('Player Error: $event');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.playerError(event.toString()),
            ),
          ),
        );
      }
    });
  }

  Future<void> _initPlaylist() async {
    final List<Media> mediaList = [];

    for (final video in widget.playlist) {
      if (video.isSeries) {
        final dir = Directory(video.path);
        if (await dir.exists()) {
          final List<File> episodes = [];
          try {
            // Recursive scan for video files
            await for (final entity in dir.list(
              recursive: true,
              followLinks: false,
            )) {
              if (entity is File) {
                final ext = p.extension(entity.path).toLowerCase();
                if (VideoExtensions.supported.contains(ext)) {
                  episodes.add(entity);
                }
              }
            }
            // Sort episodes alphabetically to ensure correct order
            episodes.sort(
              (a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()),
            );

            mediaList.addAll(episodes.map((e) => Media(e.path)));
          } on Exception catch (e) {
            errorReporter.report(
              'Scansione della cartella serie non riuscita',
              e,
              source: 'PlayerScreen',
            );
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
          SnackBar(content: Text(AppLocalizations.of(context)!.playerNoFile)),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    _errorSubscription = null;
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
              tooltip: AppLocalizations.of(context)!.goBack,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
