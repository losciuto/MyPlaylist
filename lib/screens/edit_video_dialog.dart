import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'edit/video_info_column.dart';
import 'edit/episodes_section.dart';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../services/metadata_service.dart';
import '../services/settings_service.dart';
import '../services/tmdb_service.dart';
import '../utils/nfo_parser.dart';
import '../utils/nfo_generator.dart';
import '../utils/video_extensions.dart';
import '../widgets/movie_selection_dialog.dart';
import 'package:path/path.dart' as p;
import '../widgets/file_metadata_dialog.dart';
import '../providers/database_provider.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../services/logger_service.dart';

class EditVideoDialog extends StatefulWidget {
  const EditVideoDialog({super.key, required this.video});
  final Video video;

  @override
  State<EditVideoDialog> createState() => _EditVideoDialogState();
}

class _EditVideoDialogState extends State<EditVideoDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _yearController;
  late TextEditingController _genresController;
  late TextEditingController _directorsController;
  late TextEditingController _actorsController;
  late TextEditingController _plotController;
  late TextEditingController _posterPathController;
  late TextEditingController _durationController;
  late TextEditingController _sagaController;
  late TextEditingController _sagaIndexController;
  late TextEditingController _dateAddedController;
  late TextEditingController _timeController;
  late DateTime? _dateAdded;
  late double _rating;

  bool _isSaving = false;
  bool _isDownloading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.video.title);
    _yearController = TextEditingController(text: widget.video.year);
    _genresController = TextEditingController(text: widget.video.genres);
    _directorsController = TextEditingController(text: widget.video.directors);
    _actorsController = TextEditingController(text: widget.video.actors);
    _plotController = TextEditingController(text: widget.video.plot);
    _posterPathController = TextEditingController(
      text: widget.video.posterPath,
    );
    _durationController = TextEditingController(text: widget.video.duration);
    _sagaController = TextEditingController(text: widget.video.saga);
    _sagaIndexController = TextEditingController(
      text: widget.video.sagaIndex.toString(),
    );
    _dateAdded = widget.video.dateAdded;
    _dateAddedController = TextEditingController(
      text: _dateAdded != null
          ? DateFormat('yyyy-MM-dd').format(_dateAdded!)
          : '',
    );
    _timeController = TextEditingController(
      text: _dateAdded != null ? DateFormat('HH:mm').format(_dateAdded!) : '',
    );
    _rating = widget.video.rating;
    _loadFileSize();
  }

  String _fileSizeString = '';

  Future<void> _loadFileSize() async {
    try {
      final file = File(widget.video.path);
      if (await file.exists()) {
        final len = await file.length();
        if (len < 1024 * 1024) {
          _fileSizeString = '${(len / 1024).toStringAsFixed(1)} KB';
        } else if (len < 1024 * 1024 * 1024) {
          _fileSizeString = '${(len / (1024 * 1024)).toStringAsFixed(1)} MB';
        } else {
          _fileSizeString =
              '${(len / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
        }
        if (mounted) setState(() {});
      }
    } on Exception catch (e) {
      LoggerService().debug('Error getting file size: $e');
    }
  }

  Future<void> _downloadTmdbInfo() async {
    final apiKey = context.read<SettingsService>().tmdbApiKey;
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.tmdbApiKeyMissing),
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final service = TmdbService(apiKey);

      // Use current controller text for search if available, else use CLEANED path basename
      String query = _titleController.text.trim();
      if (query.isEmpty) {
        query = _cleanQuery(widget.video.path);
      }

      int? year = int.tryParse(_yearController.text);
      if (year == null) {
        final yearMatch = RegExp(r'\((\d{4})\)').firstMatch(query);
        if (yearMatch != null) year = int.tryParse(yearMatch.group(1)!);
      }

      final isSeries = widget.video.isSeries;
      List<Map<String, dynamic>> results;

      if (isSeries) {
        results = await service.searchTvShow(query, year: year);
      } else {
        results = await service.searchMovie(query, year: year);
      }

      if (results.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.tmdbNoResults),
            ),
          );
          setState(() => _isDownloading = false);
        }
        return;
      }

      // Pre-process results for uniformity in dialog
      final formattedResults = results.map((r) {
        return {
          'id': r['id'],
          'title': isSeries ? r['name'] : r['title'],
          'release_date': isSeries ? r['first_air_date'] : r['release_date'],
          'poster_path': r['poster_path'],
          'overview': r['overview'],
          'original_title': isSeries ? r['original_name'] : r['original_title'],
        };
      }).toList();

      if (!mounted) return;
      final selectedMovie = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => MovieSelectionDialog(
          title: isSeries
              ? AppLocalizations.of(context)!.generalTab
              : AppLocalizations.of(context)!.selectMovieTitle,
          results: formattedResults,
        ),
      );

      if (selectedMovie == null) {
        if (mounted) setState(() => _isDownloading = false);
        return;
      }

      Map<String, dynamic> details;
      String nfoContent;
      if (isSeries) {
        details = await service.getTvShowDetails(selectedMovie['id']);
        if (!mounted) return;
        nfoContent = NfoGenerator.generateTvShowNfo(details);
      } else {
        details = await service.getMovieDetails(selectedMovie['id']);
        if (!mounted) return;
        nfoContent = NfoGenerator.generateMovieNfo(details);
      }

      // 1. Write NFO
      final videoFile = File(widget.video.path);
      // For series, nfo goes in the series folder as tvshow.nfo
      // For movies, it goes next to the file with same name
      String nfoPath;
      if (isSeries) {
        nfoPath = p.join(widget.video.path, 'tvshow.nfo');
        // Actually widget.video.path IS the series directory for series items (as per new logic)
        // Check if we need to make sure path is a directory
      } else {
        nfoPath = p.setExtension(videoFile.path, '.nfo');
      }

      await File(nfoPath).writeAsString(nfoContent);

      // 2. Download Poster
      String localPosterPath = _posterPathController.text;
      if (details['poster_path'] != null) {
        final posterUrl =
            'https://image.tmdb.org/t/p/original${details['poster_path']}';
        String newPosterPath;
        if (isSeries) {
          newPosterPath = p.join(widget.video.path, 'poster.jpg');
        } else {
          newPosterPath = p.join(
            p.dirname(videoFile.path),
            '${p.basenameWithoutExtension(videoFile.path)}-poster.jpg',
          );
        }

        final response = await http.get(Uri.parse(posterUrl));
        if (response.statusCode == 200) {
          await File(newPosterPath).writeAsBytes(response.bodyBytes);
          localPosterPath = newPosterPath;
        }
      }

      // 3. Download Fanart (Backdrop)
      if (details['backdrop_path'] != null) {
        final fanartUrl =
            'https://image.tmdb.org/t/p/original${details['backdrop_path']}';
        String fanartPath;
        if (isSeries) {
          fanartPath = p.join(widget.video.path, 'fanart.jpg');
        } else {
          final baseDir = p.dirname(videoFile.path);
          final baseFileName = p.basenameWithoutExtension(videoFile.path);
          fanartPath = p.join(baseDir, '$baseFileName-fanart.jpg');
        }

        final resp = await http.get(Uri.parse(fanartUrl));
        if (resp.statusCode == 200) {
          await File(fanartPath).writeAsBytes(resp.bodyBytes);
        }
      }

      // 4. Download Logo (Clearlogo)
      if (details['images'] != null && details['images']['logos'] != null) {
        final logos = details['images']['logos'] as List;
        if (logos.isNotEmpty) {
          final logoPathTail = logos.first['file_path'];
          final logoUrl = 'https://image.tmdb.org/t/p/original$logoPathTail';
          String logoPath;
          if (isSeries) {
            logoPath = p.join(widget.video.path, 'clearlogo.png');
          } else {
            final baseDir = p.dirname(videoFile.path);
            final baseFileName = p.basenameWithoutExtension(videoFile.path);
            logoPath = p.join(baseDir, '$baseFileName-clearlogo.png');
          }
          final resp = await http.get(Uri.parse(logoUrl));
          if (!mounted) return;
          if (resp.statusCode == 200) {
            await File(logoPath).writeAsBytes(resp.bodyBytes);
          }
        }
      }

      if (!mounted) return;

      // 5. Update UI
      setState(() {
        if (isSeries) {
          _titleController.text = details['name'] ?? _titleController.text;
          final firstAir = details['first_air_date']
              ?.toString()
              .split('-')
              .first;
          if (firstAir != null) _yearController.text = firstAir;
        } else {
          _titleController.text = details['title'] ?? _titleController.text;
          final releaseDate = details['release_date']
              ?.toString()
              .split('-')
              .first;
          if (releaseDate != null) _yearController.text = releaseDate;
        }

        if (details['genres'] != null) {
          final gList = (details['genres'] as List)
              .map((g) => g['name'])
              .join(', ');
          _genresController.text = gList;
        }

        if (details['overview'] != null) {
          _plotController.text = details['overview'];
        }

        if (isSeries) {
          if (details['episode_run_time'] != null &&
              (details['episode_run_time'] as List).isNotEmpty) {
            _durationController.text = details['episode_run_time'][0]
                .toString();
          }
        } else {
          if (details['runtime'] != null) {
            _durationController.text = details['runtime'].toString();
          }
        }

        if (details['vote_average'] != null) {
          _rating = (details['vote_average'] as num).toDouble();
        }

        _posterPathController.text = localPosterPath;
        _sagaController.text = (details['belongs_to_collection'] != null)
            ? (details['belongs_to_collection']['name'] ?? '')
            : '';
        if (details['credits'] != null) {
          final topCast =
              (details['credits']['cast'] as List?)?.take(5).toList() ?? [];
          _actorsController.text = topCast.map((c) => c['name']).join(', ');

          // We need to store these in the video object eventually,
          // but controllers only handle text fields.
          // I'll keep them as local variables to use in _save.

          if (isSeries) {
            if (details['created_by'] != null) {
              final creators = details['created_by'] as List;
              _directorsController.text = creators
                  .map((c) => c['name'])
                  .join(', ');
              // Extract Director Thumbs
            }
          } else {
            final crew =
                (details['credits']['crew'] as List?)
                    ?.where((c) => c['job'] == 'Director')
                    .toList() ??
                [];
            _directorsController.text = crew.map((c) => c['name']).join(', ');
            _directorsController.text = crew.map((c) => c['name']).join(', ');
          }
        }

        _isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.tmdbUpdatedMsg)),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.genericError(e.toString()),
            ),
          ),
        );
      }
      setState(() => _isDownloading = false);
    }
  }

  /// La colonna sinistra notifica la nuova data: i controller vanno
  /// aggiornati insieme allo stato.
  void _onDateAddedChanged(DateTime value) {
    setState(() {
      _dateAdded = value;
      _dateAddedController.text = formatDateAdded(value);
      _timeController.text = formatTimeAdded(value);
    });
  }

  String _cleanQuery(String input) {
    // 1. Remove file extensions and replace dots/underscores/hyphens with space
    String cleaned = p
        .basenameWithoutExtension(input)
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');

    // 2. Remove common release tags (case insensitive)
    final tagsToRemove = [
      'ita',
      'eng',
      'sub',
      'x264',
      'x265',
      'h264',
      'h265',
      '1080p',
      '720p',
      '480p',
      '4k',
      'uhd',
      'hdr',
      'web',
      'dl',
      'webdl',
      'bluray',
      'dvdrip',
      'ac3',
      'aac',
      'dts',
      'truehd',
      'divx',
      'xvid',
      'stagione',
      'season',
      'ep',
      'episodio',
    ];

    for (final tag in tagsToRemove) {
      cleaned = cleaned.replaceAll(
        RegExp(r'\b' + tag + r'\b', caseSensitive: false),
        '',
      );
    }

    // 3. Remove SxxExx patterns (S01E01, S01, E01)
    cleaned = cleaned
        .replaceAll(RegExp(r's\d{1,2}e\d{1,2}', caseSensitive: false), '')
        .replaceAll(RegExp(r's\d{1,2}', caseSensitive: false), '')
        .replaceAll(RegExp(r'e\d{1,2}', caseSensitive: false), '');

    // 4. Remove Years inside parens or standalone (if not part of title context, tricky but let's try removing parens)
    cleaned = cleaned.replaceAll(RegExp(r'\(\d{4}\)'), '');

    // 5. Trim extra spaces
    return cleaned.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _loadFromNfo() async {
    final nfoPath = p.setExtension(widget.video.path, '.nfo');
    final file = File(nfoPath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.nfoNotFoundMsg)),
        );
      }
      return;
    }

    final metadata = await NfoParser.parseNfo(nfoPath);
    if (!mounted) return;
    if (metadata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nfoErrorMsg)),
      );
      return;
    }

    setState(() {
      _titleController.text = metadata['title'] ?? _titleController.text;
      _yearController.text = metadata['year'] ?? _yearController.text;
      _genresController.text = metadata['genres'] ?? _genresController.text;
      _directorsController.text =
          metadata['directors'] ?? _directorsController.text;
      _actorsController.text = metadata['actors'] ?? _actorsController.text;
      _plotController.text = metadata['plot'] ?? _plotController.text;
      _durationController.text =
          metadata['duration'] ?? _durationController.text;
      _rating = metadata['rating'] ?? _rating;
      if (metadata['poster'] != null &&
          metadata['poster'].toString().isNotEmpty) {
        _posterPathController.text = metadata['poster'];
      }
      _sagaController.text = metadata['saga'] ?? '';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nfoLoadedMsg)),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _genresController.dispose();
    _directorsController.dispose();
    _actorsController.dispose();
    _plotController.dispose();
    _posterPathController.dispose();
    _durationController.dispose();
    _sagaController.dispose();
    _sagaIndexController.dispose();
    _dateAddedController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _save({bool onlyDb = false}) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final updatedVideo = Video(
        id: widget.video.id,
        path: widget.video.path,
        mtime: widget.video.mtime,
        duration: _durationController.text,

        title: _titleController.text,
        year: _yearController.text,
        genres: _genresController.text,
        directors: _directorsController.text,
        actors: _actorsController.text,
        plot: _plotController.text,
        posterPath: _posterPathController.text,
        rating: _rating,
        isSeries: widget.video.isSeries,
        saga: _sagaController.text,
        sagaIndex: int.tryParse(_sagaIndexController.text) ?? 0,
        dateAdded: _dateAdded,
      );

      // LoggerService().debug(
      //   'DEBUG: Saving video. ID=${updatedVideo.id}, Title=${updatedVideo.title}, OnlyDB=$onlyDb',
      // );

      final databaseProvider = context.read<DatabaseProvider>();
      final localizations = AppLocalizations.of(context)!;
      final settings = context.read<SettingsService>();

      await databaseProvider.updateVideo(
        updatedVideo,
        syncNfo: settings.autoSyncNfoOnEdit,
      );

      if (!mounted) return;

      if (onlyDb) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.dbUpdatedMsg)));
        Navigator.pop(context, true);
        return;
      }

      // Update File Metadata
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.fileUpdateMsg)),
        );
      }

      final response = await MetadataService().updateFileMetadata(
        updatedVideo,
        onMethodDecided: (method, reason) {
          if (mounted) {
            setState(() {
              if (method == 'Remuxing -> MKV') {
                _statusMessage = AppLocalizations.of(context)!.convertingToMkv;
              } else {
                _statusMessage = AppLocalizations.of(context)!.fileUpdateMsg;
              }
            });
          }
        },
      );
      final result = response.result;

      if (mounted) {
        if (result != MetadataUpdateResult.failed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.successUpdateMsg),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(AppLocalizations.of(context)!.errorUpdateMsg),
            ),
          );
        }
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2B2B2B),
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.editVideoTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  if (_isDownloading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Row(
                      children: [
                        if (!widget.video.isSeries) ...[
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => FileMetadataDialog(
                                  filePath: widget.video.path,
                                ),
                              );
                            },
                            icon: const Icon(Icons.data_object, size: 16),
                            label: Text(
                              AppLocalizations.of(context)!.btnFileMetadata,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        TextButton.icon(
                          onPressed: _loadFromNfo,
                          icon: const Icon(Icons.sync, size: 16),
                          label: Text(
                            AppLocalizations.of(context)!.loadFromNfo,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _downloadTmdbInfo,
                          icon: const Icon(Icons.download, size: 16),
                          label: Text(
                            AppLocalizations.of(context)!.downloadTmdb,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () async {
                            final databaseProvider = context
                                .read<DatabaseProvider>();
                            final localizations = AppLocalizations.of(context)!;
                            final success = await databaseProvider.saveToNfo(
                              widget.video,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? localizations.successUpdateMsg
                                      : localizations.errorUpdateMsg,
                                ),
                                backgroundColor: success
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.save,
                            color: Colors.greenAccent,
                          ),
                          tooltip: AppLocalizations.of(context)!.saveToNfo,
                        ),
                      ],
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.fileLabel(p.basename(widget.video.path)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.pathLabel(widget.video.path),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (_fileSizeString.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    AppLocalizations.of(context)!.sizeLabel(_fileSizeString),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
              buildEpisodesSection(
                context: context,
                isSeries: widget.video.isSeries,
                episodes: _episodes,
                isLoading: _isLoadingEpisodes,
                onLoad: _loadEpisodes,
              ),
              const SizedBox(height: 15),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: buildVideoInfoColumn(
                        context: context,
                        titleController: _titleController,
                        yearController: _yearController,
                        durationController: _durationController,
                        genresController: _genresController,
                        directorsController: _directorsController,
                        actorsController: _actorsController,
                        posterPathController: _posterPathController,
                        sagaController: _sagaController,
                        sagaIndexController: _sagaIndexController,
                        dateAddedController: _dateAddedController,
                        timeController: _timeController,
                        dateAdded: _dateAdded,
                        onDateChanged: _onDateAddedChanged,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: buildVideoRatingColumn(
                        context: context,
                        rating: _rating,
                        plotController: _plotController,
                        onRatingChanged: (value) =>
                            setState(() => _rating = value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSaving ? null : () => _save(onlyDb: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange.withValues(alpha: 0.8),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(AppLocalizations.of(context)!.updateDbOnly),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSaving ? null : () => _save(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                    child: _isSaving
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              if (_statusMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    _statusMessage!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Text(AppLocalizations.of(context)!.saveAll),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Series Episode List Methods
  List<File>? _episodes;
  bool _isLoadingEpisodes = false;

  Future<void> _loadEpisodes() async {
    if (_episodes != null) return; // Already loaded

    setState(() => _isLoadingEpisodes = true);
    final dir = Directory(widget.video.path);
    if (!await dir.exists()) {
      setState(() {
        _episodes = [];
        _isLoadingEpisodes = false;
      });
      return;
    }

    final List<File> files = [];
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (VideoExtensions.supported.contains(ext)) {
            files.add(entity);
          }
        }
      }
      files.sort(
        (a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()),
      );
    } on Exception catch (e) {
      LoggerService().debug('Error loading episodes: $e');
    }

    if (mounted) {
      setState(() {
        _episodes = files;
        _isLoadingEpisodes = false;
      });
    }
  }
}
