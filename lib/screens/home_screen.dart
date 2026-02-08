import 'package:flutter/material.dart';
import '../database/app_database.dart' as db;
import 'scan_tab.dart';
import 'database_tab.dart';
import 'playlist_tab.dart';
import '../services/github_service.dart';
import '../widgets/update_dialog.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import '../config/app_config.dart';
import 'settings_screen.dart';
import 'statistics_tab.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadVideos();
    
    // Listen for tab changes from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DatabaseProvider>();
      _tabController.index = provider.currentTabIndex;
      
      provider.addListener(_onProviderChange);
      _tabController.addListener(_onTabControllerChange);
    });

    // Check for updates after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  void _onProviderChange() {
    final provider = context.read<DatabaseProvider>();
    if (_tabController.index != provider.currentTabIndex) {
      _tabController.animateTo(provider.currentTabIndex);
    }
  }

  void _onTabControllerChange() {
    if (!_tabController.indexIsChanging) {
      context.read<DatabaseProvider>().setTabIndex(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerChange);
    // Note: provider listener will be handled by provider lifecycle usually, 
    // but here we joined them. Better to ignore for now or use a proper lifecycle.
    _tabController.dispose();
    super.dispose();
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
    final count = await db.AppDatabase.instance.getVideoCount();
    if (mounted) {
      setState(() {
        if (count > 0) {
          _tabController.index = 2; // Index of 'Genera Playlist'
          context.read<DatabaseProvider>().setTabIndex(2);
        } else {
          _tabController.index = 0; // Index of 'Scansione'
          context.read<DatabaseProvider>().setTabIndex(0);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.playlistCreator),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.folder_open), text: AppLocalizations.of(context)!.navScan),
            Tab(icon: const Icon(Icons.storage), text: AppLocalizations.of(context)!.navDatabase),
            Tab(icon: const Icon(Icons.playlist_play), text: AppLocalizations.of(context)!.navPlaylist),
            Tab(icon: const Icon(Icons.bar_chart), text: AppLocalizations.of(context)!.tabStatistics),
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
      body: TabBarView(
        controller: _tabController,
        children: const [
          ScanTab(),
          DatabaseTab(),
          PlaylistTab(),
          StatisticsTab(),
        ],
      ),
    );
  }
}
