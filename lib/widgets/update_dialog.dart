import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/github_service.dart';
import '../services/update_service.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.updateInfo});
  final UpdateInfo updateInfo;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  /// Esito mostrato a schermo al termine del download: un messaggio di
  /// successo, un avviso che serve un passo manuale, o un errore.
  String? _result;

  /// Vero se l'esito e' un errore: il risultato si mostra in rosso.
  bool _failed = false;

  bool get _isDirectInstallable {
    final ext = (widget.updateInfo.fileExtension ?? '').toLowerCase();
    return [
      '.appimage',
      '.deb',
      '.exe',
      '.msix',
      '.apk',
      '.tar.gz',
    ].any((e) => ext.endsWith(e));
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _result = null;
      _failed = false;
    });

    try {
      final updateService = UpdateService();
      await for (final event in updateService.downloadAndInstall(
        widget.updateInfo,
      )) {
        if (!mounted) return;
        switch (event) {
          case DownloadProgress():
            setState(() => _downloadProgress = event.value);
          case UpdateFinished():
            final fallback = AppLocalizations.of(
              context,
            )!.updateInstalledRestart;
            setState(() {
              _isDownloading = false;
              _result = event.message ?? fallback;
            });
          case UpdateNeedsManualAction():
            setState(() {
              _isDownloading = false;
              _result = event.message;
            });
        }
      }

      if (mounted && _isDownloading) {
        // Il flusso si e' chiuso senza esito: non e' normale, ma senza questo
        // la barra resterebbe in movimento per sempre.
        setState(() {
          _isDownloading = false;
          _result = AppLocalizations.of(context)!.updateCompletedFallback;
        });
      }
    } on UpdateFailure catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _result = e.message;
          _failed = true;
        });
      }
    } on ProcessException catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _result = AppLocalizations.of(context)!.updateInstallError(e.message);
        });
      }
    }
  }

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(widget.updateInfo.downloadUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/logo.png', width: 40, height: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n.updateAvailableTitle(widget.updateInfo.version),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.updateAvailableHeader,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.updateWhatsNewLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    widget.updateInfo.body.isNotEmpty
                        ? widget.updateInfo.body
                        : l10n.updateNoReleaseNotes,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_result != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _failed ? Icons.error_outline : Icons.check_circle_outline,
                    size: 18,
                    color: _failed
                        ? theme.colorScheme.error
                        : theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _result!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _failed ? theme.colorScheme.error : null,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_isDownloading) ...[
              LinearProgressIndicator(value: _downloadProgress),
              const SizedBox(height: 8),
              Text(
                l10n.updateDownloadProgress((_downloadProgress * 100).toInt()),
                style: theme.textTheme.bodySmall,
              ),
            ] else ...[
              Text(l10n.updateDownloadPrompt, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      actions: [
        TextButton(
          onPressed: _isDownloading ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n.ignoreButtonLabel.toUpperCase(),
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ),
        const SizedBox(width: 8),
        if (_isDirectInstallable && _isDownloading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (_isDirectInstallable)
          ElevatedButton.icon(
            onPressed: _startDownload,
            icon: const Icon(Icons.download, size: 20),
            label: Text(l10n.downloadButtonLabel.toUpperCase()),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _launchUrl,
            icon: const Icon(Icons.open_in_new, size: 20),
            label: Text(l10n.openGitHubLabel.toUpperCase()),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }
}
