import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../providers/playlist_provider.dart';
import '../services/settings_service.dart';
import '../services/tmdb_service.dart';
import '../utils/nfo_generator.dart';

class VideoPreviewDialog extends StatefulWidget {
  final Video video;

  const VideoPreviewDialog({super.key, required this.video});

  @override
  State<VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<VideoPreviewDialog> {
  bool _isDownloading = false;

  Future<void> _downloadInfo() async {
    final apiKey = context.read<SettingsService>().tmdbApiKey;
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key TMDB mancante!')));
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final service = TmdbService(apiKey);
      final query = widget.video.title.replaceAll(RegExp(r'\s*\(\d{4}\)'), '').replaceAll('.', ' ');
      final yearStr = RegExp(r'\((\d{4})\)').firstMatch(widget.video.title)?.group(1);
      final int? year = yearStr != null ? int.tryParse(yearStr) : null;

      final results = await service.searchMovie(query, year: year);

      if (results.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessun risultato trovato su TMDB.')));
        setState(() => _isDownloading = false);
        return;
      }

      Map<String, dynamic> selectedMovie;
      if (results.length == 1) {
        selectedMovie = results.first;
      } else {
        if (!mounted) return;
        final selection = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Seleziona Film'),
            children: results.map((m) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, m),
              child: Text('${m['title']} (${m['release_date']?.toString().split('-').first ?? 'N/A'})'),
            )).toList(),
          ),
        );
        if (selection == null) {
          setState(() => _isDownloading = false);
          return;
        }
        selectedMovie = selection;
      }

      final details = await service.getMovieDetails(selectedMovie['id']);
      final nfoContent = NfoGenerator.generateMovieNfo(details);

      // Save NFO
      final videoFile = File(widget.video.path);
      final nfoPath = '${videoFile.parent.path}/${videoFile.uri.pathSegments.last.replaceAll(RegExp(r'\.[^.]+$'), '')}.nfo';
      await File(nfoPath).writeAsString(nfoContent);

      // Download Poster (Optional)
      if (details['poster_path'] != null) {
        final posterUrl = 'https://image.tmdb.org/t/p/original${details['poster_path']}';
        final posterPath = '${videoFile.parent.path}/${videoFile.uri.pathSegments.last.replaceAll(RegExp(r'\.[^.]+$'), '')}-poster.jpg';
        final response = await http.get(Uri.parse(posterUrl));
        if (response.statusCode == 200) {
          await File(posterPath).writeAsBytes(response.bodyBytes);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Info scaricate con successo! Riavvia la scansione per aggiornare.')));
        Navigator.pop(context); // Close dialog
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = Theme.of(context).cardColor;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title and Close
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.video.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Poster
              Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isDark ? Colors.black45 : Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: widget.video.posterPath.isNotEmpty
                      ? (widget.video.posterPath.startsWith('http')
                          ? Image.network(widget.video.posterPath, fit: BoxFit.contain)
                          : Image.file(
                              File(widget.video.posterPath),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.movie, size: 80, color: secondaryTextColor),
                              ),
                            ))
                      : Center(
                          child: Icon(Icons.movie, size: 80, color: secondaryTextColor),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Info Row
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (widget.video.year.isNotEmpty) _buildChip(widget.video.year, Colors.blue),
                  if (widget.video.duration.isNotEmpty) _buildChip(widget.video.duration, Colors.purple),
                  _buildChip('★ ${widget.video.rating.toStringAsFixed(1)}', Colors.orange),
                  if (widget.video.directors.isNotEmpty) _buildChip('Regia: ${widget.video.directors}', Colors.teal),
                ],
              ),
              const SizedBox(height: 24),

              // Buttons (Play & TMDB)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   ElevatedButton.icon(
                    onPressed: () {
                      context.read<PlaylistProvider>().playSingleVideo(widget.video);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('RIPRODUCI', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 15),
/*
                  ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadInfo,
                    icon: _isDownloading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                      : const Icon(Icons.download),
                    label: const Text('Info TMDB'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
*/
                ],
              ),

              const SizedBox(height: 24),
  
              // Plot
              if (widget.video.plot.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'TRAMA:',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.video.plot,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}
