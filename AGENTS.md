# MyPlaylist — Regole di progetto

## Stato del progetto
- Il progetto è considerato **a buon punto**: le funzionalità presenti sono consolidate e non vanno più modificate né cambiate.
- **Non modificare, rifattorizzare, rimuovere o stravolgere** alcuna funzionalità esistente, anche se contiene bug, refusi o sembra migliorabile.
- Se un difetto o un limite emerge, **suggerisci la soluzione e attendi il mio consenso esplicito** prima di toccare il codice.
- Il consenso vale solo per lo intervento descritto: non si estende automaticamente ad altri interventi.

## Regole operative
1. **Lingua italiana** — tutte le manifestazioni (risposte, commenti, commit, changelog, documentazione) vanno in italiano.
2. **Report di fine lavoro** — a ogni lavoro concluso va consegnato un report sintetico: cosa è stato fatto, cosa è stato modificato, verifiche eseguite e cosa resta aperto.
3. **Consenso esplicito** — nessuna modifica a funzionalità esistente senza il mio consenso esplicito. Lavori non richiesti vanno evitati; in caso di dubbio si chiede.
4. **Scope minimo** — intervenire solo su quanto richiesto; niente refactoring estranei, niente pulizie opportunistiche, niente cambi di stile non richiesti.
5. **Verifica** — dopo ogni modifica eseguire `flutter analyze` e `flutter test`, e la build della piattaforma interessata quando l'intervento tocca codice applicativo.
6. **Tracciamento progressi** — tenere traccia in file di stato (regole, cosa è da fare, cosa è già fatto) aggiornati all'inizio e alla fine della sessione.

## Riferimenti tecnici
- App Flutter con Drift/SQLite: `lib/database/app_database.dart` (schema version 6, `getValuesWithCounts` con CTE ricorsiva).
- Versione e data mostrate nella finestra Info: `lib/config/app_config.dart`.
- Versione pacchetti: `pubspec.yaml`, `linux/packaging/deb/make_config.yaml`, `windows/installer_script.iss`.
- Documentazione versione: `README.md`, `README_IT.md`, `README_EN.md`, `CHANGELOG.md`, `CHANGELOG_IT.md`, `RELEASE_NOTES.md`.
- Comandi vocali offline: `docs/VOICE_COMMANDS.md` (progettazione, stato, rollback). Il motore, il parser e il catalogo sono condivisi con VlcRemote, che ha la stessa feature: modifiche ai due lati vanno tenute allineate. In VlcRemote la progettazione e' in `VlcRemote/docs/VOICE_COMMANDS.md`.
- CI: `test.yml` gira da solo su push/PR verso `main`; `release.yml` e `publish-precompiled.yml` partono solo con tag `v*` (o `workflow_dispatch`); `build-android.yml` è solo manuale.
- Release pubblicata su GitHub: `https://github.com/losciuto/MyPlaylist` (branch `main`, tag `vX.Y.Z`).

## Coordinamento con VlcRemote
- Il protocollo di controllo remoto è **condiviso**: qualunque modifica al
  pacchetto o ai comandi va applicata ai due lati. Le regole di compatibilità
  C1-C13 sono in `VlcRemote/docs/REFACTORING_TODO.md` (sezione 0) e il lato
  server è `lib/services/remote_control_service.dart`.
- I comandi vocali sono una feature **spezzata sui due progetti**: qui la
  scheda "Voce" con stringhe localizzate, in VlcRemote il pannello nell'AppBar
  con stringhe in italiano. Motore, parser e catalogo sono lo stesso codice:
  se ne cambia uno, va cambiato anche l'altro.

Stato feature comandi vocali (sessione 2026-10-21):

- MyPlaylist: implementato su branch `feat/comandi-vocali` con scheda `VoiceTab`
  (l10n IT/EN), `lib/services/voice/`, `lib/screens/voice_tab.dart`. Trigger
  abbreviati (IT/EN) in `lib/services/voice/voice_command_parser.dart`:
  volume / alza / abbassa / casuale / recenti / avvia / successiva /
  precedente / avanti / indietro / pausa / continua / stop (IT) e volume /
  up / down / random / shuffle / recent / latest / start / next / previous /
  forward / backward / pause / resume / stop (EN).
- VlcRemote: implementato su branch `feat/comandi-vocali` con pannello
  `voice_panel.dart` (stringhe hardcoded IT), fix JNA Android 16
  (`build.gradle.kts`, `MainActivity.kt`, `voice_command_service.dart`).
  Stessi trigger abbreviati del parser condiviso.
- Modifiche non committate su entrambi i branch (in attesa di richiesta esplicita).
- Verifiche MyPlaylist: `flutter analyze` OK, `flutter test` OK (195 passati),
  `flutter build linux --release` OK.
- Verifiche VlcRemote: `flutter analyze` OK, `flutter test` OK (244 passati),
  `flutter build linux --release` OK, `flutter build apk --release` OK,
  test su telefono fisico OK (nessun crash JNA, microfono attivo).
