import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:my_playlist/widgets/confirm_dialog.dart';

Widget wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Builder(builder: (context) => child)),
);

/// Apre il dialog di conferma e restituisce l'esito quando viene chiuso.
Future<void> openTestDialog(
  WidgetTester tester, {
  ConfirmStyle style = ConfirmStyle.elevated,
  bool destructive = false,
  String? cancelLabel,
  Color? confirmColor,
}) async {
  showDialog<bool>(
    context: tester.element(find.byType(Scaffold)),
    builder: (_) => ConfirmDialog(
      title: 'Titolo',
      message: 'Messaggio',
      confirmLabel: 'Conferma',
      cancelLabel: cancelLabel,
      style: style,
      destructive: destructive,
      confirmColor: confirmColor,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('senza scelta il dialog restituisce false', (tester) async {
    bool? result;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: 'Titolo',
                message: 'Messaggio',
                confirmLabel: 'Conferma',
              );
            },
            child: const Text('apri'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    // Il pulsante di annullamento e' l'ultimo TextButton (il primo e' l'apri).
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('confermare restituisce true', (tester) async {
    bool? result;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: 'Titolo',
                message: 'Messaggio',
                confirmLabel: 'Conferma',
                destructive: true,
              );
            },
            child: const Text('apri'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('il testo mostrato è titolo, messaggio ed etichette', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SizedBox()));
    await openTestDialog(tester);

    expect(find.text('Titolo'), findsOneWidget);
    expect(find.text('Messaggio'), findsOneWidget);
    expect(find.text('Conferma'), findsOneWidget);
    // L'annullamento usa l'etichetta localizzata di default.
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets('l\'etichetta di annullamento può essere personalizzata', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SizedBox()));
    await openTestDialog(tester, cancelLabel: 'No');

    expect(find.text('No'), findsOneWidget);
  });

  testWidgets('ogni stile usa il pulsante previsto', (tester) async {
    for (final stile in ConfirmStyle.values) {
      await tester.pumpWidget(wrap(const SizedBox()));
      await openTestDialog(tester, style: stile);

      // TextButton è sempre presente: è l'azione di annullamento.
      final attesiTextButton = stile == ConfirmStyle.text ? 2 : 1;
      expect(find.byType(TextButton), findsNWidgets(attesiTextButton));

      if (stile == ConfirmStyle.elevated) {
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing);
      }
      if (stile == ConfirmStyle.filled) {
        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.byType(ElevatedButton), findsNothing);
      }

      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();
    }
  });
}
