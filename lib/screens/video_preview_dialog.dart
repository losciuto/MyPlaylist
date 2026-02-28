import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../models/video.dart';
import '../providers/playlist_provider.dart';
import '../services/settings_service.dart';
import '../services/tmdb_service.dart';
import '../utils/nfo_generator.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

class VideoPreviewDialog extends StatefulWidget {
  final Video video;
  final Set<String>? selectedEpisodePaths;
  final VoidCallback? onSelectionChanged;

  const VideoPreviewDialog({
    super.key, 
    required this.video,
    this.selectedEpisodePaths,
    this.onSelectionChanged,
  });

  @override
  State<VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<VideoPreviewDialog> {
  List<File>? _episodes;
  bool _isLoadingEpisodes = false;

  @override
  void initState() {
    super.initState();
    if (widget.video.isSeries) {
      _loadEpisodes();
    }
  }

  Future<void> _loadEpisodes() async {
    setState(() => _isLoadingEpisodes = true);
    final dir = Directory(widget.video.path);
    if (!await dir.exists()) {
      setState(() {
        _episodes = [];
        _isLoadingEpisodes = false;
      });
      return;
    }

    const videoExtensions = [
      '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.mpg', 
      '.mpeg', '.m2v', '.ts', '.mts', '.m2ts', '.vob', '.ogv', '.ogg', '.qt', 
      '.yuv', '.rm', '.rmvb', '.asf', '.amv', '.divx', '.3gp', '.3g2', '.mxf'
    ];

    List<File> files = [];
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (videoExtensions.contains(ext)) {
            files.add(entity);
          }
        }
      }
      files.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    } catch (e) {
      debugPrint('Error loading episodes: $e');
    }

    if (mounted) {
      setState(() {
        _episodes = files;
        _isLoadingEpisodes = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // Theme aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = Theme.of(context).cardColor;
    final l10n = AppLocalizations.of(context)!;

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
                      color: Colors.black.withValues(alpha: 0.2),
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
                              errorBuilder: (context, error, stackTrace) => Center(
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
                    label: Text(l10n.playButtonLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.sectionPlot.toUpperCase(),
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

              // Episodes Section
              if (widget.video.isSeries) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.sectionEpisodes.toUpperCase(),
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
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isLoadingEpisodes
                      ? const Center(child: CircularProgressIndicator())
                      : (_episodes == null || _episodes!.isEmpty)
                          ? Center(child: Text(l10n.noEpisodesFound, style: const TextStyle(color: Colors.grey)))
                          : ListView.separated(
                              itemCount: _episodes!.length,
                              separatorBuilder: (ctx, i) => const Divider(height: 1, color: Colors.white10),
                              itemBuilder: (ctx, i) {
                                final episodeFile = _episodes![i];
                                final epPath = episodeFile.path;
                                final isSelected = widget.selectedEpisodePaths?.contains(epPath) ?? false;
                                
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: widget.selectedEpisodePaths == null ? null : (val) {
                                    setState(() {
                                      if (val == true) {
                                        widget.selectedEpisodePaths!.add(epPath);
                                      } else {
                                        widget.selectedEpisodePaths!.remove(epPath);
                                      }
                                    });
                                    if (widget.onSelectionChanged != null) {
                                      widget.onSelectionChanged!();
                                    }
                                  },
                                  title: Text(
                                    p.basename(epPath),
                                    style: TextStyle(color: textColor, fontSize: 13),
                                  ),
                                  dense: true,
                                  activeColor: const Color(0xFF4CAF50),
                                  controlAffinity: ListTileControlAffinity.leading,
                                );
                              },
                            ),
                ),
                const SizedBox(height: 24),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}
