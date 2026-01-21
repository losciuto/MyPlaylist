class Video {
  final int? id;
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
  final bool isSeries;
  final String posterPath;
  final String saga;
  final int sagaIndex;

  Video({
    this.id,
    required this.path,
    required this.mtime,
    this.title = '',
    this.genres = '',
    this.year = '',
    this.directors = '',
    this.plot = '',
    this.actors = '',
    this.duration = '',
    this.rating = 0.0,
    this.isSeries = false,
    this.posterPath = '',
    this.saga = '',
    this.sagaIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'mtime': mtime,
      'title': title,
      'genres': genres,
      'year': year,
      'directors': directors,
      'plot': plot,
      'actors': actors,
      'duration': duration,
      'rating': rating,
      'isSeries': isSeries ? 1 : 0,
      'posterPath': posterPath,
      'saga': saga,
      'sagaIndex': sagaIndex,
    };
  }

  factory Video.fromMap(Map<String, dynamic> map) {
    return Video(
      id: map['id'],
      path: map['path'],
      mtime: (map['mtime'] is int) ? (map['mtime'] as int).toDouble() : (map['mtime'] as double? ?? 0.0),
      title: map['title'] ?? '',
      genres: map['genres'] ?? '',
      year: map['year']?.toString() ?? '',
      directors: map['directors'] ?? '',
      plot: map['plot'] ?? '',
      actors: map['actors'] ?? '',
      duration: map['duration'] ?? '',
      rating: (map['rating'] is int) ? (map['rating'] as int).toDouble() : (map['rating'] as double? ?? 0.0),
      isSeries: map['isSeries'] == 1,
      posterPath: map['posterPath'] ?? '',
      saga: map['saga'] ?? '',
      sagaIndex: map['sagaIndex'] ?? 0,
    );
  }

  Video copyWith({
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
    bool? isSeries,
    String? posterPath,
    String? saga,
    int? sagaIndex,
  }) {
    return Video(
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
}
