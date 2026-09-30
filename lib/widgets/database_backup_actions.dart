import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../providers/database_provider.dart';
import '../services/database_backup_service.dart';
import 'confirm_dialog.dart';

const _successColor = Color(0xFF4CAF50);
const _warningColor = Colors.orange;
const _errorColor = Colors.red;

Future<void> exportDatabaseFlow(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final service = DatabaseBackupService();

  try {
    if (!await service.databaseFileExists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dbNotFoundMsg)));
      return;
    }

    final String? outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.selectDestinationFolder,
    );
    if (outputDir == null) return;

    final outcome = await service.exportTo(outputDir);
    if (!context.mounted) return;

    switch (outcome.status) {
      case DatabaseBackupStatus.success:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupSuccessMsg(outcome.path ?? '')),
            backgroundColor: _successColor,
          ),
        );
      case DatabaseBackupStatus.notFound:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.dbNotFoundMsg)));
      case DatabaseBackupStatus.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupErrorMsg(outcome.error ?? '')),
            backgroundColor: _errorColor,
          ),
        );
      case DatabaseBackupStatus.cancelled:
      case DatabaseBackupStatus.invalidFile:
        break;
    }
  } on Exception catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.backupErrorMsg(e.toString())),
        backgroundColor: _errorColor,
      ),
    );
  }
}

Future<void> importDatabaseFlow(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final service = DatabaseBackupService();

  try {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: l10n.selectBackupFile,
    );
    if (result == null || result.files.single.path == null) return;

    final backupPath = result.files.single.path!;

    if (!backupPath.endsWith(DatabaseBackupService.fileExtension)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invalidDbMsg),
          backgroundColor: _warningColor,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.confirmRestoreTitle,
      message: l10n.confirmRestoreMsg,
      confirmLabel: l10n.confirm,
      destructive: true,
    );
    if (!confirmed) return;

    final outcome = await service.importFrom(backupPath);
    if (!context.mounted) return;

    if (outcome.status == DatabaseBackupStatus.success) {
      await context.read<DatabaseProvider>().refreshVideos();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.dbRestoredMsg),
          backgroundColor: _successColor,
        ),
      );
    } else if (outcome.status == DatabaseBackupStatus.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.restoreErrorMsg(outcome.error ?? '')),
          backgroundColor: _errorColor,
        ),
      );
    }
  } on Exception catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.restoreErrorMsg(e.toString())),
        backgroundColor: _errorColor,
      ),
    );
  }
}
