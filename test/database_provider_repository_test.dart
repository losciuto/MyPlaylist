import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/providers/database_provider.dart';
import 'package:my_playlist/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_video_repository.dart';

void main() {
  late FakeVideoRepository repository;
  late DatabaseProvider provider;

  setUp(() async {
    // clearDatabase azzera anche le preferenze, quindi il servizio deve
    // essere inizializzato.
    SharedPreferences.setMockInitialValues({});
    await SettingsService().init();
    repository = FakeVideoRepository();
    provider = DatabaseProvider(repository);
  });

  group('DatabaseProvider - caricamento', () {
    test('refreshVideos carica i video e azzera il caricamento', () async {
      repository.videos.addAll([
        buildVideo(id: 1, title: 'Primo', path: '/v/primo.mkv'),
        buildVideo(id: 2, title: 'Secondo', path: '/v/secondo.mkv'),
      ]);

      await provider.refreshVideos();

      expect(provider.videos, hasLength(2));
      expect(provider.filteredVideos, hasLength(2));
      expect(provider.isLoading, isFalse);
    });

    test('i listener vengono avvisati durante il caricamento', () async {
      var notify = 0;
      provider.addListener(() => notify++);

      await provider.refreshVideos();

      // Segnala l'inizio e la fine del caricamento.
      expect(notify, greaterThanOrEqualTo(2));
    });

    test('il conteggio dei fallimenti arriva dal repository', () async {
      repository.failedRenames.add(
        const FailedRenameEntry('/v/a.mkv', 'errore'),
      );

      await provider.refreshVideos();

      expect(provider.failedRenamesCount, 1);
    });

    test('refreshFailedRenamesCount aggiorna solo il contatore', () async {
      await provider.refreshVideos();
      await repository.insertFailedRename('/v/b.mkv', 'errore');

      await provider.refreshFailedRenamesCount();

      expect(provider.failedRenamesCount, 1);
      expect(provider.videos, isEmpty);
    });
  });

  group('DatabaseProvider - filtro e ordinamento', () {
    setUp(() {
      repository.videos.addAll([
        buildVideo(id: 1, title: 'Zeta', path: '/v/zeta.mkv', year: '2001'),
        buildVideo(id: 2, title: 'Alpha', path: '/v/alpha.mkv', year: '2020'),
        buildVideo(id: 3, title: 'Mid', path: '/v/mid.mkv', year: '2010'),
      ]);
    });

    test('filterVideos restringe per titolo', () async {
      await provider.refreshVideos();

      provider.filterVideos('alp');

      expect(provider.filteredVideos, hasLength(1));
      expect(provider.filteredVideos.single.title, 'Alpha');
      expect(provider.searchQuery, 'alp');
    });

    test('un filtro vuoto restituisce tutti i video', () async {
      await provider.refreshVideos();

      provider.filterVideos('alp');
      provider.filterVideos('');

      expect(provider.filteredVideos, hasLength(3));
    });

    test('filterByPerson cerca tra attori e registi', () async {
      repository.videos.add(
        buildVideo(
          id: 4,
          title: 'Con persona',
          path: '/v/persona.mkv',
          actors: 'Mario Rossi, Luca Verdi',
        ),
      );
      await provider.refreshVideos();

      // Il provider confronta il nome per intero, attori e registi.
      provider.filterByPerson('mario rossi');

      expect(provider.filteredVideos, hasLength(1));
      expect(provider.filteredVideos.single.title, 'Con persona');
      // Il provider porta l'utente alla scheda del database.
      expect(provider.currentTabIndex, 1);
      expect(provider.currentServiceTabIndex, 1);
    });

    test('filterByPerson con un nome assente non lascia nulla', () async {
      await provider.refreshVideos();

      provider.filterByPerson('nessuno');

      expect(provider.filteredVideos, isEmpty);
    });

    test('sort riordina in base al criterio scelto', () async {
      await provider.refreshVideos();

      provider.sort(0, true);
      final perTitolo = provider.filteredVideos.map((v) => v.title).toList();
      expect(perTitolo, ['Alpha', 'Mid', 'Zeta']);

      provider.sort(0, false);
      final inverso = provider.filteredVideos.map((v) => v.title).toList();
      expect(inverso, ['Zeta', 'Mid', 'Alpha']);
      expect(provider.sortAscending, isFalse);
    });

    test('setSortedVideos sostituisce l\'elenco filtrato', () async {
      await provider.refreshVideos();

      provider.setSortedVideos([repository.videos.first]);

      expect(provider.filteredVideos, hasLength(1));
      expect(provider.filteredVideos.single.title, 'Zeta');
    });
  });

  group('DatabaseProvider - tab e stato', () {
    test('gli indici delle tab vengono memorizzati', () {
      provider.setTabIndex(1);
      provider.setServiceTabIndex(2);

      expect(provider.currentTabIndex, 1);
      expect(provider.currentServiceTabIndex, 2);
    });
  });

  group('DatabaseProvider - modifica dei dati', () {
    test('updateVideo scrive nel repository e ricarica', () async {
      final video = buildVideo(id: 1, title: 'Vecchio', path: '/v/a.mkv');
      repository.videos.add(video);
      await provider.refreshVideos();

      await provider.updateVideo(video.copyWith(title: 'Nuovo'));

      expect(repository.videos.single.title, 'Nuovo');
      expect(provider.videos.single.title, 'Nuovo');
    });

    test('deleteVideo rimuove dal repository e ricarica', () async {
      final video = buildVideo(id: 1, title: 'Da eliminare', path: '/v/a.mkv');
      repository.videos.add(video);
      await provider.refreshVideos();

      await provider.deleteVideo(video);

      expect(repository.videos, isEmpty);
      expect(provider.videos, isEmpty);
    });

    test('deleteVideo con id nullo non fa nulla', () async {
      final video = buildVideo(title: 'Senza id', path: '/v/b.mkv');
      repository.videos.add(video);
      await provider.refreshVideos();

      await provider.deleteVideo(video);

      expect(repository.videos, hasLength(1));
    });

    test('clearDatabase svuota il repository e ricarica', () async {
      repository.videos.add(buildVideo(id: 1, title: 'A', path: '/v/a.mkv'));
      await provider.refreshVideos();

      await provider.clearDatabase();

      expect(repository.videos, isEmpty);
      expect(provider.videos, isEmpty);
    });
  });
}
