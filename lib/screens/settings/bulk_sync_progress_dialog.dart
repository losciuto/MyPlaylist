import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import '../../database/app_database.dart' as db;

import '../../services/metadata_service.dart';

class BulkSyncProgressDialog extends StatefulWidget {
  const BulkSyncProgressDialog({super.key});

  @override
  BulkSyncProgressDialogState createState() => BulkSyncProgressDialogState();
}

class BulkSyncProgressDialogState extends State<BulkSyncProgressDialog> {
  int _totalFiles = 0;
  int _currentIndex = 0;
  int _updatedCount = 0;
  int _skippedCount = 0;
  bool _isFinished = false;
  bool _isCancelled = false;
  String _currentTitle = '';
  String _currentMethod = '';
  String? _currentReason;

  @override
  void initState() {
    super.initState();
    _runSync();
  }

  String _getLocalizedReason(String reason) {
    if (reason == 'fast_engine_disabled') {
      return AppLocalizations.of(context)!.syncReasonFastDisabled;
    }
    if (reason.startsWith('unsupported_format:')) {
      final ext = reason.split(':').last;
      return AppLocalizations.of(context)!.syncReasonUnsupportedFormat(ext);
    }
    if (reason.startsWith('tool_not_found:')) {
      final tool = reason.split(':').last;
      return AppLocalizations.of(context)!.syncReasonToolNotFound(tool);
    }
    if (reason.startsWith('tool_failed:')) {
      final parts = reason.split(':');
      if (parts.length >= 3) {
        final tool = parts[1];
        String error = parts.sublist(2).join(':');
        if (error == 'timeout_too_slow') {
          error = AppLocalizations.of(context)!.syncReasonTimeout;
        }
        return '${AppLocalizations.of(context)!.syncReasonToolFailed(tool)}: $error';
      }
      final tool = parts.last;
      return AppLocalizations.of(context)!.syncReasonToolFailed(tool);
    }
    return reason;
  }

  Future<void> _runSync() async {
    final videos = await db.AppDatabase.instance.getAllVideos();
    if (!mounted) return;
    setState(() {
      _totalFiles = videos.length;
    });

    for (int i = 0; i < videos.length; i++) {
      if (!mounted || _isCancelled) break;

      setState(() {
        _currentIndex = i + 1;
        _currentTitle = videos[i].title.isNotEmpty
            ? videos[i].title
            : videos[i].path.split('/').last;
      });

      final response = await MetadataService().updateFileMetadata(
        videos[i],
        enforceFullMetadata: true,
        onMethodDecided: (method, reason) {
          if (mounted) {
            setState(() {
              _currentMethod = method;
              _currentReason = reason;
            });
          }
        },
      );

      if (_isCancelled) break;

      setState(() {
        _currentMethod = response.method;
        _currentReason = response.reason;
      });

      if (response.result == MetadataUpdateResult.updated) {
        _updatedCount++;
      } else if (response.result == MetadataUpdateResult.alreadyInSync) {
        _skippedCount++;
      }
    }

    if (!mounted) return;
    setState(() {
      _isFinished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      final String title = _isCancelled
          ? AppLocalizations.of(context)!.syncInterrupted
          : AppLocalizations.of(context)!.syncCompleted;
      return AlertDialog(
        title: Text(title),
        content: Text(
          AppLocalizations.of(context)!.syncResultMsg(
            (_isCancelled ? _currentIndex - 1 : _totalFiles).toString(),
            _updatedCount.toString(),
            _skippedCount.toString(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.closeButton),
          ),
        ],
      );
    }

    final double progress = _totalFiles > 0 ? _currentIndex / _totalFiles : 0.0;
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.batchProcessingTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(
              context,
            )!.fileXofY(_currentIndex.toString(), _totalFiles.toString()),
          ),
          const SizedBox(height: 8),
          if (_currentTitle.isNotEmpty)
            Text(
              _currentTitle,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: Colors.white70,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 16),
          Text(
            '${AppLocalizations.of(context)!.syncUpdated(_updatedCount.toString())}\n${AppLocalizations.of(context)!.syncSkipped(_skippedCount.toString())}',
            textAlign: TextAlign.center,
          ),
          if (_currentMethod.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color:
                    _currentMethod == 'Remuxing -> MKV' ||
                        _currentMethod == 'mkvpropedit' ||
                        _currentMethod == 'MP4Box'
                    ? Colors.green.withValues(alpha: 0.15)
                    : (_currentMethod == 'FFmpeg'
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _currentMethod == 'Remuxing -> MKV' ||
                          _currentMethod == 'mkvpropedit' ||
                          _currentMethod == 'MP4Box'
                      ? Colors.green.withValues(alpha: 0.5)
                      : (_currentMethod == 'FFmpeg'
                            ? Colors.orange.withValues(alpha: 0.3)
                            : Colors.blue.withValues(alpha: 0.3)),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _currentMethod == 'Remuxing -> MKV'
                        ? AppLocalizations.of(context)!.convertingToMkv
                        : AppLocalizations.of(
                            context,
                          )!.syncMethodLabel(_currentMethod),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          _currentMethod == 'Remuxing -> MKV' ||
                              _currentMethod == 'mkvpropedit' ||
                              _currentMethod == 'MP4Box'
                          ? Colors.greenAccent
                          : (_currentMethod == 'FFmpeg'
                                ? Colors.orangeAccent
                                : Colors.blueAccent),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_currentMethod == 'FFmpeg' && _currentReason != null) ...[
                    const SizedBox(height: 4),
                    SelectableText(
                      AppLocalizations.of(
                        context,
                      )!.syncReasonLabel(_getLocalizedReason(_currentReason!)),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white60,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _isCancelled = true;
            });
          },
          child: Text(
            AppLocalizations.of(context)!.stopButton,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
