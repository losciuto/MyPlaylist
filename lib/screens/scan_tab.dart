import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/scan_service.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  String _statusMessage = ''; // Will be set in initState or build
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_statusMessage.isEmpty) {
      _statusMessage = AppLocalizations.of(context)!.scanStatusReady;
    }
  }
  int _count = 0;
  bool _isScanning = false;
  StreamSubscription? _scanSubscription;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  void _selectFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      lockParentWindow: true,
    );

    if (selectedDirectory != null) {
      _startScan(selectedDirectory);
    }
  }

  void _startScan(String folder) {
    setState(() {
      _isScanning = true;
      _statusMessage = AppLocalizations.of(context)!.scanStatusInit;
      _count = 0;
    });

    _scanSubscription = ScanService.instance.scanFolder(folder).listen(
      (status) {
        if (mounted) {
          setState(() {
            _statusMessage = status.message;
            _count = status.count;
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _scanSubscription = null;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.scanFinishedMsg(_count))),
          );
          
          final settings = context.read<SettingsService>();
          if (settings.autoSyncEnabled) {
            settings.addWatchedDirectory(folder);
          }
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _scanSubscription = null;
            _statusMessage = AppLocalizations.of(context)!.genericError(e.toString());
          });
        }
      },
      cancelOnError: true,
    );
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    setState(() {
      _isScanning = false;
      _scanSubscription = null;
      _statusMessage = 'Scansione interrotta dall\'utente.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              AppLocalizations.of(context)!.scanTitle,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
            const SizedBox(height: 20),
            Text(
            AppLocalizations.of(context)!.scanDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _selectFolder,
                  icon: const Icon(Icons.folder_open),
                  label: Text(_isScanning ? AppLocalizations.of(context)!.scanInProgress : AppLocalizations.of(context)!.selectFolderToScan),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                if (_isScanning) ...[
                  const SizedBox(height: 15),
                  TextButton.icon(
                    onPressed: _stopScan,
                    icon: const Icon(Icons.stop, color: Colors.red),
                    label: const Text('Ferma Scansione', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 30),
          if (_isScanning)
             const LinearProgressIndicator(color: Color(0xFF4CAF50)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.scanStats,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(height: 15),
                Text(
                  _statusMessage,
                  style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  AppLocalizations.of(context)!.videosFoundCount(_count),
                   style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context)!.scanSupportedExt,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
