import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'providers/database_provider.dart';
import 'providers/playlist_provider.dart';

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
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'MyPlaylist',
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
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyPlaylist',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Green primary like the original
          brightness: Brightness.dark,
          surface: const Color(0xFF2B2B2B), // Dark background
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF2B2B2B),
        cardColor: const Color(0xFF3C3C3C),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
