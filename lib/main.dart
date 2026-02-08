import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'providers/database_provider.dart';
import 'providers/playlist_provider.dart';
import 'services/remote_control_service.dart';
import 'config/app_config.dart';
import 'database/app_database.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_playlist/l10n/app_localizations.dart'; // Add generated import
import 'services/logger_service.dart';
import 'services/file_watcher_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MediaKit for video playback
  MediaKit.ensureInitialized();

  // Initialize Settings
  final settingsService = SettingsService();
  await settingsService.init();

  // Initialize Logger
  final logger = LoggerService();
  await logger.init();

  // Handle Flutter Errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    logger.error('Flutter Error', details.exception, details.stack);
  };

  // Handle Platform Errors
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('Platform Error', error, stack);
    return true;
  };
  
  // Initialize Window Manager for desktop
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: AppConfig.windowSize,
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: AppConfig.appName,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize File Watcher
  final fileWatcher = FileWatcherService();
  
  // Initial sync state
  if (settingsService.autoSyncEnabled) {
    for (final dir in settingsService.watchedDirectories) {
      fileWatcher.startWatching(dir);
    }
  }

  // Listen for settings changes to update watcher
  settingsService.addListener(() async {
    if (settingsService.autoSyncEnabled) {
      if (!fileWatcher.isWatching && settingsService.watchedDirectories.isNotEmpty) {
          // Re-enable or start watching new dirs
          for (final dir in settingsService.watchedDirectories) {
             await fileWatcher.startWatching(dir);
          }
      } else {
         // Check for diffs in watched directories
         final currentWatched = fileWatcher.watchedDirectories.toSet();
         final targetWatched = settingsService.watchedDirectories.toSet();
         
         // Remove no longer watched
         for (final dir in currentWatched) {
           if (!targetWatched.contains(dir)) {
             await fileWatcher.stopWatching(dir);
           }
         }
         
         // Add newly watched
         for (final dir in targetWatched) {
           if (!currentWatched.contains(dir)) {
             await fileWatcher.startWatching(dir);
           }
         }
      }
    } else {
      if (fileWatcher.isWatching) {
        await fileWatcher.stopAll();
      }
    }
  });

  final database = AppDatabase();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: database),
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider(create: (_) => DatabaseProvider(database)..refreshVideos()),
        ChangeNotifierProvider(create: (context) => PlaylistProvider()),
        ChangeNotifierProxyProvider2<SettingsService, PlaylistProvider, RemoteControlService>(
          lazy: false,
          create: (context) => RemoteControlService(
            settingsService: context.read<SettingsService>(),
            playlistProvider: context.read<PlaylistProvider>(),
          ),
          update: (context, settings, playlist, previous) => previous!,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.unknown,
            },
          ),
          title: AppConfig.appName,
          theme: AppConfig.lightTheme,
          darkTheme: AppConfig.darkTheme,
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('it'), // Italian
            Locale('en'), // English
          ],
          home: const HomeScreen(),
        );
      },
    );
  }
}
