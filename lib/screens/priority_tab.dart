import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/video.dart';
import 'edit_video_dialog.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class PriorityTab extends StatefulWidget {
  const PriorityTab({super.key});

  @override
  State<PriorityTab> createState() => _PriorityTabState();
}

class _PriorityTabState extends State<PriorityTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<DatabaseProvider>().searchQuery;

    // Sync search bar when provider changes (e.g. from DB tab or photo filter)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatabaseProvider>().addListener(_onProviderChange);
    });
  }

  void _onProviderChange() {
    if (!mounted) return;
    final query = context.read<DatabaseProvider>().searchQuery;
    if (_searchController.text != query) {
      setState(() {
        _searchController.text = query;
      });
    }
  }

  void _filterVideos(String query) {
    context.read<DatabaseProvider>().filterVideos(query);
  }

  Future<void> _editVideo(Video video) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditVideoDialog(video: video),
    );

    if (result == true && mounted) {
      await context.read<DatabaseProvider>().refreshVideos();
    }
  }

  @override
  void dispose() {
    try {
      context.read<DatabaseProvider>().removeListener(_onProviderChange);
    } catch (e) {
      debugPrint('Error removing listener: $e');
    }

    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DatabaseProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    // Use filteredVideos instead of all videos
    final sortedVideos = List<Video>.from(provider.filteredVideos);
    sortedVideos.sort((a, b) {
      final aDate = a.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate); // Descending for Priority
    });

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.navPriority,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.read<DatabaseProvider>().syncDatesWithMtime();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.opCompleted)));
                  },
                  icon: const Icon(Icons.history_toggle_off),
                  label: Text(l10n.btnSyncDates),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.searchVideosPlaceholder,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _filterVideos('');
                          setState(() {});
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3C3C3C)
                    : Colors.grey[200],
              ),
              onChanged: _filterVideos,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: sortedVideos.isEmpty
                  ? Center(child: Text(l10n.noVideoFound))
                  : ListView.separated(
                      controller: _scrollController,
                      itemCount: sortedVideos.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final video = sortedVideos[index];
                        final dateStr = video.dateAdded != null
                            ? DateFormat.yMMMd(
                                Localizations.localeOf(context).toString(),
                              ).add_Hm().format(video.dateAdded!)
                            : '-';

                        return ListTile(
                          onTap: () => _editVideo(video),
                          title: Text(
                            video.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            video.path,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              if (video.year.isNotEmpty)
                                Text(
                                  video.year,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
