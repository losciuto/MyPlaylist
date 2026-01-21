import '../models/video.dart';

class FilterUtils {
  static List<Video> filterVideos(List<Video> videos, String query) {
    if (query.isEmpty) {
      return List.from(videos);
    }
    final lower = query.toLowerCase();
    return videos.where((v) => 
      v.title.toLowerCase().contains(lower) || 
      v.path.toLowerCase().contains(lower)
    ).toList();
  }

  static void sortVideos(List<Video> videos, int sortColumnIndex, bool ascending) {
    videos.sort((a, b) {
      int comparison = 0;
      switch (sortColumnIndex) {
        case 0: comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase()); break;
        case 2: comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase()); break; 
        case 5: comparison = a.year.compareTo(b.year); break;
        case 11: comparison = a.rating.compareTo(b.rating); break;
        case 4: 
          final aDur = parseDuration(a.duration);
          final bDur = parseDuration(b.duration);
          comparison = aDur.compareTo(bDur); 
          break;
        case 14: comparison = a.saga.toLowerCase().compareTo(b.saga.toLowerCase()); break;
        case 3: comparison = a.genres.toLowerCase().compareTo(b.genres.toLowerCase()); break;
        case 6: comparison = a.directors.toLowerCase().compareTo(b.directors.toLowerCase()); break;
        default: comparison = 0;
      }
      return ascending ? comparison : -comparison;
    });
  }

  static int parseDuration(String duration) {
    int totalMinutes = 0;
    final hourMatch = RegExp(r'(\d+)h').firstMatch(duration);
    final minMatch = RegExp(r'(\d+)m').firstMatch(duration);
    if (hourMatch != null) totalMinutes += int.parse(hourMatch.group(1)!) * 60;
    if (minMatch != null) totalMinutes += int.parse(minMatch.group(1)!);
    return totalMinutes;
  }
}
