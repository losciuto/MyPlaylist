import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:my_playlist/services/error_reporter_service.dart';
import 'package:my_playlist/widgets/recent_errors_screen.dart';

void main() {
  late ErrorReporterService reporter;

  setUp(() {
    reporter = ErrorReporterService();
  });

  group('ErrorReporterService', () {
    test('la cronologia parte vuota', () {
      expect(reporter.isEmpty, isTrue);
      expect(reporter.count, 0);
      expect(reporter.errors, isEmpty);
    });

    test('un errore registrato conserva titolo, messaggio e sorgente', () {
      reporter.report(
        'Caricamento fallito',
        StateError('boom'),
        source: 'Scan',
      );

      expect(reporter.count, 1);
      final error = reporter.errors.single;
      expect(error.title, 'Caricamento fallito');
      expect(error.message, contains('boom'));
      expect(error.source, 'Scan');
      expect(error.timestamp, isA<DateTime>());
    });

    test('gli errori piu\' recenti vengono per primi', () {
      reporter.report('Primo', 'a');
      reporter.report('Secondo', 'b');

      expect(reporter.errors.first.title, 'Secondo');
      expect(reporter.errors.last.title, 'Primo');
    });

    test('la cronologia e\' limitata a 50 voci', () {
      for (var i = 0; i < 60; i++) {
        reporter.report('Errore $i', 'dettaglio $i');
      }

      expect(reporter.count, ErrorReporterService.maxErrors);
      expect(reporter.errors.first.title, 'Errore 59');
      expect(reporter.errors.last.title, 'Errore 10');
    });

    test('clear svuota la cronologia', () {
      reporter.report('Errore', 'dettaglio');
      reporter.clear();

      expect(reporter.isEmpty, isTrue);
    });

    test('i listener vengono avvisati', () {
      var notify = 0;
      reporter.addListener(() => notify++);

      reporter.report('Errore', 'dettaglio');
      expect(notify, 1);

      reporter.clear();
      expect(notify, 2);

      // clear su una cronologia vuota non notifica.
      reporter.clear();
      expect(notify, 2);
    });

    test('la cronologia esposta non e\' modificabile', () {
      reporter.report('Errore', 'dettaglio');

      expect(() => reporter.errors.clear(), throwsUnsupportedError);
    });
  });

  group('RecentErrorsScreen', () {
    Widget wrap() => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RecentErrorsScreen(),
    );

    testWidgets('senza errori mostra lo stato vuoto', (tester) async {
      errorReporter.clear();
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('No error recorded in this session.'), findsOneWidget);
    });

    testWidgets('con un errore mostra titolo e messaggio', (tester) async {
      errorReporter.clear();
      errorReporter.report(
        'Scansione fallita',
        'percorso non valido',
        source: 'ScanService',
      );
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('Scansione fallita'), findsOneWidget);
      expect(find.text('percorso non valido'), findsOneWidget);
      expect(find.textContaining('ScanService'), findsOneWidget);

      errorReporter.clear();
    });

    testWidgets('il pannello delle impostazioni riusa lo stesso elenco', (
      tester,
    ) async {
      errorReporter.clear();
      errorReporter.report('Errore dal pannello', 'dettaglio pannello');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: RecentErrorsPanel()),
        ),
      );
      await tester.pump();

      expect(find.text('Errore dal pannello'), findsOneWidget);
      expect(find.text('dettaglio pannello'), findsOneWidget);

      errorReporter.clear();
    });

    testWidgets('il pulsante di pulizia svuota l\'elenco', (tester) async {
      errorReporter.clear();
      errorReporter.report('Errore', 'dettaglio');
      await tester.pumpWidget(wrap());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pump();

      expect(errorReporter.isEmpty, isTrue);
      expect(find.byIcon(Icons.delete_sweep), findsNothing);
    });
  });
}
