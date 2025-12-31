import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  // Try to find the DB in the current directory first
  String dbPath = 'videos.db';
  if (!await File(dbPath).exists()) {
    // Fallback to home dir .local/share
    final home = Platform.environment['HOME'];
    dbPath = p.join(home!, '.local/share/my_playlist/databases/videos.db');
  }

  if (!await File(dbPath).exists()) {
    print('DB not found.');
    return;
  }
  
  var db = await databaseFactory.openDatabase(dbPath);
  
  print('--- Sample Data Hunt: Animazione ---');
  final res = await db.rawQuery("SELECT id, title, genres FROM videos WHERE genres LIKE '%Animazione%' LIMIT 20");
  for (var r in res) {
    print('ID: ${r['id']} | Title: ${r['title']} | Genres: [${r['genres']}]');
  }
  
  print('\n--- Testing exclusion specifically for one of them ---');
  if (res.isNotEmpty) {
     final testId = res.first['id'];
     final testTitle = res.first['title'];
     final testGenre = 'Animazione';
     
     final check = await db.rawQuery("SELECT COUNT(*) as count FROM videos WHERE id = ? AND genres NOT LIKE ?", [testId, '%$testGenre%']);
     print('Exclusion check for "$testTitle" (ID $testId) with NOT LIKE "%$testGenre%": ${check.first['count'] == 1 ? 'PASS (Matches, so NOT excluded - WAIT THIS IS WRONG)' : 'EXCLUDED (Correct behavior)'}');
     // Wait, if it matches NOT LIKE, it means it is NOT like Animazione. 
     // If it IS Animazione, NOT LIKE should return 0.
  }

  await db.close();
}
