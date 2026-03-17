import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/video.dart';
import '../providers/database_provider.dart';
import '../providers/playlist_provider.dart';
import '../services/settings_service.dart';
import '../services/video_processing_service.dart';
import 'package:provider/provider.dart';

/// Technical info fetched via ffprobe for a single file.
class _TechInfo {
  final int? fileSizeBytes;
  final String? containerFormat;
  final String? videoCodec;
  final String? resolution;
  final String? frameRate;
  final String? videoBitrate;
  final String? audioCodec;
  final String? audioChannels;
  final String? audioSampleRate;
  final String? duration;
  final String? overallBitrate;
  final bool fileExists;

  const _TechInfo({
    this.fileSizeBytes,
    this.containerFormat,
    this.videoCodec,
    this.resolution,
    this.frameRate,
    this.videoBitrate,
    this.audioCodec,
    this.audioChannels,
    this.audioSampleRate,
    this.duration,
    this.overallBitrate,
    this.fileExists = true,
  });

  static const _TechInfo missing = _TechInfo(fileExists: false);
}

/// Fetches technical file info via ffprobe.
Future<_TechInfo> _fetchTechInfo(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return _TechInfo.missing;
    final fileSizeBytes = await file.length();

    final result = await Process.run('ffprobe', [
      '-v',
      'quiet',
      '-print_format',
      'json',
      '-show_format',
      '-show_streams',
      path,
    ]);

    if (result.exitCode != 0) {
      return _TechInfo(fileExists: true, fileSizeBytes: fileSizeBytes);
    }

    final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
    final format = json['format'] as Map<String, dynamic>?;
    final streams = json['streams'] as List<dynamic>?;

    final videoStream =
        streams?.firstWhere(
              (s) => s['codec_type'] == 'video',
              orElse: () => null,
            )
            as Map<String, dynamic>?;
    final audioStream =
        streams?.firstWhere(
              (s) => s['codec_type'] == 'audio',
              orElse: () => null,
            )
            as Map<String, dynamic>?;

    // Parse frame rate (e.g. "24000/1001" → "23.98")
    String? fps;
    final fpsRaw = videoStream?['r_frame_rate'] as String?;
    if (fpsRaw != null && fpsRaw.contains('/')) {
      final parts = fpsRaw.split('/');
      final num = double.tryParse(parts[0]) ?? 0;
      final den = double.tryParse(parts[1]) ?? 1;
      if (den != 0) fps = (num / den).toStringAsFixed(2);
    }

    // Parse duration (seconds → HH:MM:SS)
    String? dur;
    final durSec = double.tryParse(format?['duration']?.toString() ?? '');
    if (durSec != null) {
      final h = durSec ~/ 3600;
      final m = (durSec % 3600) ~/ 60;
      final s = (durSec % 60).toStringAsFixed(0).padLeft(2, '0');
      dur = h > 0 ? '${h}h ${m}m ${s}s' : '${m}m ${s}s';
    }

    // Bitrate in Mbps
    String? bitrateStr;
    final brRaw = int.tryParse(format?['bit_rate']?.toString() ?? '');
    if (brRaw != null)
      bitrateStr = '${(brRaw / 1_000_000).toStringAsFixed(2)} Mbps';

    String? vBitrateStr;
    final vBrRaw = int.tryParse(videoStream?['bit_rate']?.toString() ?? '');
    if (vBrRaw != null)
      vBitrateStr = '${(vBrRaw / 1_000_000).toStringAsFixed(2)} Mbps';

    // Container
    final formatName = (format?['format_long_name'] as String?)
        ?.replaceAll(RegExp(r',.*'), '')
        .trim();

    return _TechInfo(
      fileSizeBytes: fileSizeBytes,
      containerFormat: formatName,
      videoCodec:
          videoStream?['codec_long_name'] as String? ??
          videoStream?['codec_name'] as String?,
      resolution: (videoStream != null)
          ? '${videoStream['width']}×${videoStream['height']}'
          : null,
      frameRate: fps != null ? '$fps fps' : null,
      videoBitrate: vBitrateStr,
      audioCodec:
          audioStream?['codec_long_name'] as String? ??
          audioStream?['codec_name'] as String?,
      audioChannels: () {
        final ch = audioStream?['channels'] as int?;
        if (ch == null) return null;
        return ch == 1
            ? 'Mono'
            : ch == 2
            ? 'Stereo'
            : '$ch canali';
      }(),
      audioSampleRate: audioStream?['sample_rate'] != null
          ? '${int.tryParse(audioStream!['sample_rate'].toString()) != null ? (int.parse(audioStream['sample_rate'].toString()) / 1000).toStringAsFixed(1) : audioStream['sample_rate']} kHz'
          : null,
      duration: dur,
      overallBitrate: bitrateStr,
      fileExists: true,
    );
  } catch (e) {
    return const _TechInfo();
  }
}

/// Dialog that shows all duplicates in a group side by side with technical
/// metadata and allows choosing which one to delete.
class DuplicateCompareDialog extends StatefulWidget {
  final List<Video> group;

  const DuplicateCompareDialog({super.key, required this.group});

  @override
  State<DuplicateCompareDialog> createState() => _DuplicateCompareDialogState();
}

class _DuplicateCompareDialogState extends State<DuplicateCompareDialog> {
  final VideoProcessingService _svc = VideoProcessingService();
  late List<Future<_TechInfo>> _futures;

  @override
  void initState() {
    super.initState();
    _futures = widget.group.map((v) => _fetchTechInfo(v.path)).toList();
  }

  Future<void> _deleteFromDb(Video video) async {
    await context.read<DatabaseProvider>().deleteVideo(video);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteFromDbAndDisk(Video video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina da disco'),
        content: Text(
          'Verranno eliminati permanently:\n• Il file video\n• NFO, poster, fanart e tutti i file associati\n\n${p.basename(video.path)}\n\nConfermi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    // Extract provider before async gap
    final dbProvider = context.read<DatabaseProvider>();

    await _svc.deleteVideoWithFiles(video);
    await dbProvider.refreshVideos();
    if (mounted) Navigator.pop(context, true);
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '?';
    if (bytes > 1_000_000_000)
      return '${(bytes / 1_000_000_000).toStringAsFixed(2)} GB';
    if (bytes > 1_000_000)
      return '${(bytes / 1_000_000).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.group.first.title;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.group.length <= 2 ? 860 : 1100,
          maxHeight: 640,
        ),
        child: Column(
          children: [
            // ── Header
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
                  Icon(Icons.compare_arrows, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confronto doppioni',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
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

            // ── Columns
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.group.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final video = entry.value;
                    return FutureBuilder<_TechInfo>(
                      future: _futures[idx],
                      builder: (context, snap) {
                        final info = snap.data;
                        final loading =
                            snap.connectionState != ConnectionState.done;
                        return _VideoColumn(
                          video: video,
                          info: info,
                          loading: loading,
                          formatSize: _formatSize,
                          onDeleteDb: () => _deleteFromDb(video),
                          onDeleteDisk: () => _deleteFromDbAndDisk(video),
                          isFirst: idx == 0,
                          theme: theme,
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Footer
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
                      'Scegli quale copia eliminare. "Solo DB" rimuove il record. "+ Disco" elimina anche tutti i file dalla cartella.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ignora button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final key = DatabaseProvider.duplicateKey(
                        widget.group.first,
                      );
                      await SettingsService().addIgnoredDuplicateKey(key);
                      if (mounted) Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.visibility_off_outlined, size: 16),
                    label: const Text('Ignora'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Chiudi'),
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

/// A single column for one video in the comparison dialog.
class _VideoColumn extends StatelessWidget {
  final Video video;
  final _TechInfo? info;
  final bool loading;
  final String Function(int?) formatSize;
  final VoidCallback onDeleteDb;
  final VoidCallback onDeleteDisk;
  final bool isFirst;
  final ThemeData theme;

  const _VideoColumn({
    required this.video,
    required this.info,
    required this.loading,
    required this.formatSize,
    required this.onDeleteDb,
    required this.onDeleteDisk,
    required this.isFirst,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : Border(left: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          // File header
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.basename(video.path),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                Text(
                  p.dirname(video.path),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Tech metadata
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- File ----
                        _section(context, '📁 FILE'),
                        _row(
                          context,
                          'Dimensione',
                          formatSize(info?.fileSizeBytes),
                          big: true,
                          accent: theme.colorScheme.primary,
                        ),
                        _row(context, 'Contenitore', info?.containerFormat),
                        if (!(info?.fileExists ?? true))
                          _row(
                            context,
                            'Stato',
                            '⚠ File non trovato',
                            accent: Colors.red,
                          ),
                        const SizedBox(height: 12),

                        // ---- Video ----
                        _section(context, '🎬 VIDEO'),
                        _row(context, 'Codec', info?.videoCodec),
                        _row(
                          context,
                          'Risoluzione',
                          info?.resolution,
                          big: true,
                          accent: theme.colorScheme.primary,
                        ),
                        _row(context, 'Frame rate', info?.frameRate),
                        _row(context, 'Bitrate video', info?.videoBitrate),
                        _row(context, 'Bitrate totale', info?.overallBitrate),
                        const SizedBox(height: 12),

                        // ---- Audio ----
                        _section(context, '🔊 AUDIO'),
                        _row(context, 'Codec', info?.audioCodec),
                        _row(context, 'Canali', info?.audioChannels),
                        _row(context, 'Sample rate', info?.audioSampleRate),
                        const SizedBox(height: 12),

                        // ---- Metadati DB ----
                        _section(context, '🗂 METADATI DB'),
                        _row(context, 'Titolo (DB)', video.title),
                        _row(context, 'Anno', video.year),
                        _row(context, 'Durata (DB)', video.duration),
                        _row(context, 'Durata (file)', info?.duration),
                        _row(context, 'Generi', video.genres),
                        _row(
                          context,
                          'Voto',
                          video.rating > 0
                              ? video.rating.toStringAsFixed(1)
                              : null,
                        ),
                        _row(
                          context,
                          'Saga',
                          video.saga.isEmpty ? null : video.saga,
                        ),
                        if (video.plot.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Trama',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            video.plot,
                            style: theme.textTheme.bodySmall,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
            ),
          ),

          // Delete + Play buttons
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              children: [
                // Play button: no longer closes dialog
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<PlaylistProvider>().playSingleVideo(video);
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Riproduci'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onDeleteDb,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Elimina solo dal DB'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onDeleteDisk,
                    icon: const Icon(Icons.delete_forever, size: 16),
                    label: const Text('Elimina DB + Disco'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String? value, {
    bool big = false,
    Color? accent,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: big
                  ? theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accent,
                    )
                  : theme.textTheme.bodySmall?.copyWith(color: accent),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
