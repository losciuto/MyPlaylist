import 'package:flutter/foundation.dart';
import '../repositories/video_repository.dart';
import '../models/video.dart' as model;
import '../utils/filter_utils.dart';
import '../services/nfo_sync_service.dart';
import '../services/settings_service.dart';
import 'package:path/path.dart' as p;

class DatabaseProvider extends ChangeNotifier {
  // Index for sub-tabs in 'Servizio'

  DatabaseProvider([VideoRepository? repository])
    : _repository = repository ?? videoRepository;
  final VideoRepository _repository;
  final NfoSyncService _syncService = NfoSyncService();

  List<model.Video> _videos = [];
  List<model.Video> _filteredVideos = [];
  bool _isLoading = false;
  int _failedRenamesCount = 0;

  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  String _searchQuery = '';
  int _currentTabIndex =
      0; // Default to PlaylistTab (previously _initialIndex logic)
  int _serviceTabIndex = 0;

  List<model.Video> get videos => _videos;
  List<model.Video> get filteredVideos => _filteredVideos;
  bool get isLoading => _isLoading;
  int get failedRenamesCount => _failedRenamesCount;
  int get sortColumnIndex => _sortColumnIndex;
  bool get sortAscending => _sortAscending;
  String get searchQuery => _searchQuery;
  int get currentTabIndex => _currentTabIndex;
  int get currentServiceTabIndex => _serviceTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void setServiceTabIndex(int index) {
    _serviceTabIndex = index;
    _currentTabIndex = 1; // Always switch to Servizio tab
    notifyListeners();
  }

  Future<void> refreshVideos() async {
    _isLoading = true;
    notifyListeners();

    _videos = await _repository.getAllVideos();
    _failedRenamesCount = await _repository.getFailedRenamesCount();
    _applyFilterAndSort();

    _isLoading = false;
    notifyListeners();
  }

  void _applyFilterAndSort() {
    _filteredVideos = List.from(_videos);
    _doSort();
  }

  void filterVideos(String query) {
    _searchQuery = query;
    _filteredVideos = FilterUtils.filterVideos(_videos, query);
    _doSort();
    notifyListeners();
  }

  void filterByPerson(String personName) {
    _searchQuery = personName;
    _filteredVideos = _videos.where((v) {
      final actors = v.actors.split(',').map((e) => e.trim().toLowerCase());
      final directors = v.directors
          .split(',')
          .map((e) => e.trim().toLowerCase());
      final search = personName.trim().toLowerCase();
      return actors.contains(search) || directors.contains(search);
    }).toList();
    _doSort();
    _currentTabIndex = 1; // Switch to Servizio tab
    _serviceTabIndex = 1; // Switch to Database sub-tab in Servizio
    notifyListeners();
  }

  void sort(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;
    _doSort();
    notifyListeners();
  }

  void _doSort() {
    FilterUtils.sortVideos(_filteredVideos, _sortColumnIndex, _sortAscending);
  }

  Future<void> updateVideo(model.Video video, {bool syncNfo = false}) async {
    await _repository.updateVideo(video);

    if (syncNfo) {
      await _syncService.saveNfo(video);
    }

    await refreshVideos();
  }

  /// Manually saves video metadata to NFO on disk
  Future<bool> saveToNfo(model.Video video) async {
    return await _syncService.saveNfo(video);
  }

  /// Manually refreshes video metadata from NFO on disk
  Future<void> refreshFromNfo(model.Video video) async {
    final refreshedVideo = await _syncService.refreshFromNfo(video);
    if (refreshedVideo != null) {
      await updateVideo(refreshedVideo);
    }
  }

  Future<void> clearDatabase() async {
    await _repository.clearAll();
    // Also clear watched directories and ignored duplicates to ensure a total reset
    final settings = SettingsService();
    await settings.setWatchedDirectories([]);
    await settings.clearIgnoredDuplicateKeys();
    await refreshVideos();
  }

  Future<void> deleteVideo(model.Video video) async {
    if (video.id != null) {
      await _repository.deleteVideo(video.id!);
      await refreshVideos();
    }
  }

  Future<void> syncDatesWithMtime() async {
    await _repository.syncDatesWithMtime();
    await refreshVideos();
  }

  void setSortedVideos(List<model.Video> sortedVideos) {
    _filteredVideos = sortedVideos;
    notifyListeners();
  }

  Future<void> refreshFailedRenamesCount() async {
    _failedRenamesCount = await _repository.getFailedRenamesCount();
    notifyListeners();
  }

  /// Returns groups of duplicate videos (same title + year, case-insensitive).
  /// Only groups with 2 or more entries are returned.
  /// For series, the folder name is also included in the key to avoid
  /// grouping different seasons of the same show as duplicates.
  /// Groups whose key is in SettingsService.ignoredDuplicateKeys are excluded.
  List<List<model.Video>> getDuplicateGroups() {
    final ignored = SettingsService().ignoredDuplicateKeys;
    final Map<String, List<model.Video>> groups = {};
    for (final video in _videos) {
      final String key = duplicateKey(video);
      if (key == '|' || key.startsWith('|series|') || key.isEmpty) continue;
      if (ignored.contains(key)) continue; // Skip ignored groups
      groups.putIfAbsent(key, () => []).add(video);
    }
    return groups.values.where((group) => group.length > 1).toList();
  }

  /// Returns the duplicate-group key for a given video (same logic as getDuplicateGroups).
  static String duplicateKey(model.Video video) {
    if (video.isSeries) {
      final folderName = p.basename(video.path).trim().toLowerCase();
      return '${video.title.trim().toLowerCase()}|${video.year.trim()}|series|$folderName';
    }
    return '${video.title.trim().toLowerCase()}|${video.year.trim()}';
  }
}
