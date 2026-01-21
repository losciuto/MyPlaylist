import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/filter_settings.dart';
import '../services/settings_service.dart';
import 'filter_videos_dialog.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

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
  Map<String, int> _availableSagas = {};

  // Selected state
  final List<String> _selectedGenres = [];
  final List<String> _excludedGenres = [];
  final List<String> _selectedYears = [];
  final List<String> _excludedYears = [];
  final List<String> _selectedActors = [];
  final List<String> _excludedActors = [];
  final List<String> _selectedDirectors = [];
  final List<String> _excludedDirectors = [];
  final List<String> _selectedSagas = [];
  final List<String> _excludedSagas = [];
  double _minRating = 0.0;
  final TextEditingController _limitController = TextEditingController(text: '20');
  int _currentTab = 0; // 0: Generale, 1: Generi, 2: Anni, 3: Registi, 4: Attori, 5: Saghe

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
      final sagas = await DatabaseHelper.instance.getValuesWithCounts('saga');

      // Sort alphabetically
      final sortedGenres = Map.fromEntries(genres.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
      final sortedYears = Map.fromEntries(years.entries.toList()..sort((a, b) => b.key.compareTo(a.key))); // Years desc
      final sortedActors = Map.fromEntries(actors.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
      final sortedDirectors = Map.fromEntries(directors.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
      
      // Filter sagas to show only those with more than 1 movie
      final filteredSagas = Map.fromEntries(sagas.entries.where((e) => e.value > 1).toList()..sort((a, b) => a.key.compareTo(b.key)));

      if (mounted) {
        setState(() {
          _availableGenres = sortedGenres;
          _availableYears = sortedYears;
          _availableActors = sortedActors;
          _availableDirectors = sortedDirectors;
          _availableSagas = filteredSagas;
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
          SnackBar(content: Text('${AppLocalizations.of(context)!.genericError('')} $e')),
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
      title: Text(AppLocalizations.of(context)!.filterTitle, style: const TextStyle(color: Color(0xFF4CAF50))),
      content: SizedBox(
        width: 800,
        height: 600,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sidebar
            Container(
              width: 180,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Colors.white12)),
              ),
              child: ListView(
                children: [
                   _buildSidebarItem(0, AppLocalizations.of(context)!.tabGeneral, Icons.settings),
                   _buildSidebarItem(1, AppLocalizations.of(context)!.tabGenres, Icons.category),
                   _buildSidebarItem(2, AppLocalizations.of(context)!.tabYears, Icons.calendar_today),
                   _buildSidebarItem(3, AppLocalizations.of(context)!.tabDirectors, Icons.person),
                   _buildSidebarItem(4, AppLocalizations.of(context)!.tabActors, Icons.group),
                   _buildSidebarItem(5, AppLocalizations.of(context)!.tabSagas, Icons.library_books),
                   const Divider(color: Colors.white12),
                   _buildSummary(),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Content Area
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedGenres.clear();
              _excludedGenres.clear();
              _selectedYears.clear();
              _excludedYears.clear();
              _selectedActors.clear();
              _excludedActors.clear();
              _selectedDirectors.clear();
              _excludedDirectors.clear();
              _selectedSagas.clear();
              _excludedSagas.clear();
              _minRating = 0.0;
            });
          },
          child: Text(AppLocalizations.of(context)!.resetFilters, style: const TextStyle(color: Colors.redAccent)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
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
              sagas: _selectedSagas,
              excludedSagas: _excludedSagas,
              limit: int.tryParse(_limitController.text) ?? 20,
            );
            Navigator.pop(context, settings);
          },
          child: Text(AppLocalizations.of(context)!.createPlaylist),
        ),
      ],
    );
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

  Widget _buildMultiSelect(String title, String category, Map<String, int> options, List<String> included, List<String> excluded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title (${options.length})', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
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
                  onLongPress: () => _showVideosList(title, category, key),
                  leading: SizedBox(
                    width: 24,
                    height: 24,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isIncluded) {
                            included.remove(key);
                            excluded.add(key);
                          } else if (isExcluded) {
                            excluded.remove(key);
                          } else {
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
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(Icons.list, color: Colors.white24, size: 16),
                    onPressed: () => _showVideosList(title, category, key),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(int index, String label, IconData icon) {
    final isSelected = _currentTab == index;
    return ListTile(
      selected: isSelected,
      leading: Icon(icon, color: isSelected ? const Color(0xFF4CAF50) : Colors.white70, size: 20),
      title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF4CAF50) : Colors.white70, fontSize: 14)),
      onTap: () => setState(() => _currentTab = index),
      dense: true,
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.generalSettings, style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.maxVideos, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 5),
            TextField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true, 
                fillColor: Color(0xFF3C3C3C),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
            const SizedBox(height: 30),
            Text(AppLocalizations.of(context)!.minRating, style: const TextStyle(color: Colors.white70)),
            Slider(
              value: _minRating,
              min: 0,
              max: 10,
              divisions: 20,
              label: _minRating.toString(),
              activeColor: const Color(0xFF4CAF50),
              onChanged: (val) => setState(() => _minRating = val),
            ),
            Center(child: Text(AppLocalizations.of(context)!.filterByRating(_minRating), style: const TextStyle(color: Colors.white70))),
          ],
        );
      case 1:
        return _buildMultiSelect(AppLocalizations.of(context)!.tabGenres, 'genres', _availableGenres, _selectedGenres, _excludedGenres);
      case 2:
        return _buildMultiSelect(AppLocalizations.of(context)!.tabYears, 'year', _availableYears, _selectedYears, _excludedYears);
      case 3:
        return _buildMultiSelect(AppLocalizations.of(context)!.tabDirectors, 'directors', _availableDirectors, _selectedDirectors, _excludedDirectors);
      case 4:
        return _buildMultiSelect(AppLocalizations.of(context)!.tabActors, 'actors', _availableActors, _selectedActors, _excludedActors);
      case 5:
        return _buildMultiSelect(AppLocalizations.of(context)!.tabSagas, 'saga', _availableSagas, _selectedSagas, _excludedSagas);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSummary() {
    int inclusions = _selectedGenres.length + _selectedYears.length + _selectedActors.length + _selectedDirectors.length + _selectedSagas.length;
    int exclusions = _excludedGenres.length + _excludedYears.length + _excludedActors.length + _excludedDirectors.length + _excludedSagas.length;
    
    if (inclusions == 0 && exclusions == 0) {
       return Padding(
         padding: const EdgeInsets.all(10.0),
         child: Text(AppLocalizations.of(context)!.noActiveFilters, style: const TextStyle(color: Colors.white24, fontSize: 11)),
       );
    }

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.summary, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          if (inclusions > 0) 
            Text(AppLocalizations.of(context)!.included(inclusions), style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 11)),
          if (exclusions > 0)
            Text(AppLocalizations.of(context)!.excluded(exclusions), style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
        ],
      ),
    );
  }
}
