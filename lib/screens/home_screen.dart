import 'package:flutter/material.dart';
import '../database/app_database.dart' as db;
import 'playlist_tab.dart';
import 'service_tab.dart';
import '../services/github_service.dart';
import '../widgets/update_dialog.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import '../config/app_config.dart';
import 'settings_screen.dart';
import '../widgets/recent_errors_screen.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../services/logger_service.dart';
import '../services/error_reporter_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  DatabaseProvider? _databaseProvider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVideos();

    // Listen for tab changes from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<DatabaseProvider>();
      _databaseProvider = provider;
      _tabController.index = provider.currentTabIndex;

      provider.addListener(_onProviderChange);
      _tabController.addListener(_onTabControllerChange);
    });

    // Check for updates after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkForUpdates();
    });
  }

  void _onProviderChange() {
    if (!mounted) return;
    final provider = _databaseProvider;
    if (provider == null) return;
    if (_tabController.index != provider.currentTabIndex) {
      _tabController.animateTo(provider.currentTabIndex);
    }
  }

  void _onTabControllerChange() {
    if (_tabController.indexIsChanging) return;
    final provider = _databaseProvider;
    if (!mounted || provider == null) return;
    provider.setTabIndex(_tabController.index);
  }

  @override
  void dispose() {
    _databaseProvider?.removeListener(_onProviderChange);
    _databaseProvider = null;
    _tabController.removeListener(_onTabControllerChange);
    _tabController.dispose();
    super.dispose();
  }

  void _openRecentErrors() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RecentErrorsScreen()));
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
    try {
      final count = await db.AppDatabase.instance.getVideoCount();
      if (!mounted) return;
      final provider = _databaseProvider ?? context.read<DatabaseProvider>();
      _databaseProvider = provider;
      final targetIndex = count > 0 ? 0 : 1;
      setState(() {
        _tabController.index = targetIndex;
      });
      provider.setTabIndex(targetIndex);
      if (count == 0) {
        provider.setServiceTabIndex(0);
      }
    } on Object catch (e, stackTrace) {
      errorReporter.report(
        'Lettura del database non riuscita',
        e,
        source: 'HomeScreen',
      );
      LoggerService().debug('Error loading database count: $e\n$stackTrace');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show loading while checking DB to prevent flash
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset('assets/logo.png'),
        ),
        title: Text(AppLocalizations.of(context)!.playlistCreator),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.playlist_play),
              text: AppLocalizations.of(context)!.navPlaylist,
            ),
            Tab(
              icon: const Icon(Icons.grid_view_rounded),
              text: AppLocalizations.of(context)!.navService,
            ),
          ],
          indicatorColor: AppConfig.seedColor,
          labelColor: AppConfig.seedColor,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.tab,
        ),
        actions: [
          // Errori recenti: il badge porta al pannello senza aprire i log.
          // Resta nascosto finche' non si verifica nessun errore.
          AnimatedBuilder(
            animation: errorReporter,
            builder: (context, _) {
              if (errorReporter.isEmpty) return const SizedBox.shrink();
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.error_outline),
                    tooltip: AppLocalizations.of(context)!.recentErrors,
                    onPressed: _openRecentErrors,
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${errorReporter.count}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
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
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset('assets/logo.png', height: 80),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${AppConfig.appName} App',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${AppLocalizations.of(context)!.author}: ${AppConfig.appAuthor}',
                      ),
                      Text(
                        '${AppLocalizations.of(context)!.buildDate}: ${AppConfig.appBuildDate}',
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.currentVersion(AppConfig.appVersion),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(AppLocalizations.of(context)!.ok),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: AppLocalizations.of(context)!.settingsTitle,
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
        children: const [PlaylistTab(), ServiceTab()],
      ),
    );
  }
}
