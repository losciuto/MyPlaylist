import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

/// Elenco degli episodi di una serie: si popola quando l'utente apre la
/// sezione, per non scansionare il disco a ogni apertura del dialog.
Widget buildEpisodesSection({
  required BuildContext context,
  required bool isSeries,
  required List<File>? episodes,
  required bool isLoading,
  required VoidCallback onLoad,
}) {
  if (!isSeries) return const SizedBox.shrink();

  return ExpansionTile(
    title: Text(
      AppLocalizations.of(context)!.sectionEpisodes,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    onExpansionChanged: (expanded) {
      if (expanded) onLoad();
    },
    children: [
      if (isLoading)
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        )
      else if (episodes == null || episodes.isEmpty)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            AppLocalizations.of(context)!.noEpisodesFound,
            style: const TextStyle(color: Colors.white70),
          ),
        )
      else
        SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: episodes.length,
            itemBuilder: (ctx, i) {
              return ListTile(
                dense: true,
                title: Text(
                  p.basename(episodes[i].path),
                  style: const TextStyle(color: Colors.white70),
                ),
                leading: const Icon(
                  Icons.movie,
                  size: 16,
                  color: Colors.blueGrey,
                ),
              );
            },
          ),
        ),
    ],
  );
}
