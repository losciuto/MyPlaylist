import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import 'database_tab.dart';
import 'scan_tab.dart';
import 'priority_tab.dart';
import 'statistics_tab.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import '../config/app_config.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../database/app_database.dart' as db;
import 'package:path/path.dart' as p;

class ServiceTab extends StatefulWidget {
  const ServiceTab({super.key});

  @override
  State<ServiceTab> createState() => _ServiceTabState();
}

class _ServiceTabState extends State<ServiceTab> with TickerProviderStateMixin {
  late TabController _innerTabController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DatabaseProvider>();
    _innerTabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: provider.currentServiceTabIndex,
    );

    _innerTabController.addListener(_onTabChange);
    provider.addListener(_onProviderChange);
  }

  void _onTabChange() {
    if (!_innerTabController.indexIsChanging) {
      context.read<DatabaseProvider>().setServiceTabIndex(
        _innerTabController.index,
      );
    }
  }

  void _onProviderChange() {
    final provider = context.read<DatabaseProvider>();
    if (_innerTabController.index != provider.currentServiceTabIndex) {
      _innerTabController.animateTo(provider.currentServiceTabIndex);
    }
  }

  @override
  void dispose() {
    _innerTabController.removeListener(_onTabChange);
    try {
      context.read<DatabaseProvider>().removeListener(_onProviderChange);
    } catch (e) {
      debugPrint('Error removing listener: $e');
    }
    _innerTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Sidebar for sub-tabs
        Container(
          width: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              right: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildSidebarItem(0, l10n.navScan, Icons.folder_open),
              _buildSidebarItem(1, l10n.navDatabase, Icons.storage),
              _buildSidebarItem(2, l10n.navPriority, Icons.priority_high),
              _buildSidebarItem(3, l10n.tabStatistics, Icons.bar_chart),
              _buildSidebarItem(4, l10n.maintenanceTab, Icons.build),
              const Spacer(),
            ],
          ),
        ),
        // Content Area
        Expanded(
          child: TabBarView(
            controller: _innerTabController,
            physics:
                const NeverScrollableScrollPhysics(), // Disable swipe between sub-tabs
            children: [
              const ScanTab(),
              const DatabaseTab(),
              const PriorityTab(),
              const StatisticsTab(),
              const MaintenanceView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(int index, String label, IconData icon) {
    final isSelected = _innerTabController.index == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      selected: isSelected,
      leading: Icon(
        icon,
        color: isSelected
            ? AppConfig.seedColor
            : (isDark ? Colors.white70 : Colors.black87),
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? AppConfig.seedColor
              : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      onTap: () {
        setState(() {
          _innerTabController.index = index;
        });
      },
      tileColor: isSelected
          ? (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05))
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    );
  }
}

class MaintenanceView extends StatelessWidget {
  const MaintenanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [MaintenanceUI()],
      ),
    );
  }
}

class MaintenanceUI extends StatefulWidget {
  const MaintenanceUI({super.key});

  @override
  State<MaintenanceUI> createState() => _MaintenanceUIState();
}

class _MaintenanceUIState extends State<MaintenanceUI> {
  Future<void> _exportDatabase() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final dbPath = await db.AppDatabase.instance.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.dbNotFoundMsg)));
        }
        return;
      }

      String? outputDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: l10n.selectDestinationFolder,
      );

      if (outputDir != null) {
        final timestamp = DateTime.now()
            .toIso8601String()
            .replaceAll(':', '-')
            .split('.')
            .first;
        final newPath = p.join(outputDir, 'myplaylist_backup_$timestamp.db');
        await dbFile.copy(newPath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.backupSuccessMsg(newPath)),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupErrorMsg(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.invalidDbMsg),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        if (!mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.confirmRestoreTitle),
            content: Text(l10n.confirmRestoreMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(AppLocalizations.of(context)!.confirm),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await db.AppDatabase.instance.close();

          final dbPath = await db.AppDatabase.instance.getDatabasePath();
          final sourceFile = File(backupPath);
          await sourceFile.copy(dbPath);

          if (mounted) {
            await context.read<DatabaseProvider>().refreshVideos();
            if (!mounted) return;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.dbRestoredMsg),
                  backgroundColor: const Color(0xFF4CAF50),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.restoreErrorMsg(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetPriorityList() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetPriorityList),
        content: Text(l10n.confirmResetPriority),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<DatabaseProvider>().syncDatesWithMtime();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.opCompleted)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.maintenanceHeader),
        Text(
          l10n.backupRestoreSectionHeader,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                  Text(
                    l10n.backupDatabase,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
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
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restore, color: Colors.orangeAccent),
                  const SizedBox(width: 10),
                  Text(
                    l10n.restoreDatabase,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orangeAccent,
                    ),
                  ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                ),
                icon: const Icon(Icons.upload),
                label: Text(l10n.importButton),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_toggle_off,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.resetPriorityList,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.resetPriorityDescription,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _resetPriorityList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent[700],
                ),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.resetPriorityList),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConfig.seedColor,
          ),
        ),
        const SizedBox(height: 5),
        const Divider(color: AppConfig.seedColor),
        const SizedBox(height: 25),
      ],
    );
  }
}
