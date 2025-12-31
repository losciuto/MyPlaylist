class FilterSettings {
  final List<String> genres;
  final List<String> years;
  final double ratingMin;
  final List<String> actors;
  final List<String> directors;
  final int limit;
  final List<String> excludedGenres;
  final List<String> excludedYears;
  final List<String> excludedActors;
  final List<String> excludedDirectors;

  FilterSettings({
    this.genres = const [],
    this.years = const [],
    this.ratingMin = 0.0,
    this.actors = const [],
    this.directors = const [],
    this.excludedGenres = const [],
    this.excludedYears = const [],
    this.excludedActors = const [],
    this.excludedDirectors = const [],
    this.limit = 20,
  });
}
