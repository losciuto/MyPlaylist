import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/video.dart';
import 'edit_video_dialog.dart';
import '../services/metadata_service.dart';
import '../utils/nfo_parser.dart';
import '../widgets/movie_selection_dialog.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../services/settings_service.dart';
import '../services/tmdb_service.dart';
import '../utils/nfo_generator.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import '../widgets/video_data_table.dart';
import '../services/video_processing_service.dart';

class DatabaseTab extends StatefulWidget {
  const DatabaseTab({super.key});

  @override
  State<DatabaseTab> createState() => _DatabaseTabState();
}

class _DatabaseTabState extends State<DatabaseTab> {
  final TextEditingController _searchController = TextEditingController();
  final VideoProcessingService _processingService = VideoProcessingService();
  final ScrollController _horizontalScrollController = ScrollController();
  
  bool _onlyMissingNfo = false;

  Future<void> _bulkGenerateNfo() async {
     final apiKey = context.read<SettingsService>().tmdbApiKey;
     final fanartApiKey = context.read<SettingsService>().fanartApiKey;
     
     if (apiKey.isEmpty) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.tmdbApiKeyMissing)));
       return;
     }

     final mode = await showDialog<String>(
       context: context,
       builder: (ctx) => AlertDialog(
         title: Text(AppLocalizations.of(context)!.tmdbGenTitle),
         content: StatefulBuilder(
           builder: (context, setState) {
             return Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(AppLocalizations.of(context)!.tmdbGenModeMsg),
                 const SizedBox(height: 20),
                 CheckboxListTile(
                   title: Text(AppLocalizations.of(context)!.onlyMissingNfo),
                   value: _onlyMissingNfo,
                   onChanged: (val) {
                     setState(() {
                        _onlyMissingNfo = val ?? false;
                     });
                   },
                   contentPadding: EdgeInsets.zero,
                   controlAffinity: ListTileControlAffinity.leading,
                 ),
               ],
             );
           }
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
           ElevatedButton(onPressed: () => Navigator.pop(ctx, 'auto'), child: Text(AppLocalizations.of(context)!.tmdbClickAuto)),
           ElevatedButton(onPressed: () => Navigator.pop(ctx, 'interactive'), child: Text(AppLocalizations.of(context)!.tmdbClickInteractive)),
         ],
       ),
     );
     
     if (mode == null) return;
     if (!mounted) return;

     final provider = context.read<DatabaseProvider>();
     final allVideos = List<Video>.from(provider.videos);
     final total = allVideos.length;

     if (total == 0) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noVideoInDb)));
       return;
     }

     final progressNotifier = ValueNotifier<VideoProcessingStatus>(VideoProcessingStatus(current: 0, total: total, currentTitle: '-'));
     
     // Show progress dialog always, user can see status
     showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF3C3C3C),
            content: ValueListenableBuilder<VideoProcessingStatus>(
              valueListenable: progressNotifier,
              builder: (ctx, status, _) {
                 return Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(AppLocalizations.of(context)!.downloadingInfo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 10),
                     Text(status.currentTitle, style: const TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                     const SizedBox(height: 10),
                     LinearProgressIndicator(value: status.current / total, color: Colors.blue),
                     Text('${status.current} / $total', style: const TextStyle(color: Colors.white54)),
                   ],
                 );
              }
            ),
            actions: [
              TextButton(onPressed: () { _processingService.cancel(); Navigator.pop(ctx); }, child: Text(AppLocalizations.of(context)!.stopAllButtonLabel))
            ],
          )
     );

     final result = await _processingService.bulkGenerateNfo(
       videos: allVideos,
       apiKey: apiKey,
       fanartApiKey: fanartApiKey,
       mode: mode,
       onlyMissingNfo: _onlyMissingNfo,
       onProgress: (status) => progressNotifier.value = status,
       onInteractiveSelection: (video, results) async {
          if (!mounted) return null;
          // Hide progress dialog temporarily maybe? No, showDialog stacks.
          // We show selection dialog on top.
          final choice = await showDialog<dynamic>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => MovieSelectionDialog(
              title: AppLocalizations.of(context)!.selectMovieTitle,
              results: results.map((r) => {
                'id': r['id'],
                'title': video.isSeries ? r['name'] : r['title'],
                'release_date': video.isSeries ? r['first_air_date'] : r['release_date'],
                'poster_path': r['poster_path'],
                'overview': r['overview'],
              }).toList(),
              isBulkMode: true,
            ),
          );

          if (choice is Map<String, dynamic> && choice['action'] == 'cancel') {
            _processingService.cancel();
            return null;
          }
          return choice as Map<String, dynamic>?;
       },
     );

     if (mounted && !_processingService.isCancelled) Navigator.pop(context); // Close progress dialog
     
     if (mounted) {
       await provider.refreshVideos();
       showDialog(
         context: context, 
         builder: (ctx) => AlertDialog(
           title: Text(AppLocalizations.of(context)!.genComplete),
           content: Text(AppLocalizations.of(context)!.genStats(result.updated.toString(), result.skipped.toString(), result.errors.toString())),
           actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.ok))]
         )
       );
     }
  }

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<DatabaseProvider>().searchQuery;
    
    // Sync search bar when provider changes (e.g. from photo filter)
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

  @override
  void dispose() {
    // We should safely remove the listener
    // This is tricky without a reference to the same provider instance if it changes
    // But usually provider is stable during tab lifetime.
    try {
      context.read<DatabaseProvider>().removeListener(_onProviderChange);
    } catch (e) {}
    
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _sortVideos(int columnIndex, bool ascending) {
    final provider = context.read<DatabaseProvider>();
    provider.sort(columnIndex, ascending);
  }

  // Wrappers to keep UI clean
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.videoUpdated)));
    }
  }

  Future<void> _deleteVideo(Video video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeleteTitle),
        content: Text(AppLocalizations.of(context)!.confirmDeleteMsg(video.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<DatabaseProvider>().deleteVideo(video);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.videoDeleted)));
    }
  }

  Future<void> _clearDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirm),
        content: Text(AppLocalizations.of(context)!.confirmClearDb),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.no)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context)!.yesDelete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<DatabaseProvider>().clearDatabase();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.dbCleared)));
    }
  }

  Future<void> _bulkRenameTitles() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.bulkRenameTitle),
        content: Text(AppLocalizations.of(context)!.bulkRenameMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(AppLocalizations.of(context)!.start)
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final provider = context.read<DatabaseProvider>();
    final allVideos = List<Video>.from(provider.videos);
    final total = allVideos.length;

    if (total == 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noVideoFound)));
      return;
    }

    final progressNotifier = ValueNotifier<VideoProcessingStatus>(VideoProcessingStatus(current: 0, total: total, currentTitle: '-'));
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF3C3C3C),
        title: Text(AppLocalizations.of(context)!.renaming, style: const TextStyle(color: Colors.white)),
        content: ValueListenableBuilder<VideoProcessingStatus>(
          valueListenable: progressNotifier,
          builder: (context, status, child) {
            final percent = (status.current / total * 100).toStringAsFixed(1);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.processing, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                const SizedBox(height: 5),
                Text(status.currentTitle, style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 20),
                LinearProgressIndicator(value: status.current / total, backgroundColor: Colors.white10, color: const Color(0xFF4CAF50)),
                const SizedBox(height: 15),
                Text('${status.current} / $total ($percent%)', style: const TextStyle(color: Colors.white70)),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () { _processingService.cancel(); Navigator.pop(ctx); }, child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    final result = await _processingService.bulkRenameTitles(
      videos: allVideos,
      onProgress: (status) => progressNotifier.value = status,
      onCancelCleanup: (dir) async {
        try {
          await MetadataService().cleanupTempFiles(dir);
        } catch (e) {
          debugPrint('Error cleaning temp files in $dir: $e');
        }
      },
    );

    if (mounted && !_processingService.isCancelled) Navigator.pop(context);

    if (_processingService.isCancelled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.cancelling)));
    }

    if (mounted) {
       await context.read<DatabaseProvider>().refreshVideos();
       showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_processingService.isCancelled ? AppLocalizations.of(context)!.opCancelled : AppLocalizations.of(context)!.opCompleted),
          content: Text(AppLocalizations.of(context)!.bulkOpStats(result.updated.toString(), result.skipped.toString(), result.errors.toString())),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.ok))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DatabaseProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header: Title and Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.databaseManagementTitle,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                Text(l10n.videosInDatabase(provider.filteredVideos.length),
                      style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
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
                    onChanged: _filterVideos, // Calls wrapper
                  ),
            const SizedBox(height: 10),
            // Action Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   ElevatedButton.icon(
                      onPressed: _clearDatabase,
                      icon: const Icon(Icons.delete_sweep),
                      label: Text(l10n.clearDatabaseButton),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                    ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => provider.refreshVideos(),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.refreshButton),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _bulkRenameTitles,
                    icon: const Icon(Icons.drive_file_rename_outline),
                    label: Text(l10n.renameTitlesButton),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _bulkGenerateNfo,
                    icon: const Icon(Icons.auto_fix_high),
                    label: Text(l10n.tmdbGenAuto),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // The Table
            Expanded(
              child: VideoDataTable(
                videos: provider.filteredVideos,
                sortColumnIndex: provider.sortColumnIndex,
                isSortedAscending: provider.sortAscending,
                onSort: _sortVideos,
                onEdit: _editVideo,
                onDelete: _deleteVideo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
