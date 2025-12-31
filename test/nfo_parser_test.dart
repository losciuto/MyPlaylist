import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/utils/nfo_parser.dart';

void main() {
  group('NfoParser Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nfo_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('Parses complex Kodi-style NFO correctly', () async {
      final nfoFile = File('${tempDir.path}/movie.nfo');
      await nfoFile.writeAsString('''
<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<movie>
    <title>Inception</title>
    <originaltitle>Inception</originaltitle>
    <year>2010</year>
    <plot>A thief who steals corporate secrets through the use of dream-sharing technology...</plot>
    <rating name="imdb" max="10" default="true">
        <value>8.8</value>
        <votes>2500000</votes>
    </rating>
    <director>Christopher Nolan</director>
    <genre>Action</genre>
    <genre>Sci-Fi</genre>
    <actor>
        <name>Leonardo DiCaprio</name>
        <role>Cobb</role>
    </actor>
    <actor>
        <name>Joseph Gordon-Levitt</name>
        <role>Arthur</role>
    </actor>
</movie>
''');

      final result = await NfoParser.parseNfo(nfoFile.path);

      expect(result, isNotNull);
      expect(result!['title'], 'Inception');
      expect(result['year'], '2010');
      expect(result['rating'], 8.8);
      expect(result['directors'], 'Christopher Nolan');
      expect(result['genres'], contains('Action'));
      expect(result['genres'], contains('Sci-Fi'));
      expect(result['actors'], contains('Leonardo DiCaprio'));
    });

    test('Parses simple NFO correctly', () async {
      final nfoFile = File('${tempDir.path}/simple.nfo');
      await nfoFile.writeAsString('''
<movie>
    <title>Simple Movie</title>
    <rating>7,5</rating>
</movie>
''');

      final result = await NfoParser.parseNfo(nfoFile.path);

      expect(result, isNotNull);
      expect(result!['title'], 'Simple Movie');
      // Should handle comma as decimal separator if logic supports it
      expect(result['rating'], 7.5);
    });

    test('Handles missing file gracefully', () async {
      final result = await NfoParser.parseNfo('${tempDir.path}/ghost.nfo');
      expect(result, isNull);
    });
  });
}
