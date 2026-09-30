import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/services/process_runner.dart';

void main() {
  group('ProcessRunner - esito', () {
    test('un comando che termina con successo', () async {
      final outcome = await ProcessRunner.runWithTimeout('echo', const [
        'ciao',
      ]);

      expect(outcome.exitCode, 0);
      expect(outcome.timedOut, isFalse);
      expect(outcome.succeeded, isTrue);
      expect(outcome.stdout.trim(), 'ciao');
    });

    test('un comando che fallisce espone stderr come messaggio', () async {
      final outcome = await ProcessRunner.runWithTimeout('sh', const [
        '-c',
        'echo problema >&2; exit 3',
      ]);

      expect(outcome.exitCode, 3);
      expect(outcome.succeeded, isFalse);
      expect(outcome.errorMessage, 'problema');
    });

    test('il messaggio d\'errore ripiega su stdout', () async {
      final outcome = await ProcessRunner.runWithTimeout('sh', const [
        '-c',
        'echo solo_stdout; exit 1',
      ]);

      expect(outcome.errorMessage, 'solo_stdout');
    });

    test('il messaggio d\'errore resta su una riga', () async {
      final outcome = await ProcessRunner.runWithTimeout('sh', const [
        '-c',
        'printf "prima\\nseconda\\rterza"; exit 1',
      ]);

      expect(outcome.errorMessage.contains('\n'), isFalse);
      expect(outcome.errorMessage.contains('\r'), isFalse);
      expect(outcome.errorMessage, 'prima seconda terza');
    });

    test('senza output il messaggio ripiega sul codice di uscita', () async {
      final outcome = await ProcessRunner.runWithTimeout('true', const []);

      expect(outcome.succeeded, isTrue);
      expect(outcome.errorMessage, 'Exit code: 0');
    });

    test('un comando che non esiste solleva ProcessException', () async {
      await expectLater(
        ProcessRunner.runWithTimeout('comando_inesistente_xyz', const []),
        throwsA(isA<ProcessException>()),
      );
    });

    test('il timeout uccide il processo e lo segnala', () async {
      final outcome = await ProcessRunner.runWithTimeout('sleep', const [
        '5',
      ], timeout: const Duration(milliseconds: 200));

      expect(outcome.timedOut, isTrue);
      expect(outcome.succeeded, isFalse);
    });

    test(
      'onFinished viene eseguito anche quando il comando va a buon fine',
      () async {
        var called = 0;
        await ProcessRunner.runWithTimeout('echo', const [
          'ok',
        ], onFinished: () => called++);

        expect(called, 1);
      },
    );

    test('onFinished viene eseguito anche in caso di timeout', () async {
      var called = 0;
      await ProcessRunner.runWithTimeout(
        'sleep',
        const ['5'],
        timeout: const Duration(milliseconds: 200),
        onFinished: () => called++,
      );

      expect(called, 1);
    });
  });

  group('ProcessRunner - sanitize', () {
    test('i messaggi su piu\' righe diventano una riga sola', () {
      expect(
        ProcessRunner.sanitize('riga1\nriga2\r\nriga3'),
        'riga1 riga2  riga3',
      );
    });

    test('i due punti vengono sostituiti per non rompere i log', () {
      expect(ProcessRunner.sanitize('Errore: dettaglio'), 'Errore; dettaglio');
    });
  });

  group('ProcessRunner - timeout con file temporaneo', () {
    test('il file temporaneo viene rimosso dal callback', () async {
      final dir = await Directory.systemTemp.createTemp('process_runner_test');
      final tempFile = File('${dir.path}/temporaneo.txt')
        ..writeAsStringSync('x');

      await ProcessRunner.runWithTimeout('echo', const [
        'ok',
      ], onFinished: () => tempFile.delete());

      expect(tempFile.existsSync(), isFalse);
      await dir.delete(recursive: true);
    });
  });
}
