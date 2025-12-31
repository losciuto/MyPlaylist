import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/utils/nfo_generator.dart';
import 'package:xml/xml.dart';

void main() {
  group('NfoGenerator Tests', () {
    test('Generates valid NFO XML from TMDB data', () {
      final mockData = {
        'title': 'Inception',
        'original_title': 'Inception',
        'overview': 'Dream within a dream.',
        'tagline': 'Your mind is the scene of the crime.',
        'release_date': '2010-07-16',
        'vote_average': 8.8,
        'vote_count': 25000,
        'runtime': 148,
        'genres': [
          {'name': 'Action'},
          {'name': 'Sci-Fi'}
        ],
        'credits': {
          'cast': [
             {'name': 'Leonardo DiCaprio', 'character': 'Cobb', 'profile_path': '/leo.jpg'}
          ],
          'crew': [
             {'name': 'Christopher Nolan', 'job': 'Director'}
          ]
        },
        'poster_path': '/poster.jpg',
        'backdrop_path': '/backdrop.jpg'
      };

      final xmlString = NfoGenerator.generateMovieNfo(mockData);
      
      // Verify basic structure
      final document = XmlDocument.parse(xmlString);
      expect(document.findAllElements('movie').isNotEmpty, true);
      expect(document.findAllElements('title').first.innerText, 'Inception');
      expect(document.findAllElements('year').first.innerText, '2010');
      expect(document.findAllElements('rating').first.getAttribute('default'), 'true');
      expect(document.findAllElements('value').first.innerText, '8.8');
      
      // Verify Actors
      final actors = document.findAllElements('actor');
      expect(actors.isNotEmpty, true);
      expect(actors.first.findElements('name').first.innerText, 'Leonardo DiCaprio');
      
      // Verify Director
      final directors = document.findAllElements('director');
      expect(directors.first.innerText, 'Christopher Nolan');
    });
  });
}
