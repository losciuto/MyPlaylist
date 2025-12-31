import 'dart:io';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize MediaKit for video playback
  MediaKit.ensureInitialized();

  // Initialize Settings
  final settingsService = SettingsService();
  await settingsService.init();
  
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider(create: (_) => DatabaseProvider()..refreshVideos()),
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
          title: AppConfig.appName,
          theme: AppConfig.lightTheme,
          darkTheme: AppConfig.darkTheme,
          themeMode: settings.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
