import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../database/database_helper.dart';
import '../services/metadata_service.dart';
import '../services/settings_service.dart';
import '../services/tmdb_service.dart';
import '../utils/nfo_parser.dart';
import '../utils/nfo_generator.dart';
import '../widgets/movie_selection_dialog.dart';
import 'package:path/path.dart' as p;

class EditVideoDialog extends StatefulWidget {
  final Video video;

  const EditVideoDialog({super.key, required this.video});

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
  late double _rating;

  bool _isSaving = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.video.title);
    _yearController = TextEditingController(text: widget.video.year);
    _genresController = TextEditingController(text: widget.video.genres);
    _directorsController = TextEditingController(text: widget.video.directors);
    _actorsController = TextEditingController(text: widget.video.actors);
    _plotController = TextEditingController(text: widget.video.plot);
    _posterPathController = TextEditingController(text: widget.video.posterPath);
    _durationController = TextEditingController(text: widget.video.duration);
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
           _fileSizeString = '${(len / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error getting file size: $e');
    }
  }

  Future<void> _downloadTmdbInfo() async {
    final apiKey = context.read<SettingsService>().tmdbApiKey;
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key TMDB mancante!')));
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final service = TmdbService(apiKey);
      
      // Use current controller text for search if available, else basename
      String query = _titleController.text.trim();
      if (query.isEmpty) {
         query = p.basenameWithoutExtension(widget.video.path).replaceAll('.', ' ').replaceAll(RegExp(r'\(\d{4}\)'), '');
      }
      
      int? year = int.tryParse(_yearController.text);
      if (year == null) {
         final yearMatch = RegExp(r'\((\d{4})\)').firstMatch(query);
         if (yearMatch != null) year = int.tryParse(yearMatch.group(1)!);
      }

      final results = await service.searchMovie(query, year: year);

      if (results.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nessun risultato trovato su TMDB.')));
        setState(() => _isDownloading = false);
        return;
      }

      // Always Interactive in single edit mode
      if (!mounted) return;
      final selectedMovie = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => MovieSelectionDialog(
          title: 'Seleziona Film',
          results: results,
          isBulkMode: false,
        ),
      );

      if (selectedMovie == null) {
         setState(() => _isDownloading = false);
         return;
      }

      final details = await service.getMovieDetails(selectedMovie['id']);
      final nfoContent = NfoGenerator.generateMovieNfo(details);

      // 1. Write NFO
      final videoFile = File(widget.video.path);
      final nfoPath = p.setExtension(videoFile.path, '.nfo');
      await File(nfoPath).writeAsString(nfoContent);

      // 2. Download Poster
      String localPosterPath = _posterPathController.text;
      if (details['poster_path'] != null) {
        final posterUrl = 'https://image.tmdb.org/t/p/original${details['poster_path']}';
        final newPosterPath = '${p.dirname(videoFile.path)}/${p.basenameWithoutExtension(videoFile.path)}-poster.jpg';
        final response = await http.get(Uri.parse(posterUrl));
        if (response.statusCode == 200) {
          await File(newPosterPath).writeAsBytes(response.bodyBytes);
          localPosterPath = newPosterPath;
        }
      }

      // 3. Download Fanart (Backdrop)
      final baseDir = p.dirname(videoFile.path);
      final baseFileName = p.basenameWithoutExtension(videoFile.path);
      
      if (details['backdrop_path'] != null) {
        final fanartUrl = 'https://image.tmdb.org/t/p/original${details['backdrop_path']}';
        final fanartPath = '$baseDir/$baseFileName-fanart.jpg';
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
          final logoPath = '$baseDir/$baseFileName-clearlogo.png';
          final resp = await http.get(Uri.parse(logoUrl));
          if (resp.statusCode == 200) {
            await File(logoPath).writeAsBytes(resp.bodyBytes);
          }
        }
      }

      // 5. Update UI
      setState(() {
         _titleController.text = details['title'] ?? _titleController.text;
         final releaseDate = details['release_date']?.toString().split('-').first;
         if (releaseDate != null) {
            _yearController.text = releaseDate;
            // Also update Title to follow "Title (Year)" if needed? No, user might prefer manual.
            // But for consistency with bulk, we can suggest it.
            // Let's just update the year field.
         }
         
         if (details['genres'] != null) {
            final gList = (details['genres'] as List).map((g) => g['name']).join(', ');
            _genresController.text = gList;
         }
         
         if (details['overview'] != null) _plotController.text = details['overview'];
         if (details['runtime'] != null) _durationController.text = details['runtime'].toString();
         if (details['vote_average'] != null) _rating = (details['vote_average'] as num).toDouble();
         
         _posterPathController.text = localPosterPath;
         
         if (details['credits'] != null) {
            final cast = (details['credits']['cast'] as List?)?.take(5).map((c) => c['name']).join(', ');
            if (cast != null) _actorsController.text = cast;
            
            final crew = (details['credits']['crew'] as List?)?.where((c) => c['job'] == 'Director').map((c) => c['name']).join(', ');
            if (crew != null) _directorsController.text = crew;
         }
         
         _isDownloading = false;
      });
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dati aggiornati da TMDB (NFO e asset creati)')));

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _loadFromNfo() async {
    final nfoPath = p.setExtension(widget.video.path, '.nfo');
    final file = File(nfoPath);
    if (!await file.exists()) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File .nfo non trovato.')));
       return;
    }
    
    final metadata = await NfoParser.parseNfo(nfoPath);
    if (metadata == null) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore nel parsing del file .nfo.')));
       return;
    }
    
    setState(() {
       _titleController.text = metadata['title'] ?? _titleController.text;
       _yearController.text = metadata['year'] ?? _yearController.text;
       _genresController.text = metadata['genres'] ?? _genresController.text;
       _directorsController.text = metadata['directors'] ?? _directorsController.text;
       _actorsController.text = metadata['actors'] ?? _actorsController.text;
       _plotController.text = metadata['plot'] ?? _plotController.text;
       _durationController.text = metadata['duration'] ?? _durationController.text;
       _rating = metadata['rating'] ?? _rating;
       if (metadata['poster'] != null && metadata['poster'].toString().isNotEmpty) {
          _posterPathController.text = metadata['poster'];
       }
    });
    
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dati caricati dal file .nfo!')));
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
      );

      // ignore: avoid_print
      print('DEBUG: Saving video. ID=${updatedVideo.id}, Title=${updatedVideo.title}, OnlyDB=$onlyDb');

      // Update Database
      await DatabaseHelper.instance.updateVideo(updatedVideo);

      if (onlyDb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database aggiornato (senza toccare il file video)')));
          Navigator.pop(context, true);
        }
        return;
      }

      // Update File Metadata
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aggiornamento file in corso...')));
      }

      final success = await MetadataService().updateFileMetadata(updatedVideo);
      
      if (mounted) {
        if (success) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File e Database aggiornati con successo!')));
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text('Errore aggiornamento file (Database comunque aggiornato)')));
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
                   const Text('Modifica Video', 
                     style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                    if (_isDownloading)
                       const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                       Row(
                         children: [
                           TextButton.icon(
                             onPressed: _loadFromNfo,
                             icon: const Icon(Icons.sync, size: 16),
                             label: const Text('Carica da NFO'),
                             style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
                           ),
                           const SizedBox(width: 10),
                           ElevatedButton.icon(
                             onPressed: _downloadTmdbInfo,
                             icon: const Icon(Icons.download, size: 16),
                             label: const Text('Scarica TMDB'),
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
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
                        'File: ${p.basename(widget.video.path)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Percorso: ${widget.video.path}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (_fileSizeString.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text('Dimensione: $_fileSizeString', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ),
                const SizedBox(height: 15),
               Expanded(
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Left Column
                     Expanded(
                       child: SingleChildScrollView(
                         child: Column(
                           children: [
                             _buildTextField(_titleController, 'Titolo', true),
                             const SizedBox(height: 10),
                             Row(
                               children: [
                                 Expanded(child: _buildTextField(_yearController, 'Anno')),
                                 const SizedBox(width: 10),
                                 Expanded(child: _buildTextField(_durationController, 'Durata (min)')),
                               ],
                             ),
                             const SizedBox(height: 10),
                             _buildTextField(_genresController, 'Generi (separati da virgola)'),
                             const SizedBox(height: 10),
                             _buildTextField(_directorsController, 'Registi'),
                             const SizedBox(height: 10),
                             _buildTextField(_actorsController, 'Attori (separati da virgola)'),
                             const SizedBox(height: 10),
                             _buildTextField(_posterPathController, 'Path Poster'),
                           ],
                         ),
                       ),
                     ),
                     const SizedBox(width: 20),
                     // Right Column
                     Expanded(
                       child: Column(
                         children: [
                            const Text('Rating', style: TextStyle(color: Colors.white70)),
                            Slider(
                              value: _rating,
                              min: 0,
                              max: 10,
                              divisions: 20,
                              label: _rating.toString(),
                              activeColor: const Color(0xFF4CAF50),
                              onChanged: (val) => setState(() => _rating = val),
                            ),
                            Text('Voto: $_rating', style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 20),
                            Expanded(
                              child: _buildTextField(_plotController, 'Trama', false, 10),
                            ),
                         ],
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
                      child: const Text('Annulla'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSaving ? null : () => _save(onlyDb: true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange.withOpacity(0.8)),
                      child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Aggiorna solo DB'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSaving ? null : () => _save(onlyDb: false),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                      child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Salva tutto (File + DB)'),
                    ),
                 ],
               ),
             ],
           ),
         ),
       ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, [bool required = false, int maxLines = 1]) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: required ? (val) => val == null || val.isEmpty ? 'Campo obbligatorio' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF4CAF50))),
        filled: true,
        fillColor: const Color(0xFF3C3C3C),
      ),
    );
  }
}
