# Comandi vocali offline (Vosk) — progettazione e stato

Documento di riferimento per la scheda **"Voce"** di MyPlaylist: riconoscimento
vocale in locale con Vosk, senza inviare audio a servizi esterni.

Questa e' l'**implementazione di origine**. La stessa funzionalita' e' stata
portata in VlcRemote (il telecomando), dove vive oggi il pannello dei comandi
vocali: la progettazione di quella versione e' in
`VlcRemote/docs/VOICE_COMMANDS.md`.

| | MyPlaylist | VlcRemote |
|---|---|---|
| **Dove** | scheda "Voce" (`lib/screens/voice_tab.dart`) | pannello aperto dall'AppBar (`lib/widgets/voice_panel.dart`) |
| **Interfaccia** | stringhe localizzate (it/en) con `flutter gen-l10n` | stringhe in italiano scritte a mano, come nel resto del progetto |
| **Esecuzione** | `vlc_rc_client.dart`, un client RC proprio | `VlcVoiceCommandExecutor` sul `VlcProvider` gia' presente |
| **Motore, parser, catalogo, modelli** | identici (stesso codice, portato) | identici |

---

## 1. Perche' esiste

MyPlaylist genera e avvia playlist, e controlla VLC. Le operazioni piu'
frequenti — "riproduci la playlist", "alza il volume", "ferma" — sono anche
quelle che si danno piu' spesso a voce mentre si guarda un film.

Il requisito non negoziabile e' **offline**: l'audio del microfono non deve
uscire dal dispositivo. Per questo la scelta e' Vosk, che gira in locale, e non
un servizio cloud. Il prezzo e' che il motore riconosce parole chiave
italiane e inglesi, non il linguaggio naturale.

## 2. Come funziona

```
microfono --(PCM 16k mono)--> Vosk --(testo)--> VoiceCommandParser
          --> VoiceCommand --> VlcRcClient (socket RC) --> VLC
          --> oppure: azione sulle playlist (MyPlaylist locale)
```

- Il modello Vosk ("small", italiano o inglese) viene **scaricato al primo
  uso** e tenuto nella cartella dati dell'applicazione.
- `prepareIfModelPresent()` carica il modello **senza rete** se e' gia' in
  locale: cosi' il pulsante di ascolto resta attivo senza scaricare nulla.
- Il riconoscimento lavora a **16 kHz, mono, PCM 16 bit**, il formato che
  Vosk si aspetta.
- Ogni frase trascritta viene analizzata dal parser e, se riconosciuta,
  eseguita; l'esito finisce nella cronologia.

### Stati del motore

`idle` -> `preparing` -> `ready` -> `listening`, con `error` a parte. Gli
errori tipizzati sono in `VoiceError`: `unsupportedPlatform`,
`nativeLibraryMissing`, `modelDownloadFailed`, `modelLoadFailed`,
`microphoneDenied`, `recorderUnavailable`.

## 3. Il catalogo dei comandi

| Comando | Italiano | Inglese | Numero |
|---|---|---|---|
| Volume su | "alza il volume", "volume su", "aumenta il volume" | "volume up", "louder" | — |
| Volume giu | "abbassa il volume", "volume giu" | "volume down", "quieter" | — |
| Volume a valore | "volume" + numero | "volume" + numero | obbligatorio, 0-100 |
| Playlist casuale | "playlist casuale", "genera casuale" | "random playlist", "shuffle" | facoltativo |
| Playlist recenti | "playlist recenti", "video recenti" | "recent playlist", "latest videos" | facoltativo |
| Avvia playlist | "riproduci la playlist", "avvia la playlist" | "play the playlist" | — |
| Traccia successiva | "traccia successiva", "prossima traccia" | "next track" | — |
| Traccia precedente | "traccia precedente" | "previous track" | — |
| Avanti nella traccia | "salta avanti", "avanti", "inoltra" | "skip forward" | facoltativo, default 30 s |
| Indietro nella traccia | "salta indietro", "indietro" | "skip backward" | facoltativo, default 30 s |
| Pausa | "pausa", "sospendi" | "pause" | — |
| Riprendi | "riprendi", "riproduci" | "resume", "continue" | — |
| Stop | "ferma", "ferma tutto", "chiudi vlc" | "stop", "close vlc" | — |

Il riconoscimento e' a **parole chiave**, con sinonimi, e l'ordine delle
regole conta: "volume 50" viene valutato prima di "volume su". I numeri si
cercano come cifre o come parole; in italiano i termini ambigui ("uno", "sei",
"sette", "otto", "nove") sono esclusi perche' compaiono troppo spesso nel
parlato.

## 4. L'esecuzione

`VlcRcClient` (`lib/services/voice/vlc_rc_client.dart`) parla il protocollo
RC di VLC direttamente via socket, con gestione di timeout ed errori tipizzati
(`VlcRcException`).

| Comando | Azione | Precondizione |
|---|---|---|
| play / pausa / stop | comando RC | VLC raggiungibile |
| traccia successiva / precedente | comando RC | VLC raggiungibile |
| volume su/giu/valore | comando RC con percentuale | VLC raggiungibile |
| spostamento nella traccia | `seek` **assoluto**, calcolato dalla posizione corrente | VLC raggiungibile e durata nota |
| playlist casuale / recenti / avvio | azione sulle playlist di MyPlaylist | sempre disponibile (server locale) |

Lo spostamento e' l'unico caso non banale: il comando RC `seek` e' assoluto,
quindi la posizione di partenza si legge dallo stato corrente e si somma il
numero di secondi richiesto.

## 5. Integrazione nativa

| Piattaforma | Stato | Note |
|---|---|---|
| Linux | funzionante | `libvosk.so` accanto all'eseguibile; il percorso e' indicato al plugin prima che parta la VM Dart |
| Android | funzionante | il plugin porta con se' `libvosk.so` per ogni ABI; serve `RECORD_AUDIO` |
| Windows | supportata | il pacchetto fornisce la DLL |
| macOS | non supportata | il plugin non espone l'interfaccia nativa |

Il pacchetto usato e' `vosk_flutter_fixed` (0.1.4) e non
`vosk_flutter_service`: quest'ultimo usa ancora il vecchio nome del plugin
nel CMake e nella CLI di installazione, quindi la build Linux fallisce.
`record` e' fermo alla 6.x, perche' la 7.x richiede Dart 3.12.

## 6. Permessi e privacy

- **Android**: `RECORD_AUDIO`, con `<uses-feature android:name="android.hardware.microphone" android:required="false" />`,
  cosi' l'app resta installabile su dispositivi senza microfono.
- **L'audio non lascia il dispositivo**: la trascrizione e' locale. L'unica
  rete usata e' il download del modello, al primo uso.

## 7. Impostazioni

Due chiavi in `SettingsService`: `voice_language` (default `it`) e
`voice_input_device`. L'id del microfono viene normalizzato: il backend
PulseAudio restituisce i valori tra virgolette (`"alsa_input..."`), e senza
pulirli la scelta non combacia piu' con quella salvata. Se il microfono salvato
non e' piu' presente, si torna al predefinito e la chiave viene rimossa.

## 8. Limiti noti

- **macOS non e' supportato** (manca l'interfaccia nativa del plugin).
- Riconoscimento a **parole chiave**, non a linguaggio naturale.
- Il modello "small" e' piu' leggero ma meno accurato di uno "large".
- La cronologia tiene **50 voci** e non viene salvata fra le sessioni.

## 9. Stato del lavoro

- [x] Motore vocale offline in `lib/services/voice/`.
- [x] Parser e catalogo dei comandi, italiano e inglese.
- [x] Client RC in `lib/services/voice/vlc_rc_client.dart`.
- [x] Scheda "Voce" in `lib/screens/voice_tab.dart`, con stringhe localizzate
      in italiano e inglese.
- [x] Impostazioni di lingua e microfono.
- [x] Integrazione nativa Linux e permessi Android.
- [x] **Porting in VlcRemote**: pannello nell'AppBar, esecutore sul
      `VlcProvider`, test di integrazione reale. Progettazione in
      `VlcRemote/docs/VOICE_COMMANDS.md`.
- [ ] macOS: serve un plugin dedicato.
- [ ] Il catalogo dei comandi e' fisso: va allargato a mano quando serve.

## 10. Rollback

La funzionalita' e' **additiva** e non tocca il protocollo di controllo
remoto: le regole di compatibilita' C1-C13 sono in
`VlcRemote/docs/REFACTORING_TODO.md` (sezione 0), e il lato server e'
`lib/services/remote_control_service.dart`. Per tornare indietro basta
rimuovere i file e ripristinare i file modificati.

```bash
git checkout -- lib/main.dart lib/screens/home_screen.dart \
                lib/services/settings_service.dart \
                android/app/src/main/AndroidManifest.xml \
                pubspec.yaml pubspec.lock
rm -rf lib/services/voice lib/screens/voice_tab.dart
flutter pub get
```
