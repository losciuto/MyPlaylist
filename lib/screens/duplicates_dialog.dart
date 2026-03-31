import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../models/video.dart';
import '../providers/database_provider.dart';
import '../services/settings_service.dart';
import '../services/video_processing_service.dart';
import 'duplicate_compare_dialog.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

class DuplicatesDialog extends StatefulWidget {
  const DuplicatesDialog({super.key});

  @override
  State<DuplicatesDialog> createState() => _DuplicatesDialogState();
}

class _DuplicatesDialogState extends State<DuplicatesDialog> {
  final VideoProcessingService _processingService = VideoProcessingService();
  late List<List<Video>> _duplicateGroups;
  bool _isLoading = false;
  String? _lastMessage;

  @override
  void initState() {
    super.initState();
    _duplicateGroups = context.read<DatabaseProvider>().getDuplicateGroups();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _duplicateGroups = context.read<DatabaseProvider>().getDuplicateGroups();
    });
  }

  Future<int?> _getFileSizeKb(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        return (await f.length()) ~/ 1024;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _deleteFromDb(Video video) async {
    final title = AppLocalizations.of(context)!.duplicatesRemovedFromDb(video.title);
    setState(() => _isLoading = true);
    await context.read<DatabaseProvider>().deleteVideo(video);
    _lastMessage = title;
    _refresh();
    setState(() => _isLoading = false);
  }

  Future<void> _deleteFromDbAndDisk(Video video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.duplicatesDeleteFromDiskTitle),
        content: Text(
          AppLocalizations.of(context)!.duplicatesDeleteFromDiskMsg(p.basename(video.path)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    // Extract provider before async gap
    final dbProvider = context.read<DatabaseProvider>();

    final deleted = await _processingService.deleteVideoWithFiles(video);
    await dbProvider.refreshVideos();

    if (mounted) {
      _lastMessage = AppLocalizations.of(context)!.duplicatesDeletedFiles(deleted.length.toString(), video.title);
      _refresh();
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalDuplicates = _duplicateGroups.fold<int>(
      0,
      (sum, g) => sum + g.length - 1,
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.copy, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.duplicatesManager,
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          AppLocalizations.of(context)!.duplicatesFoundInfo(_duplicateGroups.length.toString(), totalDuplicates.toString()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Status message
            if (_lastMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: theme.colorScheme.primaryContainer,
                child: Text(
                  _lastMessage!,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 12,
                  ),
                ),
              ),

            // Loading bar
            if (_isLoading) const LinearProgressIndicator(),

            // Content
            Expanded(
              child: _duplicateGroups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.green.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.duplicatesNoDuplicates,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.duplicatesAllUnique,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          // Show reset button if there are ignored groups
                          if (SettingsService()
                              .ignoredDuplicateKeys
                              .isNotEmpty) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await SettingsService()
                                    .clearIgnoredDuplicateKeys();
                                _refresh();
                              },
                               icon: const Icon(Icons.refresh, size: 16),
                              label: Text(
                                AppLocalizations.of(context)!.duplicatesRestoreIgnoredBtn(SettingsService().ignoredDuplicateKeys.length.toString()),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _duplicateGroups.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, groupIdx) {
                        final group = _duplicateGroups[groupIdx];
                        // Use first video's title for group header
                        final groupTitle = group.first.title.isNotEmpty
                            ? group.first.title
                            : '(senza titolo)';
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Group header with 'Confronta' button
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer
                                      .withValues(alpha: 0.4),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: theme.colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.duplicatesCopies(groupTitle, group.length.toString()),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onErrorContainer,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () async {
                                        final changed = await showDialog<bool>(
                                          context: context,
                                          builder: (_) =>
                                              DuplicateCompareDialog(
                                                group: group,
                                              ),
                                        );
                                        if (changed == true) _refresh();
                                      },
                                      icon: const Icon(
                                        Icons.compare_arrows,
                                        size: 14,
                                      ),
                                      label: Text(
                                        AppLocalizations.of(context)!.duplicatesCompareBtn,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            theme.colorScheme.onErrorContainer,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Video entries in the group
                              ...group.asMap().entries.map((entry) {
                                final video = entry.value;
                                return _VideoEntryRow(
                                  video: video,
                                  group: group,
                                  getFileSizeKb: _getFileSizeKb,
                                  onDeleteDb: _isLoading
                                      ? null
                                      : () => _deleteFromDb(video),
                                  onDeleteDisk: _isLoading
                                      ? null
                                      : () => _deleteFromDbAndDisk(video),
                                  onGroupChanged: _refresh,
                                  isLast: entry.key == group.length - 1,
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.duplicatesFooterInfo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Reset ignored button (shown only when ignored groups exist)
                  if (SettingsService().ignoredDuplicateKeys.isNotEmpty)
                    Tooltip(
                      message:
                          AppLocalizations.of(context)!.duplicatesResetIgnoredTooltip(SettingsService().ignoredDuplicateKeys.length.toString()),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await SettingsService().clearIgnoredDuplicateKeys();
                          _refresh();
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 14),
                        label: Text(
                          AppLocalizations.of(context)!.duplicatesResetIgnoredLabel(SettingsService().ignoredDuplicateKeys.length.toString()),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.closeButton),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single row inside a duplicate group showing path, size, and action buttons.
class _VideoEntryRow extends StatefulWidget {
  final Video video;
  final List<Video> group;
  final Future<int?> Function(String) getFileSizeKb;
  final VoidCallback? onDeleteDb;
  final VoidCallback? onDeleteDisk;
  final VoidCallback onGroupChanged;
  final bool isLast;

  const _VideoEntryRow({
    required this.video,
    required this.group,
    required this.getFileSizeKb,
    required this.onDeleteDb,
    required this.onDeleteDisk,
    required this.onGroupChanged,
    required this.isLast,
  });

  @override
  State<_VideoEntryRow> createState() => _VideoEntryRowState();
}

class _VideoEntryRowState extends State<_VideoEntryRow> {
  int? _sizeKb;
  bool _sizeLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSize();
  }

  Future<void> _loadSize() async {
    final size = await widget.getFileSizeKb(widget.video.path);
    if (mounted) {
      setState(() {
        _sizeKb = size;
        _sizeLoaded = true;
      });
    }
  }

  String _formatSize(int? kb) {
    if (kb == null) return '?';
    if (kb > 1024 * 1024) return '${(kb / 1024 / 1024).toStringAsFixed(1)} GB';
    if (kb > 1024) return '${(kb / 1024).toStringAsFixed(1)} GB';
    return '$kb MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final video = widget.video;
    final filename = p.basename(video.path);
    final dirPath = p.dirname(video.path);

    return Container(
      decoration: BoxDecoration(
        border: widget.isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
      ),
      child: InkWell(
        onTap: () async {
          final changed = await showDialog<bool>(
            context: context,
            builder: (_) => DuplicateCompareDialog(group: widget.group),
          );
          if (changed == true) widget.onGroupChanged();
        },
        borderRadius: widget.isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(8))
            : BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Icon
              Icon(
                video.isSeries ? Icons.video_library : Icons.movie,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),

              // Path info (tappable)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            filename,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 10,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                AppLocalizations.of(context)!.duplicatesDetailsLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      dirPath,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (video.duration.isNotEmpty) ...[
                          Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            video.duration,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (video.genres.isNotEmpty) ...[
                          Icon(
                            Icons.local_movies_outlined,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              video.genres,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Icon(
                          Icons.storage_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        _sizeLoaded
                            ? Text(
                                _formatSize(_sizeKb),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            : SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                        if (video.rating > 0) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            video.rating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onDeleteDb,
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: Text(
                      AppLocalizations.of(context)!.duplicatesDbOnlyBtn,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    onPressed: widget.onDeleteDisk,
                    icon: const Icon(Icons.delete_forever, size: 14),
                    label: Text(
                      AppLocalizations.of(context)!.duplicatesPlusDiskBtn,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
