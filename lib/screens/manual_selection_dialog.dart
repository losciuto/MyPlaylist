import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/video.dart';
import '../database/database_helper.dart';
import 'video_preview_dialog.dart';

class ManualSelectionDialog extends StatefulWidget {
  const ManualSelectionDialog({super.key});

  @override
  State<ManualSelectionDialog> createState() => _ManualSelectionDialogState();
}

class _ManualSelectionDialogState extends State<ManualSelectionDialog> {
  List<Video> _allVideos = [];
  List<Video> _filteredVideos = [];
  final Set<int> _selectedIds = {};
  final Set<String> _selectedEpisodePaths = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final videos = await DatabaseHelper.instance.getAllVideos();
    if (mounted) {
      setState(() {
        _allVideos = videos;
        _filteredVideos = videos;
        _isLoading = false;
      });
    }
  }

  void _filterVideos(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredVideos = _allVideos.where((v) {
        return v.title.toLowerCase().contains(lowerQuery) ||
            v.year.contains(lowerQuery) ||
            v.genres.toLowerCase().contains(lowerQuery) ||
            v.directors.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  void _showPreview(Video video) {
    showDialog(
      context: context,
      builder: (ctx) => VideoPreviewDialog(
        video: video,
        selectedEpisodePaths: video.isSeries ? _selectedEpisodePaths : null,
        onSelectionChanged: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _toggleSelection(Video video) {
    setState(() {
      if (_selectedIds.contains(video.id)) {
        _selectedIds.remove(video.id);
      } else {
        if (video.id != null) _selectedIds.add(video.id!);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds.addAll(_filteredVideos.map((v) => v.id).whereType<int>());
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<List<File>> _getEpisodes(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];
    
    const videoExtensions = [
    '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.mpg', 
    '.mpeg', '.m2v', '.ts', '.mts', '.m2ts', '.vob', '.ogv', '.ogg', '.qt', 
    '.yuv', '.rm', '.rmvb', '.asf', '.amv', '.divx', '.3gp', '.3g2', '.mxf'
  ];

    List<File> episodes = [];
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
           final ext = p.extension(entity.path).toLowerCase();
           if (videoExtensions.contains(ext)) {
             episodes.add(entity);
           }
        }
      }
      episodes.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    } catch (e) {
      debugPrint('Error scanning episodes: $e');
    }
    return episodes;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2B2B2B),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.edit_note, color: Color(0xFF4CAF50), size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Selezione Manuale Video',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Search and Statistics
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cerca per titolo, anno, regista...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
                      filled: true,
                      fillColor: const Color(0xFF3C3C3C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _filterVideos,
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Selezionati: ${_selectedIds.length}',
                      style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Totale visibili: ${_filteredVideos.length}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 10),

            // Action Buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: _selectAll,
                  icon: const Icon(Icons.check_box, size: 18),
                  label: const Text('Seleziona Tutti Visibili'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
                TextButton.icon(
                  onPressed: _deselectAll,
                  icon: const Icon(Icons.check_box_outline_blank, size: 18),
                  label: const Text('Deseleziona Tutti'),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3C3C3C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListView.separated(
                        itemCount: _filteredVideos.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1, color: Colors.white10),
                        itemBuilder: (ctx, index) {
                            final video = _filteredVideos[index];
                            final isSelected = _selectedIds.contains(video.id);

                            return ListTile(
                              onTap: () => _showPreview(video),
                              onLongPress: () => _toggleSelection(video),
                              leading: Checkbox(
                                value: isSelected,
                                activeColor: const Color(0xFF4CAF50),
                                onChanged: (v) => _toggleSelection(video),
                              ),
                              title: Row(
                                children: [
                                  if (video.isSeries) ...[
                                    const Icon(Icons.tv, color: Colors.blueAccent, size: 16),
                                    const SizedBox(width: 5),
                                    const Text('SERIE', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 5),
                                  ],
                                  Expanded(
                                    child: Text(
                                      video.title,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                video.isSeries
                                    ? '${video.year} • ${video.genres} • ★ ${video.rating.toStringAsFixed(1)}'
                                    : '${video.year} • ★ ${video.rating.toStringAsFixed(1)} • ${video.directors}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                maxLines: 1,
                              ),
                              trailing: video.posterPath.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.image, color: Colors.white24, size: 20),
                                      onPressed: () => _showPreview(video),
                                    )
                                  : null,
                            );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    // 1. Get standard selected videos
                    final selectedVideos = _allVideos.where((v) => _selectedIds.contains(v.id)).toList();
                    
                    // 2. Create virtual Video objects for selected episodes
                    for (final epPath in _selectedEpisodePaths) {
                      // Find parent series for metadata
                      try {
                        // Simple heuristic: find series that contains this path
                        // Or just iterate all series videos and check path starts with
                        final parentSeries = _allVideos.firstWhere(
                          (v) => v.isSeries && epPath.startsWith(v.path),
                          orElse: () => Video(path: '', mtime: 0), // Dummy
                        );
                        
                        if (parentSeries.path.isNotEmpty) {
                          selectedVideos.add(Video(
                            id: null, // Virtual
                            path: epPath,
                            mtime: File(epPath).lastModifiedSync().millisecondsSinceEpoch.toDouble(),
                            title: p.basename(epPath),
                            isSeries: false, // Treated as individual file
                            year: parentSeries.year,
                            genres: parentSeries.genres,
                            directors: parentSeries.directors,
                            rating: parentSeries.rating,
                            posterPath: parentSeries.posterPath,
                            plot: parentSeries.plot,
                          ));
                        }
                      } catch (e) {
                         debugPrint('Error creating virtual video for $epPath: $e');
                      }
                    }
                    
                    Navigator.pop(context, selectedVideos);
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Crea Playlist'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
