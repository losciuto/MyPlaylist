import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import '../services/github_service.dart';
import '../widgets/update_dialog.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../providers/database_provider.dart';
import '../widgets/database_backup_actions.dart';
import '../widgets/confirm_dialog.dart';
import 'settings/common.dart';
import 'settings/general_tab.dart';
import 'settings/metadata_tab.dart';
import 'settings/player_tab.dart';
import 'settings/remote_tab.dart';
import 'settings/maintenance_tab.dart';
import 'settings/debug_tab.dart';
import 'settings/bulk_sync_progress_dialog.dart';

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
  late TextEditingController _videoBackupPathController;
  bool _obscureSecret = true;
  bool _isCheckingUpdates = false;
  int _currentTab =
      0; // 0: Generale, 1: Metadati, 2: Player, 3: Remote Control, 4: Manutenzione, 5: Debug

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    _playerPathController = TextEditingController(text: settings.playerPath);
    _defaultSizeController = TextEditingController(
      text: settings.defaultPlaylistSize.toString(),
    );
    _remotePortController = TextEditingController(
      text: settings.remoteServerPort.toString(),
    );
    _remoteSecretController = TextEditingController(
      text: settings.remoteServerSecret,
    );
    _vlcPortController = TextEditingController(
      text: settings.vlcPort.toString(),
    );
    _serverInterfaceController = TextEditingController(
      text: settings.serverInterface,
    );
    _tmdbApiKeyController = TextEditingController(text: settings.tmdbApiKey);
    _fanartApiKeyController = TextEditingController(
      text: settings.fanartApiKey,
    );
    _videoBackupPathController = TextEditingController(
      text: settings.videoBackupPath,
    );
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
    _videoBackupPathController.dispose();
    super.dispose();
  }

  Future<void> _pickPlayerPath() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final String? path = result.files.single.path;
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

  void _refreshCurrentTab() => setState(() {});

  void _toggleSecretVisibility() =>
      setState(() => _obscureSecret = !_obscureSecret);

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

  Future<void> _pickVideoBackupPath() async {
    final String? result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      _videoBackupPathController.text = result;
      if (mounted) {
        context.read<SettingsService>().setVideoBackupPath(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              border: Border(
                right: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
            ),
            child: ListView(
              children: [
                _sidebarItem(0, Icons.settings),
                _sidebarItem(1, Icons.data_usage),
                _sidebarItem(2, Icons.play_circle_outline),
                _sidebarItem(3, Icons.settings_remote),
                const Divider(color: Colors.white10),
                _sidebarItem(4, Icons.build),
                _sidebarItem(5, Icons.bug_report),
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
                  children: [_buildTabContent()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon) {
    return buildSettingsSidebarItem(
      context: context,
      index: index,
      currentTab: _currentTab,
      fallbackLabel: '',
      icon: icon,
      onTap: () => setState(() => _currentTab = index),
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
    } on Exception catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.updateError(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdates = false);
    }
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return buildGeneralTab(
          context: context,
          defaultSizeController: _defaultSizeController,
          isCheckingUpdates: _isCheckingUpdates,
          onDefaultSizeChanged: _updateDefaultSize,
          onCheckForUpdates: _checkForUpdates,
        );
      case 1:
        return buildMetadataTab(
          context: context,
          tmdbApiKeyController: _tmdbApiKeyController,
          fanartApiKeyController: _fanartApiKeyController,
          videoBackupPathController: _videoBackupPathController,
          onPickVideoBackupPath: _pickVideoBackupPath,
          onStartBulkMetadataSync: _startBulkMetadataSync,
        );
      case 2:
        return buildPlayerTab(
          context: context,
          playerPathController: _playerPathController,
          vlcPortController: _vlcPortController,
          onPickPlayerPath: _pickPlayerPath,
          onVlcPortChanged: _updateVlcPort,
        );
      case 3:
        return buildRemoteTab(
          context: context,
          remotePortController: _remotePortController,
          remoteSecretController: _remoteSecretController,
          serverInterfaceController: _serverInterfaceController,
          obscureSecret: _obscureSecret,
          onRemotePortChanged: _updateRemotePort,
          onRemoteSecretChanged: _updateRemoteSecret,
          onServerInterfaceChanged: _updateServerInterface,
          onToggleSecretVisibility: _toggleSecretVisibility,
        );
      case 4:
        return buildMaintenanceTab(
          context: context,
          onExportDatabase: _exportDatabase,
          onImportDatabase: _importDatabase,
          onResetPriorityList: _resetPriorityList,
          onStartBulkMetadataSync: _startBulkMetadataSync,
        );
      case 5:
        return buildDebugTab(context: context, onRefresh: _refreshCurrentTab);
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _exportDatabase() => exportDatabaseFlow(context);

  Future<void> _importDatabase() => importDatabaseFlow(context);

  Future<void> _resetPriorityList() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.resetPriorityList,
      message: l10n.confirmResetPriority,
      confirmLabel: l10n.confirm,
      confirmColor: Colors.blueAccent,
    );

    if (confirmed && mounted) {
      await context.read<DatabaseProvider>().syncDatesWithMtime();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.opCompleted)));
      }
    }
  }

  Future<void> _startBulkMetadataSync() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.bulkSyncTitle,
      message: l10n.bulkSyncDesc,
      confirmLabel: l10n.startSyncDialogButton,
    );

    if (!confirmed || !mounted) return;

    // Show persistent progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return const BulkSyncProgressDialog();
      },
    );
  }
}
