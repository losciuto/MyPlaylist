import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_playlist/screens/home_screen.dart';
import 'package:my_playlist/services/settings_service.dart';
import 'package:my_playlist/providers/database_provider.dart';
import 'package:my_playlist/providers/playlist_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

// Minimal mock/fake for DatabaseProvider to avoid DB dependency in smoke test
class FakeDatabaseProvider extends ChangeNotifier implements DatabaseProvider {
  @override
  int get currentTabIndex => 0;
  
  @override
  int get currentServiceTabIndex => 0;

  @override
  void setTabIndex(int index) {}
  
  @override
  void setServiceTabIndex(int index) {}

  @override
  Future<void> refreshVideos() async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App smoke test - HomeScreen renders', (WidgetTester tester) async {
    // Setup initial state
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService();
    await settings.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settings),
          ChangeNotifierProvider<DatabaseProvider>(create: (_) => FakeDatabaseProvider()),
          ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('it'),
            Locale('en'),
          ],
          home: const HomeScreen(),
        ),
      ),
    );

    // Initial pump (HomeScreen has a _loadVideos that might delay rendering)
    await tester.pump();

    // Verify that some key element of HomeScreen is present
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
