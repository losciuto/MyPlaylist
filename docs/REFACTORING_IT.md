# Documento di Refactoring e Architettura

Questo documento descrive le principali scelte tecniche e i miglioramenti architetturali apportati alla versione 2.5.0 di MyPlaylist.

## 1. Ottimizzazione delle Prestazioni (Bulk Operations)

Uno dei problemi principali riscontrati nelle versioni precedenti era l'estrema lentezza durante la rinomina in massa dei titoli.

### Problema:
Ogni chiamata a `updateVideo` tramite il `DatabaseProvider` scatenava un `notifyListeners()`, che a sua volta forzava la `DataTable` a ricaricare l'intera lista dal database e il framework Flutter a ricostruire l'intero albero dei widget 160+ volte in pochi secondi.

### Soluzione:
Abbiamo separato la logica di aggiornamento dei dati dalla logica di notifica della UI:
- Durante il loop di rinomina, il codice interagisce direttamente con `DatabaseHelper.instance` (persistence layer).
- La UI viene aggiornata tramite un `ValueNotifier<int>` leggero che gestisce solo la barra di progresso.
- Un singolo `refreshVideos()` viene chiamato al termine dell'intero loop, riducendo i cicli di rebuild da N a 1.

## 2. Robustezza della Rinomina (Skip Logic)

Per rendere la funzione "Rinomina Titoli" utilizzabile quotidianamente senza sprechi di tempo, abbiamo implementato un sistema di verifica preventiva.

- **Normalizzazione**: I titoli vengono confrontati dopo aver applicato `.trim()` e `.toLowerCase()`.
- **Integrità NFO**: Se il file NFO non contiene un titolo valido, il file viene saltato invece di tentare ridenominazioni fallaci.
- **Atomicità**: FFmpeg scrive i nuovi metadati in un file temporaneo; l'originale viene sostituito solo se l'operazione ha successo. In caso di errore, l'originale viene ripristinato.

## 3. Gestione del Player Esterno (VLC)

L'integrazione con VLC è stata potenziata per offrire un'esperienza simile a quella di un telecomando fisico.
- **Process Management**: Prima di avviare una nuova riproduzione, l'app identifica e termina eventuali istanze di VLC precedentemente aperte per evitare sovrapposizioni audio/video.
- **Remote Control**: VLC viene avviato con i parametri `--rc-host` per permettere l'interazione via TCP (supportata da moduli futuri).

## 4. UI/UX Dinamica

- **Auto-Navigation**: Invece di richiedere all'utente di selezionare manualmente il tab, la `HomeScreen` interroga il database all'avvio e posiziona il cursore sul tab più utile (Genera Playlist se i dati esistono, Scansione se il database è vuoto).
- **Feedback Operativo**: Introduzione di dialog di riepilogo post-operazione che indicano chiaramente quanti file sono stati aggiornati, quanti saltati e quanti sono andati in errore.

## 5. Esclusione Video in Sessione

Per migliorare l'esperienza di scoperta, abbiamo introdotto la `Set<int> _proposedVideoIds` nel `PlaylistProvider`.
- **Persistenza in memoria**: Gli ID dei video aggiunti a una playlist vengono memorizzati per l'intera durata dell'esecuzione del programma.
- **Iniezione SQL**: Le query di `DatabaseHelper` (getRandom e getFiltered) accettano ora un parametro `excludeIds` che viene iniettato come clausola `NOT IN (...)` nella query SQL, garantendo che i video già visti non vengano riproposti fino al riavvio o all'esaurimento del pool.
- **Auto-Reset**: Se il numero di video proposti eguaglia o supera il numero totale di video nel database, la memoria viene azzerata per permettere un nuovo ciclo di visione completo.

## 6. Comandi Vocali Offline (Vosk)

La scheda "Voce" permette di controllare la riproduzione con la voce. Il
riconoscimento e' **in locale** (Vosk): l'audio del microfono non lascia mai il
dispositivo, e l'unica rete usata e' il download del modello, al primo uso.

- **Motore**: `lib/services/voice/voice_command_service.dart` gestisce modello,
  cattura audio e riconoscimento; il modello Vosk "small" (italiano o inglese)
  viene scaricato una volta sola e conservato nella cartella dati.
- **Parser**: `lib/services/voice/voice_command_parser.dart` traduce la frase
  trascritta in un comando, con parole chiave e sinonimi, in italiano e
  inglese. I numeri si leggono come cifre o come parole.
- **Esecuzione**: `lib/services/voice/vlc_rc_client.dart` parla il protocollo
  RC di VLC via socket, con timeout ed errori tipizzati; le azioni sulle
  playlist restano locali.
- **UI**: `lib/screens/voice_tab.dart` mostra stato del motore, modello,
  lingua, microfono, livello audio in ingresso e cronologia dei comandi. Le
  stringhe sono localizzate in italiano e inglese.
- **Integrazione nativa**: su Linux il percorso di `libvosk.so` viene
  indicato al plugin prima che parta la VM Dart; su Android il permesso
  `RECORD_AUDIO` e' dichiarato come facoltativo, cosi' l'app resta
  installabile su dispositivi senza microfono.

La stessa funzionalita' e' stata portata in **VlcRemote**, dove vive il
telecomando: li il pannello e' aperto dall'AppBar e l'esecuzione passa dal
`VlcProvider` invece che da un client RC proprio. La progettazione completa,
con catalogo dei comandi, limiti e rollback, e' in `docs/VOICE_COMMANDS.md` e
in `VlcRemote/docs/VOICE_COMMANDS.md`.
