import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:my_playlist/services/corrupted_files_service.dart';

class CorruptedFilesScreen extends StatefulWidget {
  const CorruptedFilesScreen({super.key});

  @override
  State<CorruptedFilesScreen> createState() => _CorruptedFilesScreenState();
}

class _CorruptedFilesScreenState extends State<CorruptedFilesScreen> {
  final CorruptedFilesService _service = CorruptedFilesService();
  bool _isLoading = true;
  bool _isVerifyingAll = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    await _service.initialize();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _verifyFile(CorruptedFileEntry entry) async {
    if (entry.status == CorruptedFileStatus.verifiedOk ||
        entry.status == CorruptedFileStatus.verifiedCorrupted) {
      return;
    }
    setState(() {});
    await _service.verifyFile(entry);
    if (mounted) setState(() {});
  }

  Future<void> _verifyAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.corruptedFilesVerifyAllTitle),
        content: Text(l10n.corruptedFilesVerifyAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.corruptedFilesVerifyAll),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isVerifyingAll = true);
    await _service.verifyAllUnverified();
    if (mounted) setState(() => _isVerifyingAll = false);
  }

  Future<void> _removeFromDb(CorruptedFileEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.corruptedFilesConfirmRemoveDb),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.corruptedFilesRemoveDb),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _service.removeFromDatabase(entry);
    if (mounted) setState(() {});
  }

  Future<void> _moveToQuarantine(CorruptedFileEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.corruptedFilesConfirmQuarantine),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(l10n.corruptedFilesQuarantine),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _service.moveToQuarantine(entry);
    if (mounted) setState(() {});
  }

  Future<void> _retryMetadata(CorruptedFileEntry entry) async {
    await _service.markForRetry(entry);
    if (mounted) setState(() {});
  }

  Future<void> _deleteEntry(CorruptedFileEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.corruptedFilesConfirmClearAll),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.corruptedFilesRemoveDb),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _service.removeEntry(entry);
    if (mounted) setState(() {});
  }

  Future<void> _clearVerifiedOk() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.corruptedFilesClearVerified),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.corruptedFilesClearVerified),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _service.clearVerifiedOk();
    if (mounted) setState(() {});
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.corruptedFilesClearAll),
        content: Text(l10n.corruptedFilesConfirmClearAll),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.corruptedFilesClearAll),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _service.clearAll();
    if (mounted) setState(() {});
  }

  String _getStatusText(AppLocalizations l10n, CorruptedFileStatus status) {
    switch (status) {
      case CorruptedFileStatus.detected:
        return l10n.corruptedFilesStatusDetected;
      case CorruptedFileStatus.verifiedCorrupted:
        return l10n.corruptedFilesStatusVerifiedCorrupted;
      case CorruptedFileStatus.verifiedOk:
        return l10n.corruptedFilesStatusVerifiedOk;
      case CorruptedFileStatus.removedFromDb:
        return l10n.corruptedFilesStatusRemovedFromDb;
      case CorruptedFileStatus.movedToQuarantine:
        return l10n.corruptedFilesStatusQuarantined;
      case CorruptedFileStatus.retryPending:
        return l10n.corruptedFilesStatusRetryPending;
    }
  }

  Color _getStatusColor(CorruptedFileStatus status) {
    switch (status) {
      case CorruptedFileStatus.detected:
        return Colors.orange;
      case CorruptedFileStatus.verifiedCorrupted:
        return Colors.red;
      case CorruptedFileStatus.verifiedOk:
        return Colors.green;
      case CorruptedFileStatus.removedFromDb:
        return Colors.grey;
      case CorruptedFileStatus.movedToQuarantine:
        return Colors.blue;
      case CorruptedFileStatus.retryPending:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = _service.entries;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.corruptedFilesTitle),
        actions: [
          if (entries.isNotEmpty) ...[
            IconButton(
              tooltip: l10n.corruptedFilesVerifyAll,
              icon: _isVerifyingAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified),
              onPressed: _isVerifyingAll ? null : _verifyAll,
            ),
            IconButton(
              tooltip: l10n.corruptedFilesClearVerified,
              icon: const Icon(Icons.cleaning_services),
              onPressed: _clearVerifiedOk,
            ),
            IconButton(
              tooltip: l10n.corruptedFilesClearAll,
              icon: const Icon(Icons.delete_forever),
              onPressed: _clearAll,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        l10n.corruptedFilesEmpty,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final statusColor = _getStatusColor(entry.status);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.2),
                        child: Icon(
                          entry.status == CorruptedFileStatus.verifiedOk
                              ? Icons.check_circle
                              : entry.status == CorruptedFileStatus.verifiedCorrupted
                                  ? Icons.error
                                  : Icons.warning,
                          color: statusColor,
                        ),
                      ),
                      title: Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$l10n.corruptedFilesDetectedAt: ${entry.detectedAt.toLocal().toString().split('.')[0]}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            entry.path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          if (entry.errorDetails != null)
                            Text(
                              '$l10n.corruptedFilesErrorDetails: ${entry.errorDetails}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.red),
                            ),
                          if (entry.verificationResult != null)
                            Text(
                              '$l10n.corruptedFilesVerificationResult: ${entry.verificationResult}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: statusColor),
                            ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getStatusText(l10n, entry.status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              if (entry.lastVerifiedAt != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Ultima verifica: ${entry.lastVerifiedAt!.toLocal().toString().split('.')[0]}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          if (entry.status != CorruptedFileStatus.verifiedOk &&
                              entry.status != CorruptedFileStatus.verifiedCorrupted)
                            IconButton(
                              tooltip: l10n.corruptedFilesVerify,
                              icon: const Icon(Icons.verified, color: Colors.blue),
                              onPressed: () => _verifyFile(entry),
                            ),
                          if (entry.videoId != null &&
                              entry.status != CorruptedFileStatus.removedFromDb)
                            IconButton(
                              tooltip: l10n.corruptedFilesRemoveDb,
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeFromDb(entry),
                            ),
                          if (entry.status != CorruptedFileStatus.movedToQuarantine)
                            IconButton(
                              tooltip: l10n.corruptedFilesQuarantine,
                              icon: const Icon(Icons.archive, color: Colors.orange),
                              onPressed: () => _moveToQuarantine(entry),
                            ),
                          if (entry.status == CorruptedFileStatus.verifiedCorrupted ||
                              entry.status == CorruptedFileStatus.retryPending)
                            IconButton(
                              tooltip: l10n.corruptedFilesRetry,
                              icon: const Icon(Icons.refresh, color: Colors.purple),
                              onPressed: () => _retryMetadata(entry),
                            ),
                          IconButton(
                            tooltip: l10n.corruptedFilesDelete,
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                            onPressed: () => _deleteEntry(entry),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}