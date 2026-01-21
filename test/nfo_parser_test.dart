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

    test('Handles non-XML content gracefully', () async {
      final nfoFile = File('${tempDir.path}/garbage.nfo');
      await nfoFile.writeAsString('This is just plain text, not XML.');
      final result = await NfoParser.parseNfo(nfoFile.path);
      // Parser checks for '<', if not found prints debug and returns null
      expect(result, isNull);
    });

    test('Handles malformed XML gracefully', () async {
      final nfoFile = File('${tempDir.path}/broken.nfo');
      await nfoFile.writeAsString('<movie><title>Unclosed Tag');
      final result = await NfoParser.parseNfo(nfoFile.path);
      // Xml parser throws exception, catch block returns null
      expect(result, isNull);
    });

    test('Handles empty fields/defaults', () async {
      final nfoFile = File('${tempDir.path}/empty.nfo');
      await nfoFile.writeAsString('<movie><year></year></movie>');
      final result = await NfoParser.parseNfo(nfoFile.path);
      expect(result, isNotNull);
      expect(result!['title'], isNull);
      expect(result['year'], isNull); // Empty string usually maps to null or empty in parser logic
      expect(result['rating'], 0.0);
    });

    test('Handles weird/bad ratings', () async {
      final nfoFile = File('${tempDir.path}/bad_rating.nfo');
      await nfoFile.writeAsString('<movie><rating>NaN</rating></movie>');
      final result = await NfoParser.parseNfo(nfoFile.path);
      expect(result, isNotNull);
      expect(result!['rating'], 0.0);
    });
    
    test('Handles UTF-8 content', () async {
       final nfoFile = File('${tempDir.path}/utf8.nfo');
       await nfoFile.writeAsString('''
<movie>
    <title>Hércules</title>
    <plot>Café &amp; Tea</plot>
</movie>
''');
       final result = await NfoParser.parseNfo(nfoFile.path);
       expect(result, isNotNull);
       expect(result!['title'], 'Hércules');
       expect(result['plot'], 'Café & Tea');
    });
  });
}
