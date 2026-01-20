import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/video.dart';
// import '../services/metadata_service.dart'; // Unused
// import '../utils/nfo_parser.dart'; // Unused
// import 'dart:io'; // Unused
// import 'package:path/path.dart' as p; // Unused

class DatabaseProvider extends ChangeNotifier {
  List<Video> _videos = [];
  List<Video> _filteredVideos = [];
  bool _isLoading = false;

  List<Video> get videos => _videos;
  List<Video> get filteredVideos => _filteredVideos;
  bool get isLoading => _isLoading;

  Future<void> refreshVideos() async {
    _isLoading = true;
    notifyListeners();
    
    _videos = await DatabaseHelper.instance.getAllVideos();
    _filteredVideos = List.from(_videos);
    
    _isLoading = false;
    notifyListeners();
  }

  void filterVideos(String query) {
    if (query.isEmpty) {
      _filteredVideos = List.from(_videos);
    } else {
      final lower = query.toLowerCase();
      _filteredVideos = _videos.where((v) => 
        v.title.toLowerCase().contains(lower) || 
        v.path.toLowerCase().contains(lower)
      ).toList();
    }
    notifyListeners();
  }

  void setSortedVideos(List<Video> sortedVideos) {
    _filteredVideos = sortedVideos;
    notifyListeners();
  }

  Future<void> updateVideo(Video video) async {
    await DatabaseHelper.instance.updateVideo(video);
    await refreshVideos(); // Refresh to update list and sort
  }

  Future<void> clearDatabase() async {
    await DatabaseHelper.instance.clearDatabase();
    await refreshVideos();
  }

  Future<void> deleteVideo(Video video) async {
    if (video.id != null) {
      await DatabaseHelper.instance.deleteVideo(video.id!);
      await refreshVideos();
    }
  }

  // Moved bulk logic here, but exposed differently.
  // Since bulk logic needs UI feedback (progress), we might need a Stream or Callback 
  // For now, I'll keep the heavily interactive bulk loop in the UI or a separate service, 
  // OR better: Return a Stream<double> of progress.
  // Actually, for simplicity given the current structure, I will keep the bulk loop structure similar 
  // but move the CORE renaming logic here.
  
  // Actually, 'bulkRename' is a very specific operation that updates the DB line by line.
  // If we move it here, we need to handle the progress notification.
  // Let's create a method that performs the rename for a single video, 
  // and the UI loop can call it? No, that spams notifyListeners.
  
  // Let's just expose the list of videos to the UI so it can loop over them. 
  // The UI already fetches 'allVideos' using DatabaseHelper.
  // I will leave the bulk *orchestration* in the UI for now as it's heavily tied to the ProgressDialog,
  // but I will expose a method to 'reload' after it's done.
}
