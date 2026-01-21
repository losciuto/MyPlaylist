import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import '../services/github_service.dart';
import '../widgets/update_dialog.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/logger_service.dart';
import 'package:flutter/services.dart';
import '../database/app_database.dart' as db;
import '../providers/database_provider.dart';
import 'dart:io';
import '../models/player_config.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import '../config/app_config.dart';

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
  late TextEditingController _fanartApiKeyController;
  bool _obscureSecret = true;
  bool _isCheckingUpdates = false;
  int _currentTab = 0; // 0: Generale, 1: Metadati, 2: Player, 3: Remote Control, 4: Manutenzione, 5: Debug

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
    _fanartApiKeyController = TextEditingController(text: settings.fanartApiKey);
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
    _fanartApiKeyController.dispose();
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
        title: Text(AppLocalizations.of(context)!.settingsTitle),
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
                const Divider(color: Colors.white10),
                _buildSidebarItem(4, 'Manutenzione', Icons.build),
                _buildSidebarItem(5, 'Debug Log', Icons.bug_report),
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

  Future<void> _checkForUpdates() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isCheckingUpdates = true);
    
    try {
      final updateInfo = await GitHubService().checkForUpdates();
      if (!mounted) return;

      if (updateInfo != null) {
        showDialog(
          context: context,
          builder: (context) => UpdateDialog(updateInfo: updateInfo),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noUpdates)),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.updateError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdates = false);
    }
  }

  Widget _buildSidebarItem(int index, String label, IconData icon) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _currentTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Map index to localized label
    String localizedLabel;
    switch (index) {
      case 0: localizedLabel = l10n.generalTab; break;
      case 1: localizedLabel = l10n.metadataTab; break;
      case 2: localizedLabel = l10n.playerTab; break;
      case 3: localizedLabel = l10n.remoteTab; break;
      case 4: localizedLabel = l10n.maintenanceTab; break;
      case 5: localizedLabel = l10n.debugTab; break;
      default: localizedLabel = label;
    }
    
    return ListTile(
      selected: isSelected,
      leading: Icon(icon, color: isSelected ? const Color(0xFF4CAF50) : (isDark ? Colors.white70 : Colors.black87), size: 22),
      title: Text(
        localizedLabel, 
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
      case 4: return _buildManutenzioneTab();
      case 5: return _buildDebugTab();
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
    final settings = Provider.of<SettingsService>(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.generalTab),
        Text(l10n.appearanceHeader, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // Language Selector
        ListTile(
            title: Text(l10n.language),
            trailing: DropdownButton<Locale>(
              value: settings.locale,
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  settings.setLocale(newLocale);
                }
              },
              items: [
                DropdownMenuItem(
                  value: Locale('it'),
                  child: Text(l10n.langIt),
                ),
                DropdownMenuItem(
                  value: Locale('en'),
                  child: Text(l10n.langEn),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        Consumer<SettingsService>(
          builder: (context, settings, child) {
            return DropdownButtonFormField<ThemeMode>(
              decoration: InputDecoration(
                labelText: l10n.themeMode,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: fillColor,
              ),
              value: settings.themeMode,
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.systemTheme)),
                DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.lightTheme)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.darkTheme)),
              ],
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) settings.setThemeMode(newValue);
              },
            );
          },
        ),
        const SizedBox(height: 35),
        Text(l10n.playlistHeader, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _defaultSizeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.videosPerPage,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: fillColor,
            helperText: l10n.defaultPlaylistSizeHelp,
          ),
          onChanged: _updateDefaultSize,
        ),
        const SizedBox(height: 35),
        Text(
          l10n.updates,
          style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListTile(
          title: Text(l10n.checkForUpdates),
          subtitle: Text(l10n.currentVersion(AppConfig.appVersion)),
          trailing: _isCheckingUpdates 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : ElevatedButton(
                onPressed: _checkForUpdates,
                child: Text(l10n.checkButton),
              ),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildMetadatiTab() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.metadataTab),
        Text(l10n.tmdbHeader, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _tmdbApiKeyController,
          decoration: InputDecoration(
            labelText: l10n.tmdbApiKey,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: fillColor,
            helperText: l10n.tmdbApiKeyHint,
          ),
          onChanged: (val) => context.read<SettingsService>().setTmdbApiKey(val),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _fanartApiKeyController,
          decoration: InputDecoration(
            labelText: l10n.fanartApiKey,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: fillColor,
            helperText: 'Optional: For better logos and backgrounds',
          ),
          onChanged: (val) => context.read<SettingsService>().setFanartApiKey(val),
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
              Expanded(
                child: Text(
                  l10n.tmdbInfo,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 35),
        
        // Auto-Sync Section
        Text(l10n.settingsAutoSync, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Consumer<SettingsService>(
          builder: (context, settings, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(l10n.settingsAutoSync),
                  subtitle: Text(l10n.settingsAutoSyncSubtitle),
                  value: settings.autoSyncEnabled,
                  onChanged: (val) => settings.setAutoSyncEnabled(val),
                  activeColor: const Color(0xFF4CAF50),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                Text(l10n.settingsWatchedFolders, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: settings.watchedDirectories.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              l10n.settingsNoWatchedFolders,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: settings.watchedDirectories.length,
                          separatorBuilder: (ctx, i) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final dir = settings.watchedDirectories[i];
                            return ListTile(
                              title: Text(p.basename(dir), style: const TextStyle(fontSize: 14)),
                              subtitle: Text(dir, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => settings.removeWatchedDirectory(dir),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlayerTab() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.playerTab),
        Text(l10n.executableHeader, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _playerPathController,
          decoration: InputDecoration(
            labelText: l10n.playerPath,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _pickPlayerPath,
            ),
            filled: true,
            fillColor: fillColor,
          ),
          onChanged: (val) => context.read<SettingsService>().setPlayerPath(val),
        ),
        const SizedBox(height: 35),
        Text(l10n.vlcRemoteHeader, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _vlcPortController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.vlcPort,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: fillColor,
          ),
          onChanged: _updateVlcPort,
        ),
      ],
    );
  }

  Widget _buildRemoteTab() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.remoteTab),
        Text(l10n.serverStatusHeader, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Consumer<SettingsService>(
          builder: (context, settings, child) {
            return SwitchListTile(
              title: Text(l10n.serverEnabled),
              subtitle: Text(l10n.remoteControlSubtitle),
              value: settings.remoteServerEnabled,
              onChanged: (val) => settings.setRemoteServerEnabled(val),
              activeColor: const Color(0xFF4CAF50),
              contentPadding: EdgeInsets.zero,
            );
          },
        ),
        const SizedBox(height: 25),
        Text(l10n.networkHeader, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _serverInterfaceController,
                decoration: InputDecoration(
                  labelText: l10n.listenInterface,
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
                  labelText: l10n.serverPort,
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
        Text(l10n.securityHeader, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _remoteSecretController,
          decoration: InputDecoration(
            labelText: l10n.securityKey,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: fillColor,
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

  Widget _buildManutenzioneTab() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.maintenanceTab),
        Text(l10n.backupRestoreHeader, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.save_alt, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 10),
                  Text(l10n.backupDatabase, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.backupDescription,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _exportDatabase,
                icon: const Icon(Icons.download),
                label: Text(l10n.exportButton),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restore, color: Colors.orangeAccent),
                  const SizedBox(width: 10),
                  Text(l10n.restoreDatabase, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orangeAccent)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.restoreDescription,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _importDatabase,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
                icon: const Icon(Icons.upload),
                label: Text(l10n.importButton),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportDatabase() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final dbPath = await db.AppDatabase.instance.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dbNotFoundMsg)));
        return;
      }

      String? outputDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: l10n.selectDestinationFolder,
      );

      if (outputDir != null) {
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
        final newPath = p.join(outputDir, 'myplaylist_backup_$timestamp.db');
        await dbFile.copy(newPath);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.backupSuccessMsg(newPath)), 
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 4),
            )
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.backupErrorMsg(e.toString())), backgroundColor: Colors.red));
    }
  }

  Future<void> _importDatabase() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: l10n.selectBackupFile,
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final backupPath = result.files.single.path!;
        
        if (!backupPath.endsWith('.db')) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidDbMsg), backgroundColor: Colors.orange));
           return;
        }

        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.confirmRestoreTitle),
            content: Text(l10n.confirmRestoreMsg),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(AppLocalizations.of(context)!.confirm)
              ),
            ],
          ),
        );

        if (confirm == true) {
          // Close connection
          await db.AppDatabase.instance.close();
          
          final dbPath = await db.AppDatabase.instance.getDatabasePath();
          final sourceFile = File(backupPath);
          await sourceFile.copy(dbPath);
          
          // Refresh provider
          if (mounted) {
            await context.read<DatabaseProvider>().refreshVideos();
            if (mounted) {
              final l10n = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dbRestoredMsg), backgroundColor: const Color(0xFF4CAF50)));
            }
          }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.restoreErrorMsg(e.toString())), backgroundColor: Colors.red));
    }
  }
  Widget _buildDebugTab() {
     final l10n = AppLocalizations.of(context)!;
     final isDark = Theme.of(context).brightness == Brightness.dark;
     final fillColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100];

     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         _buildSectionHeader(l10n.debugTab),
         
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Text(l10n.eventLog, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
             Row(
               children: [
                 IconButton(
                   icon: const Icon(Icons.refresh),
                   onPressed: () => setState(() {}),
                   tooltip: l10n.refreshLog,
                 ),
                 IconButton(
                   icon: const Icon(Icons.copy),
                   onPressed: () async {
                      final logs = await LoggerService().getLogs();
                      await Clipboard.setData(ClipboardData(text: logs));
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.logCopied)));
                   },
                   tooltip: l10n.copyLog,
                 ),
                 IconButton(
                   icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                   onPressed: () async {
                     await LoggerService().clearLogs();
                     setState(() {});
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.logCleared)));
                   },
                   tooltip: l10n.clearLog,
                 ),
               ],
             ),
           ],
         ),
         const SizedBox(height: 10),
         
         Container(
           height: 400,
           width: double.infinity,
           padding: const EdgeInsets.all(10),
           decoration: BoxDecoration(
             color: fillColor,
             borderRadius: BorderRadius.circular(5),
             border: Border.all(color: Colors.white10),
           ),
           child: FutureBuilder<String>(
             future: LoggerService().getLogs(),
             builder: (context, snapshot) {
               if (snapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: CircularProgressIndicator());
               }
               
               if (snapshot.hasError) {
                 return Text(l10n.logError(snapshot.error.toString()), style: const TextStyle(color: Colors.red));
               }
               
               return SingleChildScrollView(
                 child: SelectableText(
                   snapshot.data ?? l10n.noLogs,
                   style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                 ),
               );
             },
           ),
         ),
         const SizedBox(height: 10),
         FutureBuilder<String?>(
            future: LoggerService().getLogFilePath(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  l10n.logFile(snapshot.data!), 
                  style: const TextStyle(color: Colors.white24, fontSize: 10)
                );
              }
              return const SizedBox.shrink();
            },
         ),
       ],
     );
  }
}
