import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/filter_settings.dart';
import '../services/settings_service.dart';
import 'filter_videos_dialog.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  // Available data
  Map<String, int> _availableGenres = {};
  Map<String, int> _availableYears = {};
  Map<String, int> _availableActors = {};
  Map<String, int> _availableDirectors = {};

  // Selected state
  final List<String> _selectedGenres = [];
  final List<String> _excludedGenres = [];
  final List<String> _selectedYears = [];
  final List<String> _excludedYears = [];
  final List<String> _selectedActors = [];
  final List<String> _excludedActors = [];
  final List<String> _selectedDirectors = [];
  final List<String> _excludedDirectors = [];
  double _minRating = 0.0;
  final TextEditingController _limitController = TextEditingController(text: '20');

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final defaultSize = context.read<SettingsService>().defaultPlaylistSize;
    _limitController.text = defaultSize.toString();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final genres = await DatabaseHelper.instance.getValuesWithCounts('genres');
      final years = await DatabaseHelper.instance.getValuesWithCounts('year');
      final actors = await DatabaseHelper.instance.getValuesWithCounts('actors');
      final directors = await DatabaseHelper.instance.getValuesWithCounts('directors');

      // Sort alphabetically
      final sortedGenres = Map.fromEntries(genres.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
      final sortedYears = Map.fromEntries(years.entries.toList()..sort((a, b) => b.key.compareTo(a.key))); // Years desc
      final sortedActors = Map.fromEntries(actors.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
      final sortedDirectors = Map.fromEntries(directors.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

      if (mounted) {
        setState(() {
          _availableGenres = sortedGenres;
          _availableYears = sortedYears;
          _availableActors = sortedActors;
          _availableDirectors = sortedDirectors;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading filter data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore caricamento filtri: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF2B2B2B),
      title: const Text('Filtri Avanzati Playlist', style: TextStyle(color: Color(0xFF4CAF50))),
      content: SizedBox(
        width: 600,
        height: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Numero di video:', style: TextStyle(color: Colors.white70)),
              TextField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(filled: true, fillColor: Color(0xFF3C3C3C)),
              ),
              const SizedBox(height: 20),
              
              const Text('Rating Minimo:', style: TextStyle(color: Colors.white70)),
              Slider(
                value: _minRating,
                min: 0,
                max: 10,
                divisions: 20,
                label: _minRating.toString(),
                activeColor: const Color(0xFF4CAF50),
                onChanged: (val) => setState(() => _minRating = val),
              ),
              Text('Valore: $_minRating', style: const TextStyle(color: Colors.white30)),
              const Divider(color: Colors.grey),

              _buildMultiSelect('Generi', _availableGenres, _selectedGenres, _excludedGenres),
              _buildMultiSelect('Anni', _availableYears, _selectedYears, _excludedYears),
              _buildMultiSelect('Registi', _availableDirectors, _selectedDirectors, _excludedDirectors),
              _buildMultiSelect('Attori', _availableActors, _selectedActors, _excludedActors),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () {
            final settings = FilterSettings(
              genres: _selectedGenres,
              years: _selectedYears,
              ratingMin: _minRating,
              actors: _selectedActors,
              directors: _selectedDirectors,
              excludedGenres: _excludedGenres,
              excludedYears: _excludedYears,
              excludedActors: _excludedActors,
              excludedDirectors: _excludedDirectors,
              limit: int.tryParse(_limitController.text) ?? 20,
            );
            Navigator.pop(context, settings);
          },
          child: const Text('Genera Playlist'),
        ),
      ],
    );
  }

  String _getColumnName(String title) {
    if (title.contains('Generi')) return 'genres';
    if (title.contains('Anni')) return 'year';
    if (title.contains('Registi')) return 'directors';
    if (title.contains('Attori')) return 'actors';
    return '';
  }

  void _showVideosList(String title, String category, String filterValue) {
    showDialog(
      context: context,
      builder: (ctx) => FilterVideosDialog(
        title: title,
        category: category,
        filterValue: filterValue,
      ),
    );
  }

  Widget _buildMultiSelect(String title, Map<String, int> options, List<String> included, List<String> excluded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text('$title (${options.length})', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          height: 150,
          margin: const EdgeInsets.only(right: 12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(5),
          ),
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (ctx, i) {
              final key = options.keys.elementAt(i);
              final count = options[key];
              
              final isIncluded = included.contains(key);
              final isExcluded = excluded.contains(key);

              return ListTile(
                dense: true,
                onTap: () => _showVideosList(title, _getColumnName(title), key),
                leading: SizedBox(
                  width: 24,
                  height: 24,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isIncluded) {
                          // Allow cycling to Excluded
                          included.remove(key);
                          excluded.add(key);
                        } else if (isExcluded) {
                          // Allow cycling to None
                          excluded.remove(key);
                        } else {
                          // Cycle to Included
                          included.add(key);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                        color: isIncluded 
                              ? const Color(0xFF4CAF50) 
                              : (isExcluded ? Colors.red : Colors.transparent),
                      ),
                      child: isIncluded
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : (isExcluded 
                              ? const Icon(Icons.close, size: 16, color: Colors.white) 
                              : null),
                    ),
                  ),
                ),
                title: Text('$key ($count)',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
              );
            },
          ),
        ),
      ],
    );
  }
}
