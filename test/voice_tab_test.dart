import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:my_playlist/providers/playlist_provider.dart';
import 'package:my_playlist/screens/voice_tab.dart';
import 'package:my_playlist/services/settings_service.dart';
import 'package:my_playlist/services/voice/voice_command_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('La scheda Comandi vocali si renderizza', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.init();

    final voice = VoiceCommandService(
      settingsService: settings,
      playlistProvider: PlaylistProvider(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settings),
          ChangeNotifierProvider<VoiceCommandService>.value(value: voice),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('it'), Locale('en')],
          locale: const Locale('it'),
          home: const Scaffold(body: VoiceTab()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(VoiceTab), findsOneWidget);
    expect(find.text('Comandi vocali'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('Il meter del microfono mostra il livello', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.init();

    final voice = VoiceCommandService(
      settingsService: settings,
      playlistProvider: PlaylistProvider(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settings),
          ChangeNotifierProvider<VoiceCommandService>.value(value: voice),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('it'), Locale('en')],
          locale: const Locale('it'),
          home: const Scaffold(body: VoiceTab()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Livello microfono'), findsOneWidget);

    voice.inputLevel.value = -18;
    await tester.pump();

    expect(find.text('-18 dB'), findsOneWidget);
  });

  testWidgets('Il bottone microfono resta attivo senza modello pronto', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.init();

    final voice = VoiceCommandService(
      settingsService: settings,
      playlistProvider: PlaylistProvider(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settings),
          ChangeNotifierProvider<VoiceCommandService>.value(value: voice),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('it'), Locale('en')],
          locale: const Locale('it'),
          home: const Scaffold(body: VoiceTab()),
        ),
      ),
    );
    await tester.pump();

    final IconButton button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.mic),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Il tap sul microfono avvia la preparazione del motore', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.init();

    final voice = VoiceCommandService(
      settingsService: settings,
      playlistProvider: PlaylistProvider(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settings),
          ChangeNotifierProvider<VoiceCommandService>.value(value: voice),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('it'), Locale('en')],
          locale: const Locale('it'),
          home: const Scaffold(body: VoiceTab()),
        ),
      ),
    );
    await tester.pump();

    expect(voice.status.name, 'idle');

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Il tap deve raggiungere il servizio: la preparazione parte anche se il
    // modello non e' ancora pronto.
    expect(voice.status.name, isNot('idle'));
  });

  testWidgets('La scheda Comandi vocali regge una finestra ridotta', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 420);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.init();

    final voice = VoiceCommandService(
      settingsService: settings,
      playlistProvider: PlaylistProvider(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settings),
          ChangeNotifierProvider<VoiceCommandService>.value(value: voice),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('it'), Locale('en')],
          locale: const Locale('it'),
          home: const Scaffold(body: VoiceTab()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(VoiceTab), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
