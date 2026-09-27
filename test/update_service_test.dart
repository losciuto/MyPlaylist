import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/services/github_service.dart';
import 'package:my_playlist/services/update_service.dart';

/// Server locale che serve un asset di rilascio e, opzionalmente, la sua
/// impronta SHA-256.
///
/// Il caso interessante e' quando l'asset `.sha256` **non** viene servito:
/// e' cioe' un rilascio che non pubblica l'impronta, e in quel caso
/// l'installazione automatica non deve avvenire.
class FakeReleaseServer {
  FakeReleaseServer._(this._server);

  static Future<FakeReleaseServer> start({
    required Map<String, List<int>> assets,
    required String fileName,
    String Function(String body)? hashFor,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final instance = FakeReleaseServer._(server);

    unawaited(() async {
      await for (final request in server) {
        final path = request.uri.path;
        final name = path.substring(path.lastIndexOf('/') + 1);

        // L'asset .sha256 non e' tra gli asset binari: va servito a parte,
        // altrimenti risponderebbe 404 e il servizio non troverebbe mai
        // l'impronta da confrontare.
        if (name == '$fileName$checksumSuffix') {
          final body = assets[fileName];
          if (hashFor == null || body == null) {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
            continue;
          }
          request.response.headers.contentType = ContentType.text;
          request.response.write('${hashFor(base64Encode(body))}  $fileName\n');
          await request.response.close();
          continue;
        }

        final body = assets[name];
        if (body == null) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          continue;
        }

        request.response.headers.contentType = ContentType(
          'application',
          'octet-stream',
        );
        request.response.add(body);
        await request.response.close();
      }
    }());

    instance.fileName = fileName;
    return instance;
  }

  final HttpServer _server;
  late final String fileName;

  String get assetUrl =>
      'http://${_server.address.host}:${_server.port}/$fileName';

  Future<void> stop() => _server.close(force: true);
}

/// Ignora volutamente un futuro: usato per non aspettare il loop del server.
void unawaited(Future<void> future) {}

UpdateInfo infoFor(String url, {String? assetName}) => UpdateInfo(
  version: '3.15.0',
  body: 'note',
  downloadUrl: url,
  assetName: assetName,
  fileExtension: '.AppImage',
);

void main() {
  // Il binding NON viene inizializzato di proposito: `flutter_test` installa un
  // HttpOverrides che risponde 400 a ogni richiesta, e i test hanno bisogno di
  // raggiungere il server finto in locale. La directory temporanea e' iniettata,
  // quindi path_provider non serve.

  late Directory tempDir;

  setUpAll(() async {
    // Directory temporanea reale: il servizio la riceve iniettata.
    tempDir = await Directory.systemTemp.createTemp('my_playlist_update_test');
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('UpdateService - integrita\' del download', () {
    late UpdateService service;

    setUp(() => service = UpdateService.forTesting(() async => tempDir));

    test('senza impronta pubblicata il file NON viene installato', () async {
      // Un AppImage qualsiasi, firmato da nessuno: se il servizio lo eseguisse
      // sarebbe esattamente lo scenario di esecuzione di codice arbitrario.
      final server = await FakeReleaseServer.start(
        assets: {'MyPlaylist-3.15.0-x86_64.AppImage': List.filled(64, 0x41)},
        fileName: 'MyPlaylist-3.15.0-x86_64.AppImage',
      );
      addTearDown(server.stop);

      final events = await service
          .downloadAndInstall(
            infoFor(
              server.assetUrl,
              assetName: 'MyPlaylist-3.15.0-x86_64.AppImage',
            ),
          )
          .toList();

      final esiti = events
          .whereType<UpdateEvent>()
          .where((e) => e is! DownloadProgress)
          .toList();
      expect(esiti.whereType<UpdateFinished>(), isEmpty);
      final manuale = esiti.whereType<UpdateNeedsManualAction>().singleOrNull;
      expect(manuale, isNotNull);
      expect(manuale!.message, contains('impronta'));
      // Il file resta disponibile, ma non e' stato eseguito: su Linux un
      // .AppImage verificato verrebbe lanciato da _install.
      expect(manuale.file.existsSync(), isTrue);
    });

    test(
      'impronta sbagliata: il file viene scartato e l\'errore e\' esplicito',
      () async {
        final server = await FakeReleaseServer.start(
          assets: {'MyPlaylist-3.15.0-x86_64.AppImage': List.filled(64, 0x41)},
          fileName: 'MyPlaylist-3.15.0-x86_64.AppImage',
          // 64 caratteri esadecimali, ma non l'impronta del contenuto.
          hashFor: (_) => 'f' * 64,
        );
        addTearDown(server.stop);

        Object? errore;
        try {
          await service
              .downloadAndInstall(
                infoFor(
                  server.assetUrl,
                  assetName: 'MyPlaylist-3.15.0-x86_64.AppImage',
                ),
              )
              .toList();
        } on UpdateFailure catch (e) {
          errore = e;
        }

        expect(errore, isA<UpdateFailure>());
        expect(
          (errore! as UpdateFailure).message,
          contains('non corrispondente'),
        );
      },
    );

    test('HTTP non 200 non lascia file sul disco', () async {
      final server = await FakeReleaseServer.start(
        assets: const {},
        fileName: 'MyPlaylist-3.15.0-x86_64.AppImage',
      );
      addTearDown(server.stop);

      await expectLater(
        service
            .downloadAndInstall(
              infoFor(
                server.assetUrl,
                assetName: 'MyPlaylist-3.15.0-x86_64.AppImage',
              ),
            )
            .toList(),
        throwsA(
          isA<UpdateFailure>().having(
            (e) => e.message,
            'message',
            contains('404'),
          ),
        ),
      );
    });

    test('un file .part non viene scambiato per un download completo', () async {
      // Simula un download interrotto dal giro precedente, nella stessa
      // directory in cui il servizio scarica.
      final residuo = File(
        '${tempDir.path}/MyPlaylist-3.15.0-x86_64.AppImage.part',
      );
      residuo.parent.createSync(recursive: true);
      residuo.writeAsStringSync('scarico interrotto');

      final server = await FakeReleaseServer.start(
        assets: {'MyPlaylist-3.15.0-x86_64.AppImage': List.filled(64, 0x41)},
        fileName: 'MyPlaylist-3.15.0-x86_64.AppImage',
      );
      addTearDown(server.stop);

      await service
          .downloadAndInstall(
            infoFor(
              server.assetUrl,
              assetName: 'MyPlaylist-3.15.0-x86_64.AppImage',
            ),
          )
          .toList();

      // Dopo il download il .part non deve piu' esistere: il contenuto e' stato
      // promosso al nome definitivo.
      expect(residuo.existsSync(), isFalse);
      final finale = File('${tempDir.path}/MyPlaylist-3.15.0-x86_64.AppImage');
      expect(finale.existsSync(), isTrue);
      finale.deleteSync();
    });
  });

  group('UpdateService - eventi', () {
    late UpdateService service;

    setUp(() => service = UpdateService.forTesting(() async => tempDir));

    test(
      'un esito che richiede un passo manuale non e\' un\'eccezione',
      () async {
        // La versione precedente lanciava Exception anche quando l'esito era
        // positivo ("Estratto in /tmp"), e il dialog mostrava un errore.
        final server = await FakeReleaseServer.start(
          assets: {'MyPlaylist-3.15.0.tar.gz': List.filled(32, 0x42)},
          fileName: 'MyPlaylist-3.15.0.tar.gz',
        );
        addTearDown(server.stop);

        final events = await service
            .downloadAndInstall(
              infoFor(
                server.assetUrl,
                assetName: 'MyPlaylist-3.15.0.tar.gz',
              ).copyWithExtension('.tar.gz'),
            )
            .toList();

        // Nessuna eccezione: l'esito e' un evento.
        expect(events.whereType<DownloadProgress>(), isNotEmpty);
        expect(
          events.whereType<UpdateNeedsManualAction>().singleOrNull?.message,
          contains('impronta'),
        );
      },
    );
  });
}

extension on UpdateInfo {
  UpdateInfo copyWithExtension(String ext) => UpdateInfo(
    version: version,
    body: body,
    downloadUrl: downloadUrl,
    assetName: assetName,
    fileExtension: ext,
  );
}
