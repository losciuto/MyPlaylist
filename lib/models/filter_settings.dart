class FilterSettings {
  final List<String> genres;
  final List<String> years;
  final double ratingMin;
  final List<String> actors;
  final List<String> directors;
  final int limit;

  FilterSettings({
    this.genres = const [],
    this.years = const [],
    this.ratingMin = 0.0,
    this.actors = const [],
    this.directors = const [],
    this.limit = 20,
  });
}
