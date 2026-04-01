import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../services/metadata_service.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

class FileMetadataDialog extends StatefulWidget {
  final String filePath;

  const FileMetadataDialog({super.key, required this.filePath});

  @override
  State<FileMetadataDialog> createState() => _FileMetadataDialogState();
}

class _FileMetadataDialogState extends State<FileMetadataDialog> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _toolUsed = '';

  // Mappa chiave -> controller per ogni riga
  final List<_TagEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tags = await MetadataService().getRawFileMetadata(widget.filePath);
      if (!mounted) return;
      setState(() {
        _entries.clear();
        tags.forEach((k, v) {
          _entries.add(_TagEntry(key: k, initialValue: v));
        });
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final Map<String, String> tags = {};
    for (final entry in _entries) {
      final key = entry.keyController.text.trim();
      final value = entry.valueController.text;
      if (key.isNotEmpty) {
        tags[key] = value;
      }
    }

    final response = await MetadataService().saveFileMetadata(
      widget.filePath,
      tags,
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
      _toolUsed = response.method;
    });

    final l10n = AppLocalizations.of(context)!;
    if (response.result == MetadataUpdateResult.updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.successUpdateMsg} [${response.method}]'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorUpdateMsg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addTag() {
    setState(() {
      _entries.add(_TagEntry(key: '', initialValue: ''));
    });
  }

  void _removeTag(int index) {
    setState(() {
      _entries[index].dispose();
      _entries.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ext = p.extension(widget.filePath).toLowerCase();
    String engineLabel;
    Color engineColor;
    if (ext == '.mkv') {
      engineLabel = 'mkvpropedit';
      engineColor = Colors.tealAccent;
    } else if (ext == '.mp4' || ext == '.m4v') {
      engineLabel = 'MP4Box';
      engineColor = Colors.lightBlueAccent;
    } else {
      engineLabel = 'FFmpeg';
      engineColor = Colors.orangeAccent;
    }

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 720,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.data_object,
                    color: Color(0xFF4CAF50),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.fileMetadataTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          p.basename(widget.filePath),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Engine badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: engineColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: engineColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      engineLabel,
                      style: TextStyle(
                        color: engineColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                    iconSize: 20,
                    tooltip: l10n.closeButton,
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _loading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF4CAF50)),
                          SizedBox(height: 16),
                          Text(
                            'Lettura metadati...',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : _entries.isEmpty
                  ? Center(
                      child: Text(
                        'Nessun tag trovato nel file.',
                        style: TextStyle(color: Colors.white38),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              // KEY
                              SizedBox(
                                width: 160,
                                child: TextField(
                                  controller: entry.keyController,
                                  style: const TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF2A2A2A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3A3A3A),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3A3A3A),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                ':',
                                style: TextStyle(color: Colors.white38),
                              ),
                              const SizedBox(width: 8),
                              // VALUE
                              Expanded(
                                child: TextField(
                                  controller: entry.valueController,
                                  maxLines: null,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF252525),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3A3A3A),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3A3A3A),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // DELETE
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                color: Colors.redAccent.withValues(alpha: 0.7),
                                onPressed: () => _removeTag(index),
                                tooltip: 'Rimuovi tag',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _loading || _saving ? null : _addTag,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l10n.addTag),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _loading || _saving ? null : _loadMetadata,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Ricarica'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                  const Spacer(),
                  if (_toolUsed.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        'Ultimo: $_toolUsed',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _loading || _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_alt, size: 16),
                    label: Text(l10n.saveToFile),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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

class _TagEntry {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _TagEntry({required String key, required String initialValue})
    : keyController = TextEditingController(text: key),
      valueController = TextEditingController(text: initialValue);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
