import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:my_playlist/models/video.dart';
import 'package:my_playlist/providers/database_provider.dart';
import 'package:my_playlist/screens/duplicates/duplicate_delete_controller.dart';
import 'package:my_playlist/widgets/confirm_dialog.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_video_repository.dart';

Widget wrap(Widget child) => MultiProvider(
  providers: [
    ChangeNotifierProvider<DatabaseProvider>(
      create: (_) => DatabaseProvider(FakeVideoRepository()),
    ),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Builder(builder: (context) => child)),
  ),
);

void main() {
  final video = Video(path: '/video/film.mkv', mtime: 0, title: 'Film');

  testWidgets('l’eliminazione dal database restituisce il messaggio', (
    tester,
  ) async {
    late DuplicateDeleteResult result;

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await DuplicateDeleteController().deleteFromDb(
                context,
                video,
              );
            },
            child: const Text('elimina'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('elimina'));
    await tester.pumpAndSettle();

    expect(result.cancelled, isFalse);
    expect(result.title, contains('Film'));
  });

  testWidgets('l’eliminazione col disco chiede conferma e si annulla', (
    tester,
  ) async {
    final completer = Completer<DuplicateDeleteResult>();

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              completer.complete(
                await DuplicateDeleteController().deleteFromDbAndDisk(
                  context,
                  video,
                ),
              );
            },
            child: const Text('elimina'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('elimina'));
    await tester.pumpAndSettle();

    // Senza conferma l'eliminazione non parte.
    expect(find.byType(ConfirmDialog), findsOneWidget);

    final cancelButton = find
        .descendant(
          of: find.byType(ConfirmDialog),
          matching: find.byType(TextButton),
        )
        .first;
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    final result = await completer.future;
    expect(result.cancelled, isTrue);
    expect(result.title, isEmpty);
  });
}
