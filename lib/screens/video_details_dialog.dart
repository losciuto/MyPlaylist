import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../providers/playlist_provider.dart';
import '../services/settings_service.dart';
import '../services/tmdb_service.dart';
import '../utils/nfo_generator.dart';
import '../providers/database_provider.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import '../widgets/person_avatar.dart';

class VideoDetailsDialog extends StatefulWidget {
  final Video video;

  const VideoDetailsDialog({super.key, required this.video});

  @override
  State<VideoDetailsDialog> createState() => _VideoDetailsDialogState();
}

class _VideoDetailsDialogState extends State<VideoDetailsDialog> {
  bool _isDownloading = false;
  late final ScrollController _directorsController;
  late final ScrollController _actorsController;

  @override
  void initState() {
    super.initState();
    _directorsController = ScrollController();
    _actorsController = ScrollController();
  }

  @override
  void dispose() {
    _directorsController.dispose();
    _actorsController.dispose();
    super.dispose();
  }

  Future<void> _downloadInfo() async {
    final apiKey = context.read<SettingsService>().tmdbApiKey;
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.tmdbApiKeyMissing)));
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.tmdbNoResults)));
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
            title: Text(AppLocalizations.of(context)!.selectMovieTitle),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.tmdbSuccessMsg)));
        Navigator.pop(context); // Close dialog
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.genericError(e.toString()))));
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
    final iconColor = isDark ? Colors.white54 : Colors.grey;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: cardColor,
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
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: widget.video.posterPath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.video.posterPath.startsWith('http')
                            ? Image.network(widget.video.posterPath, fit: BoxFit.cover)
                            : Image.file(
                                File(widget.video.posterPath),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(Icons.movie, size: 80, color: iconColor),
                                ),
                              ),
                      )
                    : Center(
                        child: Icon(Icons.movie, size: 80, color: iconColor),
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
                            widget.video.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: iconColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (widget.video.year.isNotEmpty) _buildTag(widget.video.year, Colors.blue),
                        if (widget.video.duration.isNotEmpty) _buildTag(widget.video.duration, Colors.purple),
                        if (widget.video.saga.isNotEmpty) _buildTag('Saga: ${widget.video.saga}', Colors.orangeAccent),
                        
                        // Interactive Rating
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                widget.video.rating.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 120,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                  ),
                                  child: Slider(
                                    value: widget.video.rating,
                                    min: 0,
                                    max: 10,
                                    divisions: 20,
                                    activeColor: Colors.amber,
                                    onChanged: (val) {
                                      final settings = context.read<SettingsService>();
                                      context.read<DatabaseProvider>().updateVideo(
                                        widget.video.copyWith(rating: val),
                                        syncNfo: settings.autoSyncNfoOnEdit,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Buttons: Play & Sync
                    Row(
                      children: [
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<PlaylistProvider>().playSingleVideo(widget.video);
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: Text(l10n.playButtonLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Refresh from NFO
                        SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await context.read<DatabaseProvider>().refreshFromNfo(widget.video);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.nfoLoadedMsg)));
                                Navigator.pop(context); // Close and reopen or just refresh (easier to close for now)
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: Text(l10n.loadFromNfo),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Save to NFO
                        SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final success = await context.read<DatabaseProvider>().saveToNfo(widget.video);
                              if (mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NFO salvato con successo!'), backgroundColor: Colors.green));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore durante il salvataggio NFO'), backgroundColor: Colors.red));
                                }
                              }
                            },
                            icon: const Icon(Icons.save, size: 18),
                            label: Text(l10n.saveAll),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.video.genres.isNotEmpty) ...[
                          _buildSectionTitle(l10n.sectionGenres),
                          Text(widget.video.genres, style: TextStyle(color: secondaryTextColor, fontSize: 16)),
                          const SizedBox(height: 15),
                        ],
                        if (widget.video.directors.isNotEmpty) ...[
                          _buildSectionTitle(l10n.sectionDirectors ?? 'REGIA'),
                          _buildPeopleList(widget.video.directors, widget.video.directorThumbs, _directorsController),
                          const SizedBox(height: 15),
                        ],
                        if (widget.video.actors.isNotEmpty) ...[
                          _buildSectionTitle(l10n.sectionCast),
                          _buildPeopleList(widget.video.actors, widget.video.actorThumbs, _actorsController),
                          const SizedBox(height: 15),
                        ],
                        if (widget.video.plot.isNotEmpty) ...[
                          _buildSectionTitle(l10n.sectionPlot),
                          Text(widget.video.plot, style: TextStyle(color: secondaryTextColor, fontSize: 16, height: 1.4)),
                          const SizedBox(height: 15),
                        ],
                        if (widget.video.saga.isNotEmpty) ...[
                          _buildSectionTitle(l10n.sectionSaga),
                          Text(widget.video.saga, style: TextStyle(color: secondaryTextColor, fontSize: 16)),
                          const SizedBox(height: 15),
                        ],
                        _buildSectionTitle(l10n.sectionFile),
                        Text(widget.video.path, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

  Widget _buildPeopleList(String namesStr, String thumbsStr, ScrollController controller) {
    final names = namesStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final thumbs = thumbsStr.split('|').map((e) => e.trim()).toList();

    return SizedBox(
      height: 125, // Slightly increased to accommodate scrollbar
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: ListView.builder(
          controller: controller,
          padding: const EdgeInsets.only(bottom: 10),
          scrollDirection: Axis.horizontal,
          itemCount: names.length,
          itemBuilder: (context, index) {
            final name = names[index];
            final thumb = index < thumbs.length ? thumbs[index] : '';
            return PersonAvatar(name: name, thumbUrl: thumb);
          },
        ),
      ),
    );
  }
}
