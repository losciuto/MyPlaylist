import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/video.dart' as model;

part 'app_database.g.dart';

@DataClassName('DriftVideo')
class Videos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  RealColumn get mtime => real()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get genres => text().withDefault(const Constant(''))();
  TextColumn get year => text().withDefault(const Constant(''))();
  TextColumn get directors => text().withDefault(const Constant(''))();
  TextColumn get plot => text().withDefault(const Constant(''))();
  TextColumn get actors => text().withDefault(const Constant(''))();
  TextColumn get duration => text().withDefault(const Constant(''))();
  RealColumn get rating => real().withDefault(const Constant(0.0))();
  IntColumn get isSeries => integer().withDefault(const Constant(0))();
  TextColumn get posterPath => text().withDefault(const Constant(''))();
  TextColumn get saga => text().withDefault(const Constant(''))();
  TextColumn get actorThumbs => text().withDefault(const Constant(''))();
  TextColumn get directorThumbs => text().withDefault(const Constant(''))();
  IntColumn get sagaIndex => integer().withDefault(const Constant(0))();

  @override
  List<Index> get indexes => [
    Index('videos_actors_idx', 'CREATE INDEX IF NOT EXISTS videos_actors_idx ON videos (actors)'),
    Index('videos_directors_idx', 'CREATE INDEX IF NOT EXISTS videos_directors_idx ON videos (directors)'),
  ];
}

@DriftDatabase(tables: [Videos])
class AppDatabase extends _$AppDatabase {
  static final AppDatabase instance = AppDatabase();
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Add actorThumbs and directorThumbs columns
          await m.addColumn(videos, videos.actorThumbs);
          await m.addColumn(videos, videos.directorThumbs);
        }
        if (from < 3) {
          // Add indices
          await m.createIndex(Index('videos_actors_idx', 'CREATE INDEX IF NOT EXISTS videos_actors_idx ON videos (actors)'));
          await m.createIndex(Index('videos_directors_idx', 'CREATE INDEX IF NOT EXISTS videos_directors_idx ON videos (directors)'));
        }
      },
      beforeOpen: (details) async {
        // Migration logic removed - sqflite is no longer used
      },
    );
  }
  // --- Migration logic handled by beforeOpen ---

  // --- CRUD Operations (UI/Service Bridge) ---

  Future<void> insertVideo(model.Video video) async {
    await insertVideos([video]);
  }

  Future<void> insertVideos(List<model.Video> videoList) async {
    await batch((b) {
      for (final video in videoList) {
        b.insertAll(
          videos,
          [
            VideosCompanion.insert(
              path: video.path,
              mtime: video.mtime,
              title: Value(video.title),
              genres: Value(video.genres),
              year: Value(video.year),
              directors: Value(video.directors),
              directorThumbs: Value(video.directorThumbs),
              plot: Value(video.plot),
              actors: Value(video.actors),
              actorThumbs: Value(video.actorThumbs),
              duration: Value(video.duration),
              rating: Value(video.rating),
              isSeries: Value(video.isSeries ? 1 : 0),
              posterPath: Value(video.posterPath),
              saga: Value(video.saga),
              sagaIndex: Value(video.sagaIndex),
            ),
          ],
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> insertVideoUnique(model.Video video) async {
    await into(videos).insert(
      VideosCompanion.insert(
        path: video.path,
        mtime: video.mtime,
        title: Value(video.title),
        genres: Value(video.genres),
        year: Value(video.year),
        directors: Value(video.directors),
        directorThumbs: Value(video.directorThumbs),
        plot: Value(video.plot),
        actors: Value(video.actors),
        actorThumbs: Value(video.actorThumbs),
        duration: Value(video.duration),
        rating: Value(video.rating),
        isSeries: Value(video.isSeries ? 1 : 0),
        posterPath: Value(video.posterPath),
        saga: Value(video.saga),
        sagaIndex: Value(video.sagaIndex),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<int> updateVideo(model.Video video) async {
    return await (update(videos)..where((t) => t.id.equals(video.id!))).write(
      VideosCompanion(
        path: Value(video.path),
        mtime: Value(video.mtime),
        title: Value(video.title),
        genres: Value(video.genres),
        year: Value(video.year),
        directors: Value(video.directors),
        directorThumbs: Value(video.directorThumbs),
        plot: Value(video.plot),
        actors: Value(video.actors),
        actorThumbs: Value(video.actorThumbs),
        duration: Value(video.duration),
        rating: Value(video.rating),
        isSeries: Value(video.isSeries ? 1 : 0),
        posterPath: Value(video.posterPath),
        saga: Value(video.saga),
        sagaIndex: Value(video.sagaIndex),
      ),
    );
  }

  Future<void> clearDatabase() async {
    await delete(videos).go();
  }

  Future<int> deleteVideo(int id) async {
    return await (delete(videos)..where((t) => t.id.equals(id))).go();
  }

  Future<int> getVideoCount() async {
    final count = videos.id.count();
    final query = selectOnly(videos)..addColumns([count]);
    final result = await query.map((row) => row.read(count)).getSingle();
    return result ?? 0;
  }

  Future<List<model.Video>> getAllVideos() async {
    final driftVideos = await (select(videos)..orderBy([(t) => OrderingTerm(expression: t.title, mode: OrderingMode.asc)])).get();
    return driftVideos.map<model.Video>((v) => _mapDriftToModel(v)).toList();
  }

  model.Video _mapDriftToModel(DriftVideo v) {
    return model.Video(
      id: v.id,
      path: v.path,
      mtime: v.mtime,
      title: v.title ?? '',
      genres: v.genres ?? '',
      year: v.year ?? '',
      directors: v.directors ?? '',
      directorThumbs: v.directorThumbs ?? '',
      plot: v.plot ?? '',
      actors: v.actors ?? '',
      actorThumbs: v.actorThumbs ?? '',
      duration: v.duration ?? '',
      rating: v.rating ?? 0.0,
      isSeries: v.isSeries == 1,
      posterPath: v.posterPath ?? '',
      saga: v.saga ?? '',
      sagaIndex: v.sagaIndex ?? 0,
    );
  }

  Future<List<model.Video>> getRandomPlaylist(int limit, {List<int>? excludeIds}) async {
    final query = select(videos)
      ..orderBy([(t) => OrderingTerm.random()])
      ..limit(limit);
    if (excludeIds != null && excludeIds.isNotEmpty) {
      query.where((t) => t.id.isIn(excludeIds).not());
    }
    final result = await query.get();
    return result.map<model.Video>((v) => _mapDriftToModel(v)).toList();
  }

  Future<List<model.Video>> getRecentPlaylist(int limit) async {
    final result = await (select(videos)
      ..orderBy([(t) => OrderingTerm(expression: t.mtime, mode: OrderingMode.desc)])
      ..limit(limit)).get();
    return result.map<model.Video>((v) => _mapDriftToModel(v)).toList();
  }

  Future<Map<String, int>> getValuesWithCounts(String column) async {
    final result = await select(videos).get();
    
    final Map<String, int> counts = {};
    for (var row in result) {
      String? val;
      switch (column) {
        case 'genres': val = row.genres; break;
        case 'year': val = row.year; break;
        case 'directors': val = row.directors; break;
        case 'actors': val = row.actors; break;
        case 'saga': val = row.saga; break;
      }
      if (val == null || val.isEmpty) continue;

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
    return counts;
  }

  Future<List<model.Video>> getFilteredPlaylist(
      {List<String>? genres,
      List<String>? years,
      double? minRating,
      List<String>? actors,
      List<String>? directors,
      List<String>? excludedGenres,
      List<String>? excludedYears,
      List<String>? excludedActors,
      List<String>? excludedDirectors,
      List<String>? sagas,
      List<String>? excludedSagas,
      int limit = 20,
      List<int>? excludeIds}) async {
        
    final query = select(videos);
    
    query.where((t) {
      final List<Expression<bool>> predicates = [];

      if (genres != null && genres.isNotEmpty) {
        predicates.add(genres.map((g) => t.genres.like('%$g%')).reduce((a, b) => a | b));
      }
      if (years != null && years.isNotEmpty) {
        predicates.add(years.map((y) => t.year.equals(y)).reduce((a, b) => a | b));
      }
      if (minRating != null && minRating > 0) {
        predicates.add(t.rating.isBiggerOrEqualValue(minRating));
      }
      if (actors != null && actors.isNotEmpty) {
        predicates.add(actors.map((a) => t.actors.like('%$a%')).reduce((a, b) => a | b));
      }
      if (directors != null && directors.isNotEmpty) {
        predicates.add(directors.map((d) => t.directors.like('%$d%')).reduce((a, b) => a | b));
      }
      if (sagas != null && sagas.isNotEmpty) {
        predicates.add(sagas.map((s) => t.saga.like('%$s%')).reduce((a, b) => a | b));
      }

      if (excludedGenres != null && excludedGenres.isNotEmpty) {
        for (var g in excludedGenres) {
          predicates.add(t.genres.like('%$g%').not());
        }
      }
      if (excludedYears != null && excludedYears.isNotEmpty) {
        predicates.add(t.year.isIn(excludedYears).not());
      }
      if (excludedActors != null && excludedActors.isNotEmpty) {
        for (var a in excludedActors) {
          predicates.add(t.actors.like('%$a%').not());
        }
      }
      if (excludedDirectors != null && excludedDirectors.isNotEmpty) {
        for (var d in excludedDirectors) {
          predicates.add(t.directors.like('%$d%').not());
        }
      }
      if (excludedSagas != null && excludedSagas.isNotEmpty) {
        for (var s in excludedSagas) {
          predicates.add(t.saga.like('%$s%').not());
        }
      }
      if (excludeIds != null && excludeIds.isNotEmpty) {
        predicates.add(t.id.isIn(excludeIds).not());
      }

      return predicates.isEmpty ? const Constant(true) : predicates.reduce((a, b) => a & b);
    });

    query.orderBy([(t) => OrderingTerm.random()]);
    query.limit(limit);

    final result = await query.get();
    return result.map<model.Video>((v) => _mapDriftToModel(v)).toList();
  }

  Future<List<model.Video>> getVideosByPaths(List<String> paths) async {
    if (paths.isEmpty) return [];
    final result = await (select(videos)..where((t) => t.path.isIn(paths))).get();
    final vList = result.map<model.Video>((v) => _mapDriftToModel(v)).toList();
    
    // Restore order
    final videoMap = {for (var v in vList) v.path: v};
    final ordered = <model.Video>[];
    for (final p in paths) {
      if (videoMap.containsKey(p)) {
        ordered.add(videoMap[p]!);
      }
    }
    return ordered;
  }

  Future<model.Video?> getVideoByPath(String path) async {
    final driftVideo = await (select(videos)..where((t) => t.path.equals(path))).getSingleOrNull();
    return driftVideo == null ? null : _mapDriftToModel(driftVideo);
  }

  Future<List<model.Video>> getVideosByFilter(String column, String value) async {
    final query = select(videos);
    switch (column) {
      case 'year': query.where((t) => t.year.equals(value)); break;
      case 'genres': query.where((t) => t.genres.like('%$value%')); break;
      case 'directors': query.where((t) => t.directors.like('%$value%')); break;
      case 'actors': query.where((t) => t.actors.like('%$value%')); break;
      case 'saga': query.where((t) => t.saga.like('%$value%')); break;
    }
    query.orderBy([(t) => OrderingTerm(expression: t.title, mode: OrderingMode.asc)]);
    final result = await query.get();
    return result.map<model.Video>((v) => _mapDriftToModel(v)).toList();
  }

  Future<String> getDatabasePath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, 'videos_drift.db');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'videos_drift.db'));
    return NativeDatabase(file);
  });
}
