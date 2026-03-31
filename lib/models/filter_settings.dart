class FilterSettings {
  final List<String> genres;
  final List<String> years;
  final double ratingMin;
  final List<String> actors;
  final List<String> directors;
  final List<String> sagas;
  final int limit;
  final List<String> excludedGenres;
  final List<String> excludedYears;
  final List<String> excludedActors;
  final List<String> excludedDirectors;
  final List<String> excludedSagas;

  FilterSettings({
    this.genres = const [],
    this.years = const [],
    this.ratingMin = 0.0,
    this.actors = const [],
    this.directors = const [],
    this.sagas = const [],
    this.excludedGenres = const [],
    this.excludedYears = const [],
    this.excludedActors = const [],
    this.excludedDirectors = const [],
    this.excludedSagas = const [],
    this.limit = 20,
  });

  Map<String, dynamic> toJson() => {
    'genres': genres,
    'years': years,
    'ratingMin': ratingMin,
    'actors': actors,
    'directors': directors,
    'sagas': sagas,
    'excludedGenres': excludedGenres,
    'excludedYears': excludedYears,
    'excludedActors': excludedActors,
    'excludedDirectors': excludedDirectors,
    'excludedSagas': excludedSagas,
    'limit': limit,
  };

  factory FilterSettings.fromJson(Map<String, dynamic> json) {
    return FilterSettings(
      genres: List<String>.from(json['genres'] ?? []),
      years: List<String>.from(json['years'] ?? []),
      ratingMin: (json['ratingMin'] ?? 0.0).toDouble(),
      actors: List<String>.from(json['actors'] ?? []),
      directors: List<String>.from(json['directors'] ?? []),
      sagas: List<String>.from(json['sagas'] ?? []),
      excludedGenres: List<String>.from(json['excludedGenres'] ?? []),
      excludedYears: List<String>.from(json['excludedYears'] ?? []),
      excludedActors: List<String>.from(json['excludedActors'] ?? []),
      excludedDirectors: List<String>.from(json['excludedDirectors'] ?? []),
      excludedSagas: List<String>.from(json['excludedSagas'] ?? []),
      limit: json['limit'] ?? 20,
    );
  }
}
