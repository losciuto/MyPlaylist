import 'package:flutter/material.dart';
import '../models/video.dart';
import '../database/database_helper.dart';

class ManualSelectionDialog extends StatefulWidget {
  const ManualSelectionDialog({super.key});

  @override
  State<ManualSelectionDialog> createState() => _ManualSelectionDialogState();
}

class _ManualSelectionDialogState extends State<ManualSelectionDialog> {
  List<Video> _allVideos = [];
  List<Video> _filteredVideos = [];
  final Set<int> _selectedIds = {};
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
                            onTap: () => _toggleSelection(video),
                            leading: Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF4CAF50),
                              onChanged: (v) => _toggleSelection(video),
                            ),
                            title: Text(
                              video.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${video.year} • ${video.directors}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                              maxLines: 1,
                            ),
                            trailing: video.posterPath.isNotEmpty
                                ? const Icon(Icons.image, color: Colors.white24, size: 20)
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
                    final selectedVideos = _allVideos.where((v) => _selectedIds.contains(v.id)).toList();
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
