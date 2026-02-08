import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../models/video.dart' as model;
import 'package:drift/drift.dart';
import '../utils/filter_utils.dart';
import '../services/nfo_sync_service.dart';
import '../services/settings_service.dart';

class DatabaseProvider extends ChangeNotifier {
  final AppDatabase _db;
  final NfoSyncService _syncService = NfoSyncService();
  
  List<model.Video> _videos = [];
  List<model.Video> _filteredVideos = [];
  bool _isLoading = false;

  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  String _searchQuery = '';
  int _currentTabIndex = 2; // Default to PlaylistTab (previously _initialIndex logic)

  DatabaseProvider(this._db);

  List<model.Video> get videos => _videos;
  List<model.Video> get filteredVideos => _filteredVideos;
  bool get isLoading => _isLoading;
  int get sortColumnIndex => _sortColumnIndex;
  bool get sortAscending => _sortAscending;
  String get searchQuery => _searchQuery;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  Future<void> refreshVideos() async {
    _isLoading = true;
    notifyListeners();
    
    final driftVideos = await _db.select(_db.videos).get();
    _videos = driftVideos.map((v) => _mapDriftToModel(v)).toList();
    _applyFilterAndSort();
    
    _isLoading = false;
    notifyListeners();
  }

  model.Video _mapDriftToModel(DriftVideo v) {
    return model.Video(
      id: v.id,
      path: v.path,
      mtime: v.mtime,
      title: v.title,
      genres: v.genres,
      year: v.year,
      directors: v.directors,
      plot: v.plot,
      actors: v.actors,
      duration: v.duration,
      rating: v.rating,
      isSeries: v.isSeries == 1,
      posterPath: v.posterPath,
      saga: v.saga,
      sagaIndex: v.sagaIndex,
      actorThumbs: v.actorThumbs ?? '',
      directorThumbs: v.directorThumbs ?? '',
    );
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
      final directors = v.directors.split(',').map((e) => e.trim().toLowerCase());
      final search = personName.trim().toLowerCase();
      return actors.contains(search) || directors.contains(search);
    }).toList();
    _doSort();
    _currentTabIndex = 1; // Switch to DatabaseTab
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
    await _db.update(_db.videos).replace(
      VideosCompanion(
        id: Value(video.id!),
        path: Value(video.path),
        mtime: Value(video.mtime),
        title: Value(video.title),
        genres: Value(video.genres),
        year: Value(video.year),
        directors: Value(video.directors),
        plot: Value(video.plot),
        actors: Value(video.actors),
        duration: Value(video.duration),
        rating: Value(video.rating),
        isSeries: Value(video.isSeries ? 1 : 0),
        posterPath: Value(video.posterPath),
        saga: Value(video.saga),
        sagaIndex: Value(video.sagaIndex),
        actorThumbs: Value(video.actorThumbs),
        directorThumbs: Value(video.directorThumbs),
      ),
    );

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
      await updateVideo(refreshedVideo, syncNfo: false);
    }
  }

  Future<void> clearDatabase() async {
    await _db.delete(_db.videos).go();
    await refreshVideos();
  }

  Future<void> deleteVideo(model.Video video) async {
    if (video.id != null) {
      await (_db.delete(_db.videos)..where((t) => t.id.equals(video.id!))).go();
      await refreshVideos();
    }
  }

  void setSortedVideos(List<model.Video> sortedVideos) {
    _filteredVideos = sortedVideos;
    notifyListeners();
  }
}
