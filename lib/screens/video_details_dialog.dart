import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../providers/playlist_provider.dart';
import '../services/settings_service.dart';
import '../services/tmdb_service.dart';
import '../utils/nfo_generator.dart';
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
                      children: [
                        if (widget.video.year.isNotEmpty) _buildTag(widget.video.year, Colors.blue),
                        if (widget.video.duration.isNotEmpty) _buildTag(widget.video.duration, Colors.purple),
                        _buildTag('★ ${widget.video.rating.toStringAsFixed(1)}', Colors.amber),
                        if (widget.video.saga.isNotEmpty) _buildTag('Saga: ${widget.video.saga}', Colors.orangeAccent),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Buttons: Play & TMDB
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
                        /*
                        const SizedBox(width: 15),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: _isDownloading ? null : _downloadInfo,
                            icon: _isDownloading 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                              : const Icon(Icons.download),
                            label: const Text('Info TMDB', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        */
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
                          _buildPeopleList(widget.video.directors, widget.video.directorThumbs),
                          const SizedBox(height: 15),
                        ],
                        if (widget.video.actors.isNotEmpty) ...[
                          _buildSectionTitle(l10n.sectionCast),
                          _buildPeopleList(widget.video.actors, widget.video.actorThumbs),
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

  Widget _buildPeopleList(String namesStr, String thumbsStr) {
    final names = namesStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final thumbs = thumbsStr.split('|').map((e) => e.trim()).toList();
    final controller = ScrollController();

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
