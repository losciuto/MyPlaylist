import 'package:flutter/material.dart';
import '../models/video.dart';
import '../database/app_database.dart' as db;
import 'video_preview_dialog.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

class FilterVideosDialog extends StatefulWidget {
  final String title;
  final String category;
  final String filterValue;

  const FilterVideosDialog({
    super.key,
    required this.title,
    required this.category,
    required this.filterValue,
  });

  @override
  State<FilterVideosDialog> createState() => _FilterVideosDialogState();
}

class _FilterVideosDialogState extends State<FilterVideosDialog> {
  List<Video> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final videos = await db.AppDatabase.instance.getVideosByFilter(widget.category, widget.filterValue);
    if (mounted) {
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    }
  }

  void _showPreview(Video video) {
    showDialog(
      context: context,
      builder: (ctx) => VideoPreviewDialog(video: video),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2B2B2B),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 1000,
        height: 700,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.movie_filter, color: Color(0xFF4CAF50), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.videosFor(widget.title, widget.filterValue),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 20),
            
            // Stats
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.foundVideos(_videos.length),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 10),

            // List Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF3C3C3C),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(AppLocalizations.of(context)!.labelTitle, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 1, child: Text(AppLocalizations.of(context)!.labelYear, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 1, child: Text(AppLocalizations.of(context)!.ratingLabel(''), style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 4, child: Text(AppLocalizations.of(context)!.pathLabel(''), style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
            ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3C3C3C),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListView.separated(
                        itemCount: _videos.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1, color: Colors.white10),
                        itemBuilder: (ctx, index) {
                          final video = _videos[index];
                          return InkWell(
                            onTap: () => _showPreview(video),
                            onDoubleTap: () => _showPreview(video),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      video.title,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      video.year,
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.orange, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          video.rating.toStringAsFixed(1),
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: SelectableText(
                                      video.path,
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
