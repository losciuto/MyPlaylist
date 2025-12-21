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
  late TextEditingController _remotePortController;
  late TextEditingController _remoteSecretController;
  late TextEditingController _vlcPortController;
  late TextEditingController _serverInterfaceController;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    _playerPathController = TextEditingController(text: settings.playerPath);
    _defaultSizeController = TextEditingController(text: settings.defaultPlaylistSize.toString());
    _remotePortController = TextEditingController(text: settings.remoteServerPort.toString());
    _remoteSecretController = TextEditingController(text: settings.remoteServerSecret);
    _vlcPortController = TextEditingController(text: settings.vlcPort.toString());
    _serverInterfaceController = TextEditingController(text: settings.serverInterface);
  }

  @override
  void dispose() {
    _playerPathController.dispose();
    _defaultSizeController.dispose();
    _remotePortController.dispose();
    _remoteSecretController.dispose();
    _vlcPortController.dispose();
    _serverInterfaceController.dispose();
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

  void _updateRemotePort(String value) {
    if (value.isNotEmpty) {
      final int? port = int.tryParse(value);
      if (port != null && port > 0) {
        context.read<SettingsService>().setRemoteServerPort(port);
      }
    }
  }

  void _updateRemoteSecret(String value) {
    if (value.isNotEmpty) {
      context.read<SettingsService>().setRemoteServerSecret(value);
    }
  }

  void _updateVlcPort(String value) {
    if (value.isNotEmpty) {
      final int? port = int.tryParse(value);
      if (port != null && port > 0) {
        context.read<SettingsService>().setVlcPort(port);
      }
    }
  }

  void _updateServerInterface(String value) {
    if (value.isNotEmpty) {
      context.read<SettingsService>().setServerInterface(value);
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
            const SizedBox(height: 15),
            TextField(
              controller: _vlcPortController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Porta RC VLC (Default: 4212)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF3C3C3C),
                helperText: 'Porta per il controllo remoto di VLC',
              ),
              onChanged: _updateVlcPort,
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
            const SizedBox(height: 30),
            const Text(
              'Remote Control (TCP/IP)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 10),
            Consumer<SettingsService>(
              builder: (context, settings, child) {
                return SwitchListTile(
                  title: const Text('Abilita Server Remoto'),
                  subtitle: const Text('Ricevi comandi criptati per gestire le playlist'),
                  value: settings.remoteServerEnabled,
                  onChanged: (val) => settings.setRemoteServerEnabled(val),
                  activeColor: const Color(0xFF4CAF50),
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _remotePortController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Porta Server',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF3C3C3C),
              ),
              onChanged: _updateRemotePort,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _remoteSecretController,
              decoration: InputDecoration(
                labelText: 'Chiave Segreta (PSK)',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: const Color(0xFF3C3C3C),
                helperText: 'Usa la stessa chiave sul client per criptare i comandi',
                suffixIcon: IconButton(
                  icon: Icon(_obscureSecret ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                ),
              ),
              onChanged: _updateRemoteSecret,
              obscureText: _obscureSecret,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _serverInterfaceController,
              decoration: const InputDecoration(
                labelText: 'Interfaccia di Ascolto (Default: 0.0.0.0)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF3C3C3C),
                helperText: 'Indirizzo IP su cui il server accetta connessioni',
              ),
              onChanged: _updateServerInterface,
            ),
          ],
        ),
      ),
    );
  }
}
