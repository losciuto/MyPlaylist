import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:my_playlist/models/video.dart';
import 'package:my_playlist/providers/database_provider.dart';
import 'package:my_playlist/services/video_processing_service.dart';
import 'package:my_playlist/widgets/confirm_dialog.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

/// Esito di un'eliminazione di duplicato, usato dai dialog per decidere se
/// chiudersi e cosa mostrare all'utente.
class DuplicateDeleteResult {
  const DuplicateDeleteResult.deletedFromDb(this.title)
    : deletedFiles = 0,
      cancelled = false;

  const DuplicateDeleteResult.deletedWithFiles(this.title, this.deletedFiles)
    : cancelled = false;

  const DuplicateDeleteResult.cancelled()
    : title = '',
      deletedFiles = 0,
      cancelled = true;

  /// Messaggio localizzato da mostrare all'utente, vuoto se annullato.
  final String title;
  final int deletedFiles;
  final bool cancelled;
}

/// Logica di eliminazione condivisa tra il gestore dei duplicati e il dialog
/// di confronto, così le due schermate non divergono.
class DuplicateDeleteController {
  DuplicateDeleteController({VideoProcessingService? service})
    : _service = service ?? VideoProcessingService();

  final VideoProcessingService _service;

  /// Elimina la voce solo dal database.
  Future<DuplicateDeleteResult> deleteFromDb(
    BuildContext context,
    Video video,
  ) async {
    final message = AppLocalizations.of(
      context,
    )!.duplicatesRemovedFromDb(video.title);
    await context.read<DatabaseProvider>().deleteVideo(video);
    return DuplicateDeleteResult.deletedFromDb(message);
  }

  /// Chiede conferma e rimuove voce e file associati.
  Future<DuplicateDeleteResult> deleteFromDbAndDisk(
    BuildContext context,
    Video video, {
    bool includeFileName = true,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.duplicatesDeleteFromDiskTitle,
      message: includeFileName
          ? l10n.duplicatesDeleteFromDiskMsg(p.basename(video.path))
          : l10n.duplicatesDeleteFromDiskMsg2(p.basename(video.path)),
      confirmLabel: l10n.delete,
      style: ConfirmStyle.filled,
      destructive: true,
    );
    if (!confirmed) return const DuplicateDeleteResult.cancelled();
    if (!context.mounted) return const DuplicateDeleteResult.cancelled();

    // Provider e traduzioni vanno letti prima dell'attesa asincrona.
    final dbProvider = context.read<DatabaseProvider>();
    final deleted = await _service.deleteVideoWithFiles(video);
    await dbProvider.refreshVideos();

    return DuplicateDeleteResult.deletedWithFiles(
      l10n.duplicatesDeletedFiles(deleted.length.toString(), video.title),
      deleted.length,
    );
  }
}
