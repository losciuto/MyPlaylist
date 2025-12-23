import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/video.dart';
import '../providers/playlist_provider.dart';

class VideoDetailsDialog extends StatelessWidget {
  final Video video;

  const VideoDetailsDialog({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2B2B2B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 900,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Poster
              Container(
                width: 350,
                height: 500,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black,
                ),
                child: video.posterPath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: video.posterPath.startsWith('http')
                            ? Image.network(video.posterPath, fit: BoxFit.cover)
                            : Image.file(
                                File(video.posterPath),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.movie, size: 80, color: Colors.white54),
                                ),
                              ),
                      )
                    : const Center(
                        child: Icon(Icons.movie, size: 80, color: Colors.white54),
                      ),
              ),
              const SizedBox(width: 20),
              // Right: Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            video.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (video.year.isNotEmpty) _buildTag(video.year, Colors.blue),
                        if (video.duration.isNotEmpty) _buildTag(video.duration, Colors.purple),
                        _buildTag('★ ${video.rating.toStringAsFixed(1)}', Colors.amber),
                        if (video.directors.isNotEmpty) _buildTag('Regia: ${video.directors}', Colors.teal),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Play Button (Moved and resized)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 200, // Reduced width
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.read<PlaylistProvider>().playSingleVideo(video);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('RIPRODUCI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (video.genres.isNotEmpty) ...[
                          _buildSectionTitle('Generi'),
                          Text(video.genres, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 15),
                        ],
                        if (video.actors.isNotEmpty) ...[
                          _buildSectionTitle('Cast'),
                          Text(video.actors, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 15),
                        ],
                        if (video.plot.isNotEmpty) ...[
                          _buildSectionTitle('Trama'),
                          Text(video.plot, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4)),
                          const SizedBox(height: 15),
                        ],
                        _buildSectionTitle('File'),
                        Text(video.path, style: const TextStyle(color: Colors.white30, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF4CAF50),
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
