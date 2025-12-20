import 'dart:io'; // Added for File
import 'package:flutter/material.dart';
import '../models/video.dart';
import '../database/database_helper.dart';
import '../services/metadata_service.dart';

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
  late double _rating;

  bool _isSaving = false;

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
    _rating = widget.video.rating;
    _loadFileSize();
  }

  String _fileSizeString = '';

  Future<void> _loadFileSize() async {
    try {
      final file = File(widget.video.path); // Requires import 'dart:io'
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

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _genresController.dispose();
    _directorsController.dispose();
    _actorsController.dispose();
    _plotController.dispose();
    _posterPathController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final updatedVideo = Video(
        id: widget.video.id,
        path: widget.video.path,
        mtime: widget.video.mtime,
        duration: widget.video.duration,
        
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
      print('DEBUG: Saving video. ID=${updatedVideo.id}, Title=${updatedVideo.title}');

      // Update Database
      await DatabaseHelper.instance.updateVideo(updatedVideo);

      // Update File Metadata
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aggiornamento file in corso...')));
      }

      final success = await MetadataService().updateFileMetadata(updatedVideo);
      
      if (mounted) {
        if (success) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File aggiornato con successo!')));
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text('Errore aggiornamento file (vedi log)')));
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
               const Text('Modifica Video', 
                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                if (_fileSizeString.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text('Dimensione file: $_fileSizeString', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                const SizedBox(height: 20),
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
                             _buildTextField(_yearController, 'Anno'),
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
                     onPressed: _isSaving ? null : _save,
                     child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Salva Modifiche'),
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
