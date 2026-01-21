import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../models/video.dart' as model;
import 'package:drift/drift.dart';
import '../utils/filter_utils.dart';

class DatabaseProvider extends ChangeNotifier {
  final AppDatabase _db;
  List<model.Video> _videos = [];
  List<model.Video> _filteredVideos = [];
  bool _isLoading = false;

  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  DatabaseProvider(this._db);

  List<model.Video> get videos => _videos;
  List<model.Video> get filteredVideos => _filteredVideos;
  bool get isLoading => _isLoading;
  int get sortColumnIndex => _sortColumnIndex;
  bool get sortAscending => _sortAscending;

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
    );
  }

  void _applyFilterAndSort() {
    _filteredVideos = List.from(_videos);
    _doSort();
  }

  void filterVideos(String query) {
    _filteredVideos = FilterUtils.filterVideos(_videos, query);
    _doSort();
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


  Future<void> updateVideo(model.Video video) async {
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
      ),
    );
    await refreshVideos();
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
