// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VideosTable extends Videos with TableInfo<$VideosTable, DriftVideo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _mtimeMeta = const VerificationMeta('mtime');
  @override
  late final GeneratedColumn<double> mtime = GeneratedColumn<double>(
    'mtime',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _genresMeta = const VerificationMeta('genres');
  @override
  late final GeneratedColumn<String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _directorsMeta = const VerificationMeta(
    'directors',
  );
  @override
  late final GeneratedColumn<String> directors = GeneratedColumn<String>(
    'directors',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _plotMeta = const VerificationMeta('plot');
  @override
  late final GeneratedColumn<String> plot = GeneratedColumn<String>(
    'plot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _actorsMeta = const VerificationMeta('actors');
  @override
  late final GeneratedColumn<String> actors = GeneratedColumn<String>(
    'actors',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<String> duration = GeneratedColumn<String>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isSeriesMeta = const VerificationMeta(
    'isSeries',
  );
  @override
  late final GeneratedColumn<int> isSeries = GeneratedColumn<int>(
    'is_series',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sagaMeta = const VerificationMeta('saga');
  @override
  late final GeneratedColumn<String> saga = GeneratedColumn<String>(
    'saga',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sagaIndexMeta = const VerificationMeta(
    'sagaIndex',
  );
  @override
  late final GeneratedColumn<int> sagaIndex = GeneratedColumn<int>(
    'saga_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    path,
    mtime,
    title,
    genres,
    year,
    directors,
    plot,
    actors,
    duration,
    rating,
    isSeries,
    posterPath,
    saga,
    sagaIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'videos';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftVideo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('mtime')) {
      context.handle(
        _mtimeMeta,
        mtime.isAcceptableOrUnknown(data['mtime']!, _mtimeMeta),
      );
    } else if (isInserting) {
      context.missing(_mtimeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('genres')) {
      context.handle(
        _genresMeta,
        genres.isAcceptableOrUnknown(data['genres']!, _genresMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('directors')) {
      context.handle(
        _directorsMeta,
        directors.isAcceptableOrUnknown(data['directors']!, _directorsMeta),
      );
    }
    if (data.containsKey('plot')) {
      context.handle(
        _plotMeta,
        plot.isAcceptableOrUnknown(data['plot']!, _plotMeta),
      );
    }
    if (data.containsKey('actors')) {
      context.handle(
        _actorsMeta,
        actors.isAcceptableOrUnknown(data['actors']!, _actorsMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('is_series')) {
      context.handle(
        _isSeriesMeta,
        isSeries.isAcceptableOrUnknown(data['is_series']!, _isSeriesMeta),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('saga')) {
      context.handle(
        _sagaMeta,
        saga.isAcceptableOrUnknown(data['saga']!, _sagaMeta),
      );
    }
    if (data.containsKey('saga_index')) {
      context.handle(
        _sagaIndexMeta,
        sagaIndex.isAcceptableOrUnknown(data['saga_index']!, _sagaIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftVideo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftVideo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      mtime: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mtime'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      genres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genres'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      )!,
      directors: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}directors'],
      )!,
      plot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot'],
      )!,
      actors: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actors'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}duration'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      )!,
      isSeries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_series'],
      )!,
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      )!,
      saga: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}saga'],
      )!,
      sagaIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saga_index'],
      )!,
    );
  }

  @override
  $VideosTable createAlias(String alias) {
    return $VideosTable(attachedDatabase, alias);
  }
}

class DriftVideo extends DataClass implements Insertable<DriftVideo> {
  final int id;
  final String path;
  final double mtime;
  final String title;
  final String genres;
  final String year;
  final String directors;
  final String plot;
  final String actors;
  final String duration;
  final double rating;
  final int isSeries;
  final String posterPath;
  final String saga;
  final int sagaIndex;
  const DriftVideo({
    required this.id,
    required this.path,
    required this.mtime,
    required this.title,
    required this.genres,
    required this.year,
    required this.directors,
    required this.plot,
    required this.actors,
    required this.duration,
    required this.rating,
    required this.isSeries,
    required this.posterPath,
    required this.saga,
    required this.sagaIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    map['mtime'] = Variable<double>(mtime);
    map['title'] = Variable<String>(title);
    map['genres'] = Variable<String>(genres);
    map['year'] = Variable<String>(year);
    map['directors'] = Variable<String>(directors);
    map['plot'] = Variable<String>(plot);
    map['actors'] = Variable<String>(actors);
    map['duration'] = Variable<String>(duration);
    map['rating'] = Variable<double>(rating);
    map['is_series'] = Variable<int>(isSeries);
    map['poster_path'] = Variable<String>(posterPath);
    map['saga'] = Variable<String>(saga);
    map['saga_index'] = Variable<int>(sagaIndex);
    return map;
  }

  VideosCompanion toCompanion(bool nullToAbsent) {
    return VideosCompanion(
      id: Value(id),
      path: Value(path),
      mtime: Value(mtime),
      title: Value(title),
      genres: Value(genres),
      year: Value(year),
      directors: Value(directors),
      plot: Value(plot),
      actors: Value(actors),
      duration: Value(duration),
      rating: Value(rating),
      isSeries: Value(isSeries),
      posterPath: Value(posterPath),
      saga: Value(saga),
      sagaIndex: Value(sagaIndex),
    );
  }

  factory DriftVideo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftVideo(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      mtime: serializer.fromJson<double>(json['mtime']),
      title: serializer.fromJson<String>(json['title']),
      genres: serializer.fromJson<String>(json['genres']),
      year: serializer.fromJson<String>(json['year']),
      directors: serializer.fromJson<String>(json['directors']),
      plot: serializer.fromJson<String>(json['plot']),
      actors: serializer.fromJson<String>(json['actors']),
      duration: serializer.fromJson<String>(json['duration']),
      rating: serializer.fromJson<double>(json['rating']),
      isSeries: serializer.fromJson<int>(json['isSeries']),
      posterPath: serializer.fromJson<String>(json['posterPath']),
      saga: serializer.fromJson<String>(json['saga']),
      sagaIndex: serializer.fromJson<int>(json['sagaIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'mtime': serializer.toJson<double>(mtime),
      'title': serializer.toJson<String>(title),
      'genres': serializer.toJson<String>(genres),
      'year': serializer.toJson<String>(year),
      'directors': serializer.toJson<String>(directors),
      'plot': serializer.toJson<String>(plot),
      'actors': serializer.toJson<String>(actors),
      'duration': serializer.toJson<String>(duration),
      'rating': serializer.toJson<double>(rating),
      'isSeries': serializer.toJson<int>(isSeries),
      'posterPath': serializer.toJson<String>(posterPath),
      'saga': serializer.toJson<String>(saga),
      'sagaIndex': serializer.toJson<int>(sagaIndex),
    };
  }

  DriftVideo copyWith({
    int? id,
    String? path,
    double? mtime,
    String? title,
    String? genres,
    String? year,
    String? directors,
    String? plot,
    String? actors,
    String? duration,
    double? rating,
    int? isSeries,
    String? posterPath,
    String? saga,
    int? sagaIndex,
  }) => DriftVideo(
    id: id ?? this.id,
    path: path ?? this.path,
    mtime: mtime ?? this.mtime,
    title: title ?? this.title,
    genres: genres ?? this.genres,
    year: year ?? this.year,
    directors: directors ?? this.directors,
    plot: plot ?? this.plot,
    actors: actors ?? this.actors,
    duration: duration ?? this.duration,
    rating: rating ?? this.rating,
    isSeries: isSeries ?? this.isSeries,
    posterPath: posterPath ?? this.posterPath,
    saga: saga ?? this.saga,
    sagaIndex: sagaIndex ?? this.sagaIndex,
  );
  DriftVideo copyWithCompanion(VideosCompanion data) {
    return DriftVideo(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      mtime: data.mtime.present ? data.mtime.value : this.mtime,
      title: data.title.present ? data.title.value : this.title,
      genres: data.genres.present ? data.genres.value : this.genres,
      year: data.year.present ? data.year.value : this.year,
      directors: data.directors.present ? data.directors.value : this.directors,
      plot: data.plot.present ? data.plot.value : this.plot,
      actors: data.actors.present ? data.actors.value : this.actors,
      duration: data.duration.present ? data.duration.value : this.duration,
      rating: data.rating.present ? data.rating.value : this.rating,
      isSeries: data.isSeries.present ? data.isSeries.value : this.isSeries,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      saga: data.saga.present ? data.saga.value : this.saga,
      sagaIndex: data.sagaIndex.present ? data.sagaIndex.value : this.sagaIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftVideo(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('mtime: $mtime, ')
          ..write('title: $title, ')
          ..write('genres: $genres, ')
          ..write('year: $year, ')
          ..write('directors: $directors, ')
          ..write('plot: $plot, ')
          ..write('actors: $actors, ')
          ..write('duration: $duration, ')
          ..write('rating: $rating, ')
          ..write('isSeries: $isSeries, ')
          ..write('posterPath: $posterPath, ')
          ..write('saga: $saga, ')
          ..write('sagaIndex: $sagaIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    path,
    mtime,
    title,
    genres,
    year,
    directors,
    plot,
    actors,
    duration,
    rating,
    isSeries,
    posterPath,
    saga,
    sagaIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftVideo &&
          other.id == this.id &&
          other.path == this.path &&
          other.mtime == this.mtime &&
          other.title == this.title &&
          other.genres == this.genres &&
          other.year == this.year &&
          other.directors == this.directors &&
          other.plot == this.plot &&
          other.actors == this.actors &&
          other.duration == this.duration &&
          other.rating == this.rating &&
          other.isSeries == this.isSeries &&
          other.posterPath == this.posterPath &&
          other.saga == this.saga &&
          other.sagaIndex == this.sagaIndex);
}

class VideosCompanion extends UpdateCompanion<DriftVideo> {
  final Value<int> id;
  final Value<String> path;
  final Value<double> mtime;
  final Value<String> title;
  final Value<String> genres;
  final Value<String> year;
  final Value<String> directors;
  final Value<String> plot;
  final Value<String> actors;
  final Value<String> duration;
  final Value<double> rating;
  final Value<int> isSeries;
  final Value<String> posterPath;
  final Value<String> saga;
  final Value<int> sagaIndex;
  const VideosCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.mtime = const Value.absent(),
    this.title = const Value.absent(),
    this.genres = const Value.absent(),
    this.year = const Value.absent(),
    this.directors = const Value.absent(),
    this.plot = const Value.absent(),
    this.actors = const Value.absent(),
    this.duration = const Value.absent(),
    this.rating = const Value.absent(),
    this.isSeries = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.saga = const Value.absent(),
    this.sagaIndex = const Value.absent(),
  });
  VideosCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    required double mtime,
    this.title = const Value.absent(),
    this.genres = const Value.absent(),
    this.year = const Value.absent(),
    this.directors = const Value.absent(),
    this.plot = const Value.absent(),
    this.actors = const Value.absent(),
    this.duration = const Value.absent(),
    this.rating = const Value.absent(),
    this.isSeries = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.saga = const Value.absent(),
    this.sagaIndex = const Value.absent(),
  }) : path = Value(path),
       mtime = Value(mtime);
  static Insertable<DriftVideo> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<double>? mtime,
    Expression<String>? title,
    Expression<String>? genres,
    Expression<String>? year,
    Expression<String>? directors,
    Expression<String>? plot,
    Expression<String>? actors,
    Expression<String>? duration,
    Expression<double>? rating,
    Expression<int>? isSeries,
    Expression<String>? posterPath,
    Expression<String>? saga,
    Expression<int>? sagaIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (mtime != null) 'mtime': mtime,
      if (title != null) 'title': title,
      if (genres != null) 'genres': genres,
      if (year != null) 'year': year,
      if (directors != null) 'directors': directors,
      if (plot != null) 'plot': plot,
      if (actors != null) 'actors': actors,
      if (duration != null) 'duration': duration,
      if (rating != null) 'rating': rating,
      if (isSeries != null) 'is_series': isSeries,
      if (posterPath != null) 'poster_path': posterPath,
      if (saga != null) 'saga': saga,
      if (sagaIndex != null) 'saga_index': sagaIndex,
    });
  }

  VideosCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<double>? mtime,
    Value<String>? title,
    Value<String>? genres,
    Value<String>? year,
    Value<String>? directors,
    Value<String>? plot,
    Value<String>? actors,
    Value<String>? duration,
    Value<double>? rating,
    Value<int>? isSeries,
    Value<String>? posterPath,
    Value<String>? saga,
    Value<int>? sagaIndex,
  }) {
    return VideosCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      mtime: mtime ?? this.mtime,
      title: title ?? this.title,
      genres: genres ?? this.genres,
      year: year ?? this.year,
      directors: directors ?? this.directors,
      plot: plot ?? this.plot,
      actors: actors ?? this.actors,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      isSeries: isSeries ?? this.isSeries,
      posterPath: posterPath ?? this.posterPath,
      saga: saga ?? this.saga,
      sagaIndex: sagaIndex ?? this.sagaIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (mtime.present) {
      map['mtime'] = Variable<double>(mtime.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (directors.present) {
      map['directors'] = Variable<String>(directors.value);
    }
    if (plot.present) {
      map['plot'] = Variable<String>(plot.value);
    }
    if (actors.present) {
      map['actors'] = Variable<String>(actors.value);
    }
    if (duration.present) {
      map['duration'] = Variable<String>(duration.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (isSeries.present) {
      map['is_series'] = Variable<int>(isSeries.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (saga.present) {
      map['saga'] = Variable<String>(saga.value);
    }
    if (sagaIndex.present) {
      map['saga_index'] = Variable<int>(sagaIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideosCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('mtime: $mtime, ')
          ..write('title: $title, ')
          ..write('genres: $genres, ')
          ..write('year: $year, ')
          ..write('directors: $directors, ')
          ..write('plot: $plot, ')
          ..write('actors: $actors, ')
          ..write('duration: $duration, ')
          ..write('rating: $rating, ')
          ..write('isSeries: $isSeries, ')
          ..write('posterPath: $posterPath, ')
          ..write('saga: $saga, ')
          ..write('sagaIndex: $sagaIndex')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VideosTable videos = $VideosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [videos];
}

typedef $$VideosTableCreateCompanionBuilder =
    VideosCompanion Function({
      Value<int> id,
      required String path,
      required double mtime,
      Value<String> title,
      Value<String> genres,
      Value<String> year,
      Value<String> directors,
      Value<String> plot,
      Value<String> actors,
      Value<String> duration,
      Value<double> rating,
      Value<int> isSeries,
      Value<String> posterPath,
      Value<String> saga,
      Value<int> sagaIndex,
    });
typedef $$VideosTableUpdateCompanionBuilder =
    VideosCompanion Function({
      Value<int> id,
      Value<String> path,
      Value<double> mtime,
      Value<String> title,
      Value<String> genres,
      Value<String> year,
      Value<String> directors,
      Value<String> plot,
      Value<String> actors,
      Value<String> duration,
      Value<double> rating,
      Value<int> isSeries,
      Value<String> posterPath,
      Value<String> saga,
      Value<int> sagaIndex,
    });

class $$VideosTableFilterComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mtime => $composableBuilder(
    column: $table.mtime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get directors => $composableBuilder(
    column: $table.directors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actors => $composableBuilder(
    column: $table.actors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isSeries => $composableBuilder(
    column: $table.isSeries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saga => $composableBuilder(
    column: $table.saga,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sagaIndex => $composableBuilder(
    column: $table.sagaIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VideosTableOrderingComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mtime => $composableBuilder(
    column: $table.mtime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get directors => $composableBuilder(
    column: $table.directors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actors => $composableBuilder(
    column: $table.actors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isSeries => $composableBuilder(
    column: $table.isSeries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saga => $composableBuilder(
    column: $table.saga,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sagaIndex => $composableBuilder(
    column: $table.sagaIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VideosTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideosTable> {
  $$VideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<double> get mtime =>
      $composableBuilder(column: $table.mtime, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get directors =>
      $composableBuilder(column: $table.directors, builder: (column) => column);

  GeneratedColumn<String> get plot =>
      $composableBuilder(column: $table.plot, builder: (column) => column);

  GeneratedColumn<String> get actors =>
      $composableBuilder(column: $table.actors, builder: (column) => column);

  GeneratedColumn<String> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get isSeries =>
      $composableBuilder(column: $table.isSeries, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saga =>
      $composableBuilder(column: $table.saga, builder: (column) => column);

  GeneratedColumn<int> get sagaIndex =>
      $composableBuilder(column: $table.sagaIndex, builder: (column) => column);
}

class $$VideosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VideosTable,
          DriftVideo,
          $$VideosTableFilterComposer,
          $$VideosTableOrderingComposer,
          $$VideosTableAnnotationComposer,
          $$VideosTableCreateCompanionBuilder,
          $$VideosTableUpdateCompanionBuilder,
          (DriftVideo, BaseReferences<_$AppDatabase, $VideosTable, DriftVideo>),
          DriftVideo,
          PrefetchHooks Function()
        > {
  $$VideosTableTableManager(_$AppDatabase db, $VideosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<double> mtime = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<String> year = const Value.absent(),
                Value<String> directors = const Value.absent(),
                Value<String> plot = const Value.absent(),
                Value<String> actors = const Value.absent(),
                Value<String> duration = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<int> isSeries = const Value.absent(),
                Value<String> posterPath = const Value.absent(),
                Value<String> saga = const Value.absent(),
                Value<int> sagaIndex = const Value.absent(),
              }) => VideosCompanion(
                id: id,
                path: path,
                mtime: mtime,
                title: title,
                genres: genres,
                year: year,
                directors: directors,
                plot: plot,
                actors: actors,
                duration: duration,
                rating: rating,
                isSeries: isSeries,
                posterPath: posterPath,
                saga: saga,
                sagaIndex: sagaIndex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String path,
                required double mtime,
                Value<String> title = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<String> year = const Value.absent(),
                Value<String> directors = const Value.absent(),
                Value<String> plot = const Value.absent(),
                Value<String> actors = const Value.absent(),
                Value<String> duration = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<int> isSeries = const Value.absent(),
                Value<String> posterPath = const Value.absent(),
                Value<String> saga = const Value.absent(),
                Value<int> sagaIndex = const Value.absent(),
              }) => VideosCompanion.insert(
                id: id,
                path: path,
                mtime: mtime,
                title: title,
                genres: genres,
                year: year,
                directors: directors,
                plot: plot,
                actors: actors,
                duration: duration,
                rating: rating,
                isSeries: isSeries,
                posterPath: posterPath,
                saga: saga,
                sagaIndex: sagaIndex,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VideosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VideosTable,
      DriftVideo,
      $$VideosTableFilterComposer,
      $$VideosTableOrderingComposer,
      $$VideosTableAnnotationComposer,
      $$VideosTableCreateCompanionBuilder,
      $$VideosTableUpdateCompanionBuilder,
      (DriftVideo, BaseReferences<_$AppDatabase, $VideosTable, DriftVideo>),
      DriftVideo,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VideosTableTableManager get videos =>
      $$VideosTableTableManager(_db, _db.videos);
}
