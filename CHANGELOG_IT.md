# Changelog

All notable changes to this project will be documented in this file.
 
## [3.12.1] - 29/03/2026

### Aggiunte
- **Progresso Scansione in Tempo Reale**: La scheda di scansione ora mostra il nome del file o della cartella attualmente in fase di elaborazione.

### Modifiche
- **Ottimizzazione Scansione Intelligente**: Notevole aumento delle prestazioni durante la ri-scansione. L'app ora salta i video che hanno già sia una locandina che un voto nel database.
- **Sincronizzazione Migliorata**: Integrata la lista delle "Rinomine Fallite" nel processo di scansione. I file che sono stati saltati nella fase di rinomina manuale vengono ora esclusi automaticamente dagli aggiornamenti dei metadati.
- **Sistema di Update Moderno**: Integrato `package_info_plus` per un rilevamento più preciso della versione e ridisegnato il dialogo di aggiornamento con un look Material 3 premium.

## [3.12.0] - 28/03/2026

### Aggiunte
- **Sincronizzazione Metadati in Massa**: Nuova funzione per allineare rapidamente i record del database con i file fisici, preservando l'integrità dei dati durante i processi di rinomina esterna o spostamento file.
- **Supporto Locandine VLC**: Aggiunto un server HTTP integrato (attivo in background sulla porta successiva) per trasmettere in tempo reale le locandine dei film alla companion app VlcRemote, senza appesantire il parsing base.

## [3.10.0] - 27/03/2026

### Novità
- **Integrazione VlcRemote**: Pieno supporto alla comunicazione bidirezionale con l'applicazione client dedicata.
- **Comando Kill VLC**: Implementato il comando remoto `kill_vlc` per terminare istantaneamente il player via socket.
- **Configurazione Default**: Abilitata l'attivazione automatica del server remoto all'avvio su porta 8080.
- **Allineamento Porte**: Porta di controllo VLC RC portata a 4242 per compatibilità standard con l'ecosistema VlcRemote.

## [3.9.8] - 22/03/2026

### Correzioni
- **Layout UI**: Risolti i problemi di visibilità con la colonna delle azioni nella schermata di gestione del database e con il pulsante "Salva nel DB" nel dialogo di selezione della locandina.

## [3.9.7] - 18/03/2026

### Modifiche
- **Database**: L'operazione di Rinomina in Massa ora processa i video dinamicamente seguendo l'ordine di 'Priorità' (i più recenti per primi).

 ## [3.9.6] - 18/03/2026
 
 ### Correzioni
 - **Test**: Sostituito il test del contatore predefinito con uno smoke test valido per MyPlaylist.
 - **Stile**: Formattazione del codice eseguita tramite `dart format`.

## [3.9.5] - 2026-03-17

### Correzioni
- **Android Build**: Downgrade AGP a 8.10.1 (o 8.7.3) per risolvere problemi di compatibilità e reperibilità dei plugin.
- **Gradle**: Passaggio alla distribuzione `all` di Gradle 8.10.2 per supporto completo alle feature di build.

## [3.9.4] - 2026-03-17

### Changed
- **Android Build**: Aggiornamento AGP a 8.10.2 e Kotlin a 2.0.21 per compatibilità dipendenze.

## [3.9.3] - 2026-03-17

### Correzioni
- **Android Build**: Rimosso path Java hardcoded per migliorare la portabilità della build.

## [3.9.2] - 2026-03-17

### Changed
- **Maintenance**: Incremento versione per allineamento release.

## [3.9.1] - 2026-03-16

### Changed
- **Cross-Platform**: Allineato l'ecosistema del player e la manipolazione dei file system per supportare pienamente sia Linux sia macchine host Windows.
- **Refactoring**: Sostituiti path strings hardcoded con estensioni sicure multipiattaforma garantite dalla libreria `path` (`p.join`, `p.isAbsolute`).
- **Gestione Processi**: Estesa chiusura VLC selettiva per Windows (`taskkill`) e fallbacks per apertura directory root tramite file manager OS nativo.


## [3.9.0] - 09/03/2026

### Novità
- **Riorganizzazione Navigazione**: Introdotta la scheda "Servizio" che raggruppa Scansione, Gestione DB, Priorità e Statistiche per un'interfaccia più pulita.
- **Ricerca in Priorità**: Aggiunta barra di ricerca nella scheda Priorità per filtrare i video per titolo, regista o attore.
- **Spostamento Manutenzione**: Le funzioni di Backup e Ripristino sono ora accessibili direttamente nella scheda Servizio.
- **Ottimizzazione UI**: Ordine delle schede ottimizzato con "Scansione" al primo posto nel gruppo Servizio per facilitare l'importazione iniziale.

## [3.8.0] - 07/03/2026

### Novità
- **Sezione Gestione Priorità**: Nuovo tab "Priorità" per gestire i video in base alla data effettiva di inserimento.
- **Modifica Granulare Ora/Data**: Separazione di data e ora nel dialogo di modifica per un controllo preciso dell'ordinamento.
- **Sincronizzazione Date Massiva**: Nuova funzione "Sincronizza Date" nel tab Priorità per allineare il database con le date dei file.

### Correzioni
- **Bug Anno Incoerente**: Risolto il problema dell'anno 58150 causato da errori di conversione nel database.
- **Cattura Date Affidabile**: Le scansioni ora utilizzano la data di modifica reale del file come data di inserimento predefinita.

## [3.7.0] - 07/03/2026

### Novità
- **Ordinamento Persistente "Più Recenti"**: Introdotta la colonna `date_added` nel database. La playlist "Più Recenti" ora si basa sulla data effettiva di aggiunta del video alla libreria anziché sulla data di modifica del file. Questo evita che la modifica dei metadati sposti i video in cima alla lista.
- **Migrazione Automatica**: Al primo avvio, i video esistenti vengono migrati preservando l'ordine cronologico attuale.

## [3.6.5] - 03/03/2026

### Correzioni
- **Log Rinomina**: Migliorata la gestione degli errori durante le operazioni di rinomina in massa. Gli errori durante l'aggiornamento dei metadati (FFmpeg) vengono ora registrati correttamente nella tabella del database "Errori Rinomina".
- **Log di Debug Dettagliati**: Aggiunto logging dettagliato per i file saltati durante la rinomina per identificare i motivi dello stato "già sincronizzato".

## [3.6.4] - 28/02/2026

## [3.6.2] - 08/02/2026

### Correzioni
- **Parsing Rating**: Risolto un bug critico nel parser NFO che ignorava il rating corretto se il campo `<userrating>` era presente ma impostato a zero (comune in file generati da TinyMediaManager/Kodi). Ora viene data priorità corretta ai valori nel blocco `<ratings>`.

## [3.6.1] - 08/02/2026

### Correzioni
- **Robustezza UI**: Aggiunti controlli di sicurezza per prevenire i crash "unmounted context" quando si chiudono dialoghi o si cambiano tab durante operazioni asincrone.
- **Aggiornamento Metadati Resiliente**: Implementata una strategia di fallback per FFmpeg: se il salvataggio completo fallisce (es. per sottotitoli corrotti), l'app riprova automaticamente preservando solo video e audio, garantendo il successo del salvataggio dei metadati.
- **Mappatura Migliorata**: Aggiunti `-map 0` e `-ignore_unknown` per preservare tutte le tracce nei file MKV complessi per impostazione predefinita.

## [3.6.0] - 2026-02-08

### Novità
- **Sincronizzazione Bidirezionale NFO**: Sincronizzazione in tempo reale tra il database dell'app e i file `.nfo` locali.
- **Auto-Sync Metadati**: Nuova impostazione per aggiornare automaticamente i file NFO su disco quando i metadati (voto, generi, ecc.) vengono modificati nell'app.
- **Controllo NFO Manuale**: Aggiunti pulsanti "Salva su NFO" e "Ricarica da NFO" nei dialoghi Dettagli e Modifica.
- **Slider Voto**: Integrato uno slider interattivo per una regolazione precisa del voto/rating nelle finestre info.
- **Pulsante Pulisci Ricerca**: Aggiunta una "X" nel campo di ricerca per svuotare rapidamente il testo e resettare i filtri.
- **Log Errori Avanzati**: Integrazione del logger per catturare i fallimenti di FFmpeg durante l'aggiornamento dei metadati, inclusi gli errori stderr.

### Ottimizzazioni
- **Motore Turbo-Scan**: Incremento significativo delle prestazioni durante la scansione delle collezioni.
    - **Elaborazione Parallela**: Le foto di attori e registi vengono verificate e scaricate simultaneamente.
    - **Concorrenza Directory**: Elaborazione multi-thread dei contenuti delle cartelle.
    - **Batch Database**: I record dei video vengono salvati in blocchi (batch) per minimizzare l'overhead di scrittura su disco.
- **Estrazione Metadati Bulk**: Perfezionato il servizio TMDB per estrarre le miniature dei partecipanti anche durante le operazioni di massa.

## [3.5.1] - 2026-02-08

### Novità
- **Foto Registi e Attori**: Estrazione e visualizzazione delle miniature per cast e regia dai file NFO.
- **Avatar Interattivi**: Clicca sulle foto per vedere un ingrandimento con animazione Hero.
- **Scorrimento Migliorato**: Abilitato lo scorrimento tramite trascinamento mouse e aggiunte scrollbar visibili per una migliore navigazione su desktop.
- **Supporto Miniature Locali**: Supporto per percorsi relativi e cartelle locali `.actors` nelle directory della collezione.

### Correzioni
- **Parsing NFO**: Risolto un bug per cui le foto dei registi potevano essere scambiate per la locandina principale del film.

## [3.4.0] - 2026-01-21

### Novità
- **Auto-Sync**: Watcher in background per rilevare automaticamente nuovi video e sincronizzarli nel database. Include la gestione delle cartelle monitorate nelle Impostazioni.
- **Integrazione Fanart.tv**: Scaricamento automatico di Loghi, ClearArt e DiscArt ad alta qualità.
- **Virtualizzazione Tabella**: Drastico miglioramento delle prestazioni per collezioni numerose grazie all'uso di `ListView.builder`.
- **Firma Digitale Linux**: Supporto GPG nel workflow di rilascio CI/CD.

### Correzioni
- **Finestra Modifica**: Risolti crash di layout ("render box no size") e migliorata la risposta dell'interfaccia di editing.
- **Layout Critico**: Risolto problema di altezza infinita con widget `Expanded` all'interno di viste a scorrimento.



### Aggiunto
- **Gestione Serie TV**: Implementata la gestione delle cartelle serie. Le cartelle contenenti "Serie", "Series", "Seriale", "TV Show" o un file `tvshow.nfo` vengono ora trattate come un'unica entità nel database.
    - **Generazione NFO**: Supporto per la creazione di `tvshow.nfo` e download di asset standard (`poster.jpg`, `fanart.jpg`, `clearlogo.png`) per le serie.
    - **Sincronizzazione Metadati Ricorsiva**: La rinomina e l'aggiornamento metadati ora si propagano a tutti gli episodi nella cartella della serie.
    - **Titoli Episodi Intelligenti**: Formattazione automatica (es. "Serie - S01E01 Titolo Episodio") con pulizia dei tag di release.
    - **Propagazione Trama**: La trama della serie viene scritta automaticamente nei metadati di ogni singolo episodio.
- **UI Potenziata**:
    - **Selezione Manuale Uniforme**: Lista resa coerente; i dettagli della serie e la selezione degli episodi sono ora integrati nel Dialog di Anteprima standard.
    - **Badge Serie**: Indicatori visivi (icona TV e badge) nella gestione DB, griglia poster e dialog di selezione.
- **Operazioni Bulk per Serie**: Estesa la rinomina dei titoli e la generazione NFO per supportare i contenuti televisivi.
- **Schema Database v2**: Aggiornato il database per supportare il nuovo tipo "Serie" con migrazione automatica.

## [2.9.0] - 2026-01-02

### Aggiunto
- **Elimina Riga Video**: Aggiunto pulsante di eliminazione nella scheda Gestione Database per rimuovere singoli record video dal database.
- **Filtro Generazione NFO**: Nuova opzione "Genera solo se manca il file .nfo" nel dialog di generazione bulk NFO per evitare di sovrascrivere metadati esistenti.

## [2.8.0] - 2025-12-31

### Aggiunto
- **Filtri di Esclusione**: Implementata selezione tri-state (Includi/Escludi/Nessuno) nel dialog dei filtri per generi, anni, attori e registi.
- **Logica di Esclusione SQL**: Aggiornate le query del database per supportare il matching negativo nella generazione delle playlist.
- **UI Migliorata per Filtri**: Widget custom per il toggle tri-state per una migliore esperienza utente nei filtri avanzati.


## [2.7.0] - 2025-12-23

### Aggiunto
- **Power Parser per Rating**: Implementata strategia duale (XML DOM + Regex) per l'estrazione dei voti dai file NFO.
- **Fallback Nome NFO**: Aggiunto supporto per `movie.nfo` quando i file NFO specifici del video non vengono trovati.
- **Visibilità Rating**: Aggiunta visualizzazione del rating nella tabella Gestione Database, Griglia Poster e Dialog Selezione Manuale.

### Corretto
- **Bug Rating Zero**: Risolto problema per cui tutti i video mostravano rating 0.0 nonostante avessero dati validi nei file NFO.
- **Supporto Tag Annidati**: Migliorato il parser per gestire strutture complesse Kodi-style `<ratings>` con attributi `default="true"`.

## [2.6.1] - 2025-12-21

- Aggiornamento documentazione e sincronizzazione versioni.

### Aggiunto
- **Protocollo Remote Control "Echo-Safe"**: Implementato mutuo-esclusione e filtraggio echi nel server di controllo per una comunicazione client-server senza interferenze.
- **Anteprima Playlist**: Nuovo comando remoto (`preview`) che permette ai client di ricevere la lista dei titoli generati senza avviare immediatamente il player.
- **Gestione Avanzata VLC**: Ottimizzata la gestione dei processi VLC per un avvio e una chiusura più affidabili.

## [2.5.1] - 2025-12-20

### Aggiunto
- **Esclusione Sessione**: La generazione di playlist casuali (anche con filtri) ora esclude i video già proposti durante la sessione corrente.
- **UI Advanced**: Tooltip sui titoli lunghi e visualizzazione del video in elaborazione durante la rinomina.
- **Gestione Serie**: Riconoscimento automatico delle cartelle serie TV (basato su nomi come "Serie", "Series", "Seriale" o file `tvshow.nfo`) per la riproduzione in sequenza.
- **Visualizzazione Titolo in Elaborazione**: Il dialog di rinomina in massa ora mostra il titolo del video che sta venendo processato in tempo reale.
- **Tooltip**: Aggiunti tooltip nella tabella del database per visualizzare il titolo completo dei video troncati.

### Corretto
- Perfezionata la logica di skip nella rinomina per essere totalmente case-insensitive.

## [2.5.0] - 2025-12-20

### Aggiunto
- Funzionalità "Rinomina Titoli in Massa" nel tab Gestione DB.
- Dialog di progresso dettagliato per le operazioni bulk.
- Possibilità di annullare la rinomina in massa con pulizia automatica dei file temporanei.
- Supporto per la chiusura automatica dei processi VLC precedenti alla riproduzione.
- Info Dialog con versione e data di redazione.

### Migliorato
- Ottimizzazione drastica delle prestazioni per l'aggiornamento del database (refresh della UI solo a fine processo).
- Logica di salto (skip) intelligente per la rinomina: i video già aggiornati correttamente vengono saltati automaticamente.
- Gestione metadati NFO: recupero più robusto di titolo, anno, generi, attori, registi e trama.
- Navigazione iniziale: l'app si apre ora sul tab 'Genera Playlist' se sono presenti video nel database.
Autore: Massimo
Ultimo Aggiornamento: 22/03/2026 (v3.9.8)

### Corretto
- Risolto bug nella logica di confronto titoli che causava aggiornamenti non necessari anche su file già corretti.
- Gestione dei codec nel player interno: migliorata la stabilità e aggiunto suggerimento per player esterni in caso di incompatibilità.

## [1.1.0] - 2025-12-14
- Versione iniziale stabile con supporto Database e Generazione Playlist.
