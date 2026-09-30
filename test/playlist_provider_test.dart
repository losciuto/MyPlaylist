import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/models/video.dart';
import 'package:my_playlist/providers/playlist_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_video_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Il provider salva lo stato su disco: in test il path_provider restituisce
    // una cartella temporanea invece di invocare il plugin.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync().path,
        );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PlaylistProvider - playlist casuale', () {
    test('la playlist generata rispetta il limite richiesto', () async {
      final repository = FakeVideoRepository([
        buildVideo(id: 1, title: 'A', path: '/v/a.mkv'),
        buildVideo(id: 2, title: 'B', path: '/v/b.mkv'),
        buildVideo(id: 3, title: 'C', path: '/v/c.mkv'),
      ]);
      final provider = PlaylistProvider(repository);

      final result = await provider.generateRandom(
        count: 2,
        launchPlayer: false,
      );

      expect(result, hasLength(2));
      expect(provider.playlist, hasLength(2));
      expect(provider.hasPlaylist, isTrue);
    });

    test(
      'i video proposti vengono esclusi dalla generazione successiva',
      () async {
        final repository = FakeVideoRepository([
          buildVideo(id: 1, title: 'A', path: '/v/a.mkv'),
          buildVideo(id: 2, title: 'B', path: '/v/b.mkv'),
          buildVideo(id: 3, title: 'C', path: '/v/c.mkv'),
        ]);
        final provider = PlaylistProvider(repository);

        await provider.generateRandom(count: 2, launchPlayer: false);
        expect(provider.playlist, hasLength(2));

        await provider.generateRandom(count: 2, launchPlayer: false);
        // Restano solo i due gia' proposti: la seconda chiamata li esclude.
        expect(
          repository.reads.where((r) => r.startsWith('random')).last,
          'random(2, exclude: 2)',
        );
        expect(provider.playlist, hasLength(1));
      },
    );

    test('il pool esaurito azzera i proposti e riparte da capo', () async {
      final repository = FakeVideoRepository([
        buildVideo(id: 1, title: 'A', path: '/v/a.mkv'),
        buildVideo(id: 2, title: 'B', path: '/v/b.mkv'),
      ]);
      final provider = PlaylistProvider(repository);

      await provider.generateRandom(count: 2, launchPlayer: false);
      expect(provider.proposedVideoCount, 2);

      await provider.generateRandom(count: 2, launchPlayer: false);
      // Tutti i video sono gia' stati proposti: la lista si svuota e la ricerca
      // riparte senza esclusioni.
      expect(
        repository.reads.where((r) => r.startsWith('random')).last,
        'random(2, exclude: 0)',
      );
      expect(provider.playlist, hasLength(2));
    });

    test('resetProposedVideos azzera il conteggio dei proposti', () async {
      final repository = FakeVideoRepository([
        buildVideo(id: 1, title: 'A', path: '/v/a.mkv'),
      ]);
      final provider = PlaylistProvider(repository);

      await provider.generateRandom(count: 1, launchPlayer: false);
      expect(provider.proposedVideoCount, 1);

      provider.resetProposedVideos();
      expect(provider.proposedVideoCount, 0);
    });
  });

  group('PlaylistProvider - playlist recenti', () {
    test('i video più recenti vengono messi in testa', () async {
      final repository = FakeVideoRepository([
        buildVideo(id: 1, title: 'Vecchio', path: '/v/vecchio.mkv', mtime: 100),
        buildVideo(id: 2, title: 'Recente', path: '/v/recente.mkv', mtime: 900),
      ]);
      final provider = PlaylistProvider(repository);

      await provider.generateRecentPlaylist(count: 2, launchPlayer: false);

      expect(provider.playlist.first.title, 'Recente');
    });
  });

  group('PlaylistProvider - stato della playlist', () {
    test('la playlist salvata viene ricaricata dai percorsi', () async {
      final repository = FakeVideoRepository([
        buildVideo(id: 1, title: 'A', path: '/v/a.mkv'),
      ]);
      final provider = PlaylistProvider(repository);

      await provider.setPlaylist(repository.videos);
      expect(provider.lastTempPlaylistPath, isNull);

      await provider.loadPlaylistState();
      expect(provider.playlist, hasLength(1));
    });

    test('updateVideoCount allinea il totale con il repository', () async {
      final repository = FakeVideoRepository([
        buildVideo(id: 1, title: 'A', path: '/v/a.mkv'),
        buildVideo(id: 2, title: 'B', path: '/v/b.mkv'),
      ]);
      final provider = PlaylistProvider(repository);

      await provider.updateVideoCount();

      expect(provider.totalVideoCount, 2);
    });
  });

  group('PlaylistProvider - notifica ai listener', () {
    test('i listener vengono avvisati quando la playlist cambia', () async {
      final repository = FakeVideoRepository([
        buildVideo(id: 1, title: 'A', path: '/v/a.mkv'),
      ]);
      final provider = PlaylistProvider(repository);

      var notified = 0;
      provider.addListener(() => notified++);

      await provider.setPlaylist(repository.videos);

      expect(notified, greaterThan(0));
    });
  });

  test('la playlist espone una lista non modificabile dall\'esterno', () async {
    final repository = FakeVideoRepository([
      buildVideo(id: 1, title: 'A', path: '/v/a.mkv'),
    ]);
    final provider = PlaylistProvider(repository);
    await provider.setPlaylist(repository.videos);

    expect(
      () => provider.playlist.add(buildVideo(id: 9, title: 'X')),
      throwsUnsupportedError,
    );
  });

  test('i video hanno il metodo toMap usato dal comando remoto', () async {
    final video = buildVideo(id: 1, title: 'A', path: '/v/a.mkv');
    final map = video.toMap();

    expect(map['title'], 'A');
    expect(map['path'], '/v/a.mkv');
    expect(map, isA<Map<String, dynamic>>());
  });

  test('Video.copyWith mantiene i campi non indicati', () {
    final video = buildVideo(id: 1, title: 'A', path: '/v/a.mkv', rating: 7);
    final copy = video.copyWith(title: 'B');

    expect(copy.title, 'B');
    expect(copy.path, '/v/a.mkv');
    expect(copy.rating, 7);
    expect(copy, isA<Video>());
  });
}
