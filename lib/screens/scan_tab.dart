import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/scan_service.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  String _statusMessage = 'Pronto per la scansione';
  int _count = 0;
  bool _isScanning = false;

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
      _statusMessage = 'Inizializzazione scansione...';
      _count = 0;
    });

    ScanService.instance.scanFolder(folder).listen(
      (status) {
        setState(() {
          _statusMessage = status.message;
          _count = status.count;
        });
      },
      onDone: () {
        setState(() {
          _isScanning = false;
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Scansione terminata! Processati $_count video.')),
           );
        }
      },
      onError: (e) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Errore: $e';
        });
      },
    );
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
            child: const Text(
              'SCANSIONE CARTELLE',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
            const SizedBox(height: 20),
            Text(
            'Scansiona le cartelle per aggiornare il database con i metadati dei video.\n'
            'Verranno cercati automaticamente i file .nfo associati.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _selectFolder,
              icon: const Icon(Icons.folder_open),
              label: Text(_isScanning ? 'Scansione in corso...' : 'Seleziona Cartella da Scansionare'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 18),
              ),
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
                const Text(
                  '📊 Informazioni Scansione',
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
                  'Video trovati: $_count',
                   style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'Estensioni supportate: .mp4, .avi, .mkv, .mov, ...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
