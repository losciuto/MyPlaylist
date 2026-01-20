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
  late TextEditingController _tmdbApiKeyController;
  bool _obscureSecret = true;
  int _currentTab = 0; // 0: Generale, 1: Metadati, 2: Player, 3: Remote Control

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
    _tmdbApiKeyController = TextEditingController(text: settings.tmdbApiKey);
  }

  @override
  void dispose() {
    _playerPathController.dispose();
    _defaultSizeController.dispose();
    _remotePortController.dispose();
    _remoteSecretController.dispose();
    _vlcPortController.dispose();
    _serverInterfaceController.dispose();
    _tmdbApiKeyController.dispose();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(right: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
            ),
            child: ListView(
              children: [
                _buildSidebarItem(0, 'Generale', Icons.settings),
                _buildSidebarItem(1, 'Metadati', Icons.data_usage),
                _buildSidebarItem(2, 'Player', Icons.play_circle_outline),
                _buildSidebarItem(3, 'Remote Control', Icons.settings_remote),
              ],
            ),
          ),
          // Content Area
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF242424) : Colors.white,
              padding: const EdgeInsets.all(30.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTabContent(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, String label, IconData icon) {
    final isSelected = _currentTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      selected: isSelected,
      leading: Icon(icon, color: isSelected ? const Color(0xFF4CAF50) : (isDark ? Colors.white70 : Colors.black87), size: 22),
      title: Text(
        label, 
        style: TextStyle(
          color: isSelected ? const Color(0xFF4CAF50) : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        )
      ),
      onTap: () => setState(() => _currentTab = index),
      tileColor: isSelected ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0: return _buildGeneraleTab();
      case 1: return _buildMetadatiTab();
      case 2: return _buildPlayerTab();
      case 3: return _buildRemoteTab();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
        const SizedBox(height: 5),
        const Divider(color: Color(0xFF4CAF50)),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildGeneraleTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Impostazioni Generali'),
        const Text('ASPETTO', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Consumer<SettingsService>(
          builder: (context, settings, child) {
            return DropdownButtonFormField<ThemeMode>(
              decoration: InputDecoration(
                labelText: 'Tema Applicazione',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: fillColor,
              ),
              value: settings.themeMode,
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('Sistema')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Chiaro')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Scuro')),
              ],
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) settings.setThemeMode(newValue);
              },
            );
          },
        ),
        const SizedBox(height: 35),
        const Text('PLAYLIST', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _defaultSizeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Numero Video Default',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: fillColor,
            helperText: 'Numero di video proposti di default alla creazione di una playlist',
          ),
          onChanged: _updateDefaultSize,
        ),
      ],
    );
  }

  Widget _buildMetadatiTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Metadati e API'),
        const Text('TMDB (THE MOVIE DATABASE)', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _tmdbApiKeyController,
          decoration: InputDecoration(
            labelText: 'TMDB API Key',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: fillColor,
            helperText: 'Richiesta per scaricare trame, locandine e dettagli da TMDB',
          ),
          onChanged: (val) => context.read<SettingsService>().setTmdbApiKey(val),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blueAccent),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  'Senza una API Key valida non sarà possibile utilizzare le funzioni di arricchimento metadati automatico.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Configurazione Player'),
        const Text('ESEGUIBILE', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _playerPathController,
          decoration: InputDecoration(
            labelText: 'Percorso Player Esterno',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _pickPlayerPath,
            ),
            filled: true,
            fillColor: fillColor,
            helperText: 'Percorso del programma utilizzato per riprodurre i video',
          ),
          onChanged: (val) => context.read<SettingsService>().setPlayerPath(val),
        ),
        const SizedBox(height: 35),
        const Text('CONTROLLO REMOTO VLC', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _vlcPortController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Porta HTTP VLC (Default: 4212)',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: fillColor,
            helperText: 'La porta impostata nell\'interfaccia RC di VLC',
          ),
          onChanged: _updateVlcPort,
        ),
      ],
    );
  }

  Widget _buildRemoteTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Server Controllo Remoto'),
        const Text('STATO SERVER', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Consumer<SettingsService>(
          builder: (context, settings, child) {
            return SwitchListTile(
              title: const Text('Abilita Server Remoto'),
              subtitle: const Text('Permette di controllare l\'app tramite rete locale'),
              value: settings.remoteServerEnabled,
              onChanged: (val) => settings.setRemoteServerEnabled(val),
              activeColor: const Color(0xFF4CAF50),
              contentPadding: EdgeInsets.zero,
            );
          },
        ),
        const SizedBox(height: 25),
        const Text('NETWORK', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _serverInterfaceController,
                decoration: InputDecoration(
                  labelText: 'Interfaccia (IP)',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: fillColor,
                ),
                onChanged: _updateServerInterface,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _remotePortController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Porta',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: fillColor,
                ),
                onChanged: _updateRemotePort,
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        const Text('SICUREZZA', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _remoteSecretController,
          decoration: InputDecoration(
            labelText: 'Pre-Shared Key (PSK)',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: fillColor,
            helperText: 'Chiave di cifratura per i comandi in ingresso',
            suffixIcon: IconButton(
              icon: Icon(_obscureSecret ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
            ),
          ),
          onChanged: _updateRemoteSecret,
          obscureText: _obscureSecret,
        ),
      ],
    );
  }
}
