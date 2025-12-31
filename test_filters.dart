import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  final home = Platform.environment['HOME'];
  final List<String> possiblePaths = [
    p.join(home!, '.local/share/my_playlist/databases/videos.db'),
    p.join(home, '.local/share/com.example.my_playlist/databases/videos.db'), // Possible package name
    'videos.db',
  ];
  
  String? dbPath;
  for (var path in possiblePaths) {
    if (await File(path).exists()) {
      dbPath = path;
      break;
    }
  }
  
  if (dbPath == null) {
    print('Error: Database not found in any of: $possiblePaths');
    return;
  }
  
  print('Using database at: $dbPath');
  var db = await databaseFactory.openDatabase(dbPath);
  
  print('\n--- Testing Genre Matching ---');
  final genreToTest = 'Animazione';
  
  // 1. Total count
  final totalRes = await db.rawQuery('SELECT COUNT(*) as count FROM videos');
  final total = totalRes.first['count'] as int;
  print('Total videos: $total');
  
  // 2. Count with Animazione
  final withAnimRes = await db.rawQuery("SELECT COUNT(*) as count FROM videos WHERE genres LIKE '%$genreToTest%'");
  final withAnim = withAnimRes.first['count'] as int;
  print('Videos with $genreToTest: $withAnim');
  
  // 3. Count excluding Animazione
  final withoutAnimRes = await db.rawQuery("SELECT COUNT(*) as count FROM videos WHERE IFNULL(genres, '') NOT LIKE '%$genreToTest%'");
  final withoutAnim = withoutAnimRes.first['count'] as int;
  print('Videos excluding $genreToTest: $withoutAnim');
  
  if (withAnim + withoutAnim != total) {
    print('WARNING: Counts do not add up! (Sum: ${withAnim + withoutAnim})');
  } else {
    print('Counts add up correctly (Total: $total). No logical leaks.');
  }
  
  // 4. Sample videos that should be excluded
  print('\n--- Sample videos WITH "$genreToTest" (should be excluded) ---');
  final sampleEx = await db.rawQuery("SELECT title, genres FROM videos WHERE genres LIKE '%$genreToTest%' LIMIT 5");
  for (var r in sampleEx) {
    print('  - ${r['title']} | Genres: [${r['genres']}]');
  }

  // 5. Check for case sensitivity
  final lowerGenre = genreToTest.toLowerCase();
  final lowerRes = await db.rawQuery("SELECT COUNT(*) as count FROM videos WHERE genres LIKE '%$lowerGenre%'");
  final withLower = lowerRes.first['count'] as int;
  print('\nVideos with "$lowerGenre" (case-insensitive check): $withLower');
  if (withLower != withAnim) {
     print('WARNING: Case sensitivity detected! LIKE differs between upper and lower case.');
  } else {
     print('LIKE seems case-insensitive as expected.');
  }

  // 6. Inspect problematic rows if any
  print('\n--- Verification of NOT LIKE logic ---');
  final rogueRes = await db.rawQuery("SELECT title, genres FROM videos WHERE IFNULL(genres, '') NOT LIKE '%$genreToTest%' AND genres LIKE '%$genreToTest%' LIMIT 5");
  if (rogueRes.isNotEmpty) {
    print('FOUND ROGUE VIDEOS! These movies match LIKE but NOT NOT-LIKE:');
    for (var r in rogueRes) {
       print('  - ${r['title']} | Genres: [${r['genres']}]');
    }
  } else {
    print('No rogue videos found. NOT LIKE correctly blocks movies that match LIKE.');
  }

  await db.close();
}
