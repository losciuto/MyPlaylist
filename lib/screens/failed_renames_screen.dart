import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import '../database/app_database.dart';
import 'package:path/path.dart' as p;

class FailedRenamesScreen extends StatefulWidget {
  const FailedRenamesScreen({super.key});

  @override
  State<FailedRenamesScreen> createState() => _FailedRenamesScreenState();
}

class _FailedRenamesScreenState extends State<FailedRenamesScreen> {
  List<FailedRename> _failedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final items = await AppDatabase.instance.getAllFailedRenames();
    setState(() {
      _failedItems = items;
      _isLoading = false;
    });
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pulisci Lista'),
        content: const Text('Vuoi rimuovere tutti i file ignorati? L\'app proverà di nuovo a rinominarli alla prossima esecuzione.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AppDatabase.instance.clearFailedRenames();
      _loadData();
    }
  }

  Future<void> _deleteItem(FailedRename item) async {
    await AppDatabase.instance.deleteFailedRename(item.id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('File Ignorati/Falliti (${_failedItems.length})'),
        actions: [
          if (_failedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Pulisci Tutto',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _failedItems.isEmpty
              ? Center(
                  child: Text(
                    'Nessun file fallito o ignorato.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: _failedItems.length,
                  itemBuilder: (context, index) {
                    final item = _failedItems[index];
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteItem(item),
                      child: ListTile(
                        leading: const Icon(Icons.error_outline, color: Colors.redAccent),
                        title: Text(p.basename(item.path)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                            Text(
                              item.path,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _deleteItem(item),
                          tooltip: 'Rimuovi dalla lista e ritenta',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
