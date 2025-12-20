import 'dart:io';
import 'package:flutter/material.dart';
import '../models/video.dart';

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
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Poster
            Container(
              width: 350,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black,
              ),
              child: video.posterPath.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: video.posterPath.startsWith('http')
                          ? Image.network(video.posterPath, fit: BoxFit.cover)
                          : Image.file(File(video.posterPath), fit: BoxFit.cover,
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
                  Row(
                    children: [
                      if (video.year.isNotEmpty) _buildTag(video.year, Colors.blue),
                      if (video.duration.isNotEmpty) _buildTag(video.duration, Colors.purple),
                      if (video.rating > 0) _buildTag('★ ${video.rating}', Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           if (video.genres.isNotEmpty) ...[
                             _buildSectionTitle('Generi'),
                             Text(video.genres, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                             const SizedBox(height: 15),
                           ],
                           if (video.directors.isNotEmpty) ...[
                             _buildSectionTitle('Regia'),
                             Text(video.directors, style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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
