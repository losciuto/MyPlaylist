import 'package:flutter/material.dart';
import '../database/database_helper.dart'; // Import DB Helper
import 'scan_tab.dart';
import 'database_tab.dart';
import 'playlist_tab.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _initialIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDatabase();
  }

  Future<void> _checkDatabase() async {
    final count = await DatabaseHelper.instance.getVideoCount();
    if (mounted) {
      setState(() {
        if (count > 0) {
          _initialIndex = 2; // Index of 'Genera Playlist'
        } else {
          _initialIndex = 0; // Index of 'Scansione'
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show loading while checking DB to prevent flash
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 3,
      initialIndex: _initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Creatore Playlist'),
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.folder_open), text: 'Scansione'),
              Tab(icon: Icon(Icons.storage), text: 'Gestione DB'),
              Tab(icon: Icon(Icons.playlist_play), text: 'Genera Playlist'),
            ],
            indicatorColor: Color(0xFF4CAF50),
            labelColor: Color(0xFF4CAF50),
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Informazioni'),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MyPlaylist App', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Text('Autore: Massimo'),
                        Text('Data redazione: 30/12/2025'),
                        SizedBox(height: 10),
                        Text('Versione: 2.7.1'),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            ScanTab(),
            DatabaseTab(),
            PlaylistTab(),
          ],
        ),
      ),
    );
  }
}
