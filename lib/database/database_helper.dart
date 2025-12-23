import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/video.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('videos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT UNIQUE,
        mtime REAL,
        title TEXT,
        genres TEXT,
        year TEXT,
        directors TEXT,
        plot TEXT,
        actors TEXT,
        duration TEXT,
        rating REAL,
        posterPath TEXT
      )
    ''');
  }

  Future<void> insertVideo(Video video) async {
    final db = await instance.database;
    // ignore: avoid_print
    print('DEBUG [DatabaseHelper]: Inserting/Replacing video: ${video.title}, Rating: ${video.rating}');
    await db.insert(
      'videos',
      video.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertVideoUnique(Video video) async {
    final db = await instance.database;
    await db.insert(
      'videos',
      video.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> updateVideo(Video video) async {
    final db = await instance.database;
    final result = await db.update(
      'videos',
      video.toMap(),
      where: 'id = ?',
      whereArgs: [video.id],
    );
    // ignore: avoid_print
    print('DEBUG: Updated video id=${video.id}. Rows affected: $result');
    return result;
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    await db.delete('videos');
  }

  Future<int> getVideoCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM videos');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Video>> getAllVideos() async {
    final db = await instance.database;
    final result = await db.query('videos', orderBy: 'title ASC');
    return result.map((json) => Video.fromMap(json)).toList();
  }

  Future<List<Video>> getRandomPlaylist(int limit, {List<int>? excludeIds}) async {
    final db = await instance.database;
    String query = 'SELECT * FROM videos';
    List<dynamic> args = [];

    if (excludeIds != null && excludeIds.isNotEmpty) {
      final placeholders = List.filled(excludeIds.length, '?').join(',');
      query += ' WHERE id NOT IN ($placeholders)';
      args.addAll(excludeIds);
    }

    query += ' ORDER BY RANDOM() LIMIT ?';
    args.add(limit);

    final result = await db.rawQuery(query, args);
    return result.map((json) => Video.fromMap(json)).toList();
  }

  Future<List<Video>> getRecentPlaylist(int limit) async {
    final db = await instance.database;
    final result = await db.query('videos', orderBy: 'mtime DESC', limit: limit);
    return result.map((json) => Video.fromMap(json)).toList();
  }

  // --- Filter Helpers ---

  Future<Map<String, int>> getValuesWithCounts(String column) async {
    final db = await instance.database;
    // Fetch all values
    // ignore: avoid_print
    print('DEBUG: Fetching values with counts for column: $column');
    final result = await db.rawQuery("SELECT $column FROM videos WHERE $column IS NOT NULL AND $column != ''");
    // ignore: avoid_print
    print('DEBUG: Raw result for $column: ${result.length} rows');
    
    final Map<String, int> counts = {};
    for (var row in result) {
      final val = row[column] as String;
      // Split by comma if it's a list (genres, actors, directors)
      if (val.contains(',')) {
        val.split(',').forEach((v) {
          final trimmed = v.trim();
          if (trimmed.isNotEmpty) {
             counts[trimmed] = (counts[trimmed] ?? 0) + 1;
          }
        });
      } else {
        final trimmed = val.trim();
        if (trimmed.isNotEmpty) {
           counts[trimmed] = (counts[trimmed] ?? 0) + 1;
        }
      }
    }
    
    // Sort logic handled by caller or we can return a sorted LinkedHashMap if needed.
    // For now returning unsorted map.
    // ignore: avoid_print
    print('DEBUG: Parsed unique values with counts for $column: ${counts.length} items');
    return counts;
  }

  Future<List<Video>> getFilteredPlaylist(
      {List<String>? genres,
      List<String>? years,
      double? minRating,
      List<String>? actors,
      List<String>? directors,
      int limit = 20,
      List<int>? excludeIds}) async {
        
    final db = await instance.database;
    String query = "SELECT * FROM videos WHERE 1=1";
    List<dynamic> args = [];

    if (genres != null && genres.isNotEmpty) {
      final conditions = genres.map((_) => "genres LIKE ?").join(' OR ');
      query += " AND ($conditions)";
      args.addAll(genres.map((g) => '%$g%'));
    }

    if (years != null && years.isNotEmpty) {
      final conditions = years.map((_) => "year LIKE ?").join(' OR '); // Use LIKE for safety or =
      query += " AND ($conditions)";
      args.addAll(years);
    }

    if (minRating != null && minRating > 0) {
      query += " AND rating >= ?";
      args.add(minRating);
    }

    if (actors != null && actors.isNotEmpty) {
      final conditions = actors.map((_) => "actors LIKE ?").join(' OR ');
      query += " AND ($conditions)";
      args.addAll(actors.map((a) => '%$a%'));
    }

    if (directors != null && directors.isNotEmpty) {
      final conditions = directors.map((_) => "directors LIKE ?").join(' OR ');
      query += " AND ($conditions)";
      args.addAll(directors.map((d) => '%$d%'));
    }

    if (excludeIds != null && excludeIds.isNotEmpty) {
      final placeholders = List.filled(excludeIds.length, '?').join(',');
      query += " AND id NOT IN ($placeholders)";
      args.addAll(excludeIds);
    }

    query += " ORDER BY RANDOM() LIMIT ?";
    args.add(limit);

    // ignore: avoid_print
    print('DEBUG FILTER QUERY: $query');
    // ignore: avoid_print
    print('DEBUG FILTER ARGS: $args');

    final result = await db.rawQuery(query, args);
    return result.map((json) => Video.fromMap(json)).toList();
  }

  Future<List<Video>> getVideosByPaths(List<String> paths) async {
    if (paths.isEmpty) return [];
    
    final db = await instance.database;
    final placeholders = List.filled(paths.length, '?').join(',');
    final result = await db.query(
      'videos',
      where: 'path IN ($placeholders)',
      whereArgs: paths,
    );

    final videos = result.map((json) => Video.fromMap(json)).toList();
    
    // Restore order
    final videoMap = {for (var v in videos) v.path: v};
    final ordered = <Video>[];
    for (final p in paths) {
      if (videoMap.containsKey(p)) {
        ordered.add(videoMap[p]!);
      }
    }
    return ordered;
  }

  Future<List<Video>> getVideosByFilter(String column, String value) async {
    final db = await instance.database;
    String query;
    List<dynamic> args;
    
    if (column == 'year') {
      query = "SELECT * FROM videos WHERE year = ? ORDER BY title ASC";
      args = [value];
    } else {
      query = "SELECT * FROM videos WHERE $column LIKE ? ORDER BY title ASC";
      args = ['%$value%'];
    }
    
    final result = await db.rawQuery(query, args);
    return result.map((json) => Video.fromMap(json)).toList();
  }
}
