import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _playerPathController;
  late TextEditingController _defaultSizeController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    _playerPathController = TextEditingController(text: settings.playerPath);
    _defaultSizeController = TextEditingController(text: settings.defaultPlaylistSize.toString());
  }

  @override
  void dispose() {
    _playerPathController.dispose();
    _defaultSizeController.dispose();
    super.dispose();
  }

  Future<void> _pickPlayerPath() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String? path = result.files.single.path;
      if (path != null) {
        _playerPathController.text = path;
        if (mounted) {
          context.read<SettingsService>().setPlayerPath(path);
        }
      }
    }
  }

  void _updateDefaultSize(String value) {
    if (value.isNotEmpty) {
      final int? size = int.tryParse(value);
      if (size != null && size > 0) {
        context.read<SettingsService>().setDefaultPlaylistSize(size);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurazione Player',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _playerPathController,
              decoration: InputDecoration(
                labelText: 'Percorso Eseguibile Player',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _pickPlayerPath,
                ),
                filled: true,
                fillColor: const Color(0xFF3C3C3C),
              ),
              onChanged: (val) => context.read<SettingsService>().setPlayerPath(val),
            ),
            const SizedBox(height: 30),
            const Text(
              'Generazione Playlist',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _defaultSizeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Numero Video Default',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF3C3C3C),
              ),
              onChanged: _updateDefaultSize,
            ),
          ],
        ),
      ),
    );
  }
}
