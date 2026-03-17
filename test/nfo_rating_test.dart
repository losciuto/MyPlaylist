import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/utils/nfo_strategies/kodi_nfo_strategy.dart';

void main() {
  final strategy = KodiNfoStrategy();

  test('Parse standard rating', () async {
    const xml = '''
    <movie>
      <title>Test Movie</title>
      <userrating>8.5</userrating>
    </movie>
    ''';
    final result = await strategy.parse(xml, '/tmp/movie.nfo');
    expect(result?['rating'], 8.5);
  });

  test('Parse nested rating default', () async {
    const xml = '''
    <movie>
      <title>Test Movie</title>
      <ratings>
        <rating name="imdb" max="10">
          <value>7.0</value>
        </rating>
        <rating name="tmdb" max="10" default="true">
          <value>8.2</value>
        </rating>
      </ratings>
    </movie>
    ''';
    final result = await strategy.parse(xml, '/tmp/movie.nfo');
    expect(result?['rating'], 8.2);
  });

  test('Parse nested rating without default (fallback to first)', () async {
    const xml = '''
    <movie>
      <title>Test Movie</title>
      <ratings>
        <rating name="imdb" max="10">
          <value>6.5</value>
        </rating>
        <rating name="tmdb" max="10">
          <value>7.5</value>
        </rating>
      </ratings>
    </movie>
    ''';
    final result = await strategy.parse(xml, '/tmp/movie.nfo');
    // Logic says: first one if no default
    expect(result?['rating'], 6.5);
  });

  test('Parse rating with comma', () async {
    const xml = '''
    <movie>
      <title>Test Movie</title>
      <userrating>8,9</userrating>
    </movie>
    ''';
    final result = await strategy.parse(xml, '/tmp/movie.nfo');
    expect(result?['rating'], 8.9);
  });

  test('Parse complex rating string', () async {
    const xml = '''
    <movie>
      <title>Test Movie</title>
      <userrating>8.5/10</userrating>
    </movie>
    ''';
    final result = await strategy.parse(xml, '/tmp/movie.nfo');
    expect(result?['rating'], 8.5);
  });

  test('Parse empty rating', () async {
    const xml = '''
      <movie>
        <title>Test Movie</title>
        <userrating></userrating>
      </movie>
      ''';
    final result = await strategy.parse(xml, '/tmp/movie.nfo');
    // Should fall back or be 0.0
    expect(result?['rating'], 0.0);
  });

  test('Parse zero rating', () async {
    const xml = '''
      <movie>
        <title>Test Movie</title>
        <userrating>0</userrating>
      </movie>
      ''';
    final result = await strategy.parse(xml, '/tmp/movie.nfo');
    expect(result?['rating'], 0.0);
  });
}
