import 'package:flutter/material.dart';
import '../database/database_helper.dart'; // Import DB Helper
import 'scan_tab.dart';
import 'database_tab.dart';
import 'playlist_tab.dart';
import '../services/github_service.dart';
import '../widgets/update_dialog.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import '../config/app_config.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _initialIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    // Check for updates after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await GitHubService().checkForUpdates();
    if (updateInfo != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => UpdateDialog(updateInfo: updateInfo),
      );
    }
  }

  Future<void> _loadVideos() async {
    final count = await DatabaseHelper.instance.getVideoCount();
    if (mounted) {
      setState(() {
        if (count > 0) {
          _initialIndex = 2; // Index of 'Genera Playlist'
        } else {
          _initialIndex = 0; // Index of 'Scansione'
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show loading while checking DB to prevent flash
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 3,
      initialIndex: _initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.playlistCreator),
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.folder_open), text: AppLocalizations.of(context)!.navScan),
              Tab(icon: const Icon(Icons.storage), text: AppLocalizations.of(context)!.navDatabase),
              Tab(icon: const Icon(Icons.playlist_play), text: AppLocalizations.of(context)!.navPlaylist),
            ],
            indicatorColor: AppConfig.seedColor,
            labelColor: AppConfig.seedColor,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.infoTitle),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${AppConfig.appName} App', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text('${AppLocalizations.of(context)!.author}: ${AppConfig.appAuthor}'),
                        Text('${AppLocalizations.of(context)!.buildDate}: ${AppConfig.appBuildDate}'),
                        const SizedBox(height: 10),
                        Text(AppLocalizations.of(context)!.currentVersion(AppConfig.appVersion)),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.ok)),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            ScanTab(),
            DatabaseTab(),
            PlaylistTab(),
          ],
        ),
      ),
    );
  }
}
