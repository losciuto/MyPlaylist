class Video {
  Video({
    this.id,
    required this.path,
    required this.mtime,
    this.title = '',
    this.genres = '',
    this.year = '',
    this.directors = '',
    this.directorThumbs = '',
    this.plot = '',
    this.actors = '',
    this.actorThumbs = '',
    this.duration = '',
    this.rating = 0.0,
    this.personalRating = 0.0,
    this.isSeries = false,
    this.posterPath = '',
    this.saga = '',
    this.sagaIndex = 0,
    this.dateAdded,
    this.tags = '',
  });

  factory Video.fromMap(Map<String, dynamic> map) {
    return Video(
      id: map['id'],
      path: map['path'],
      mtime: (map['mtime'] is int)
          ? (map['mtime'] as int).toDouble()
          : (map['mtime'] as double? ?? 0.0),
      title: map['title'] ?? '',
      genres: map['genres'] ?? '',
      year: map['year']?.toString() ?? '',
      directors: map['directors'] ?? '',
      directorThumbs: map['directorThumbs'] ?? '',
      plot: map['plot'] ?? '',
      actors: map['actors'] ?? '',
      actorThumbs: map['actorThumbs'] ?? '',
      duration: map['duration'] ?? '',
      rating: (map['rating'] is int)
          ? (map['rating'] as int).toDouble()
          : (map['rating'] as double? ?? 0.0),
      personalRating: (map['personal_rating'] is int)
          ? (map['personal_rating'] as int).toDouble()
          : (map['personal_rating'] as double? ?? 0.0),
      isSeries: map['isSeries'] == 1,
      posterPath: map['posterPath'] ?? '',
      saga: map['saga'] ?? '',
      sagaIndex: map['sagaIndex'] ?? 0,
      dateAdded: map['date_added'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date_added'])
          : null,
      tags: map['tags'] ?? '',
    );
  }
  final int? id;
  final String path;
  final double mtime;
  final String title;
  final String genres;
  final String year;
  final String directors;
  final String directorThumbs;
  final String plot;
  final String actors;
  final String actorThumbs;
  final String duration;
  final double rating;
  final double personalRating;
  final bool isSeries;
  final String posterPath;
  final String saga;
  final int sagaIndex;
  final DateTime? dateAdded;
  final String tags;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'mtime': mtime,
      'title': title,
      'genres': genres,
      'year': year,
      'directors': directors,
      'directorThumbs': directorThumbs,
      'plot': plot,
      'actors': actors,
      'actorThumbs': actorThumbs,
      'duration': duration,
      'rating': rating,
      'personal_rating': personalRating,
      'isSeries': isSeries ? 1 : 0,
      'posterPath': posterPath,
      'saga': saga,
      'sagaIndex': sagaIndex,
      'date_added': dateAdded?.millisecondsSinceEpoch,
      'tags': tags,
    };
  }

  Video copyWith({
    int? id,
    String? path,
    double? mtime,
    String? title,
    String? genres,
    String? year,
    String? directors,
    String? directorThumbs,
    String? plot,
    String? actors,
    String? actorThumbs,
    String? duration,
    double? rating,
    double? personalRating,
    bool? isSeries,
    String? posterPath,
    String? saga,
    int? sagaIndex,
    DateTime? dateAdded,
    String? tags,
  }) {
    return Video(
      id: id ?? this.id,
      path: path ?? this.path,
      mtime: mtime ?? this.mtime,
      title: title ?? this.title,
      genres: genres ?? this.genres,
      year: year ?? this.year,
      directors: directors ?? this.directors,
      directorThumbs: directorThumbs ?? this.directorThumbs,
      plot: plot ?? this.plot,
      actors: actors ?? this.actors,
      actorThumbs: actorThumbs ?? this.actorThumbs,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      personalRating: personalRating ?? this.personalRating,
      isSeries: isSeries ?? this.isSeries,
      posterPath: posterPath ?? this.posterPath,
      saga: saga ?? this.saga,
      sagaIndex: sagaIndex ?? this.sagaIndex,
      dateAdded: dateAdded ?? this.dateAdded,
      tags: tags ?? this.tags,
    );
  }
}
