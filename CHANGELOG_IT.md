# Changelog

Tutti i cambiamenti significativi a questo progetto saranno documentati in questo file.

## [3.6.0] - 2026-02-08

### Novità
- **Sincronizzazione Bidirezionale NFO**: Sincronizzazione in tempo reale tra il database dell'app e i file `.nfo` locali.
- **Auto-Sync Metadati**: Nuova impostazione per aggiornare automaticamente i file NFO su disco quando i metadati (voto, generi, ecc.) vengono modificati nell'app.
- **Controllo NFO Manuale**: Aggiunti pulsanti "Salva su NFO" e "Ricarica da NFO" nei dialoghi Dettagli e Modifica.
- **Slider Voto**: Integrato uno slider interattivo per una regolazione precisa del voto/rating nelle finestre info.

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
Ultimo Aggiornamento: 11/01/2026 (v3.0.0)

### Corretto
- Risolto bug nella logica di confronto titoli che causava aggiornamenti non necessari anche su file già corretti.
- Gestione dei codec nel player interno: migliorata la stabilità e aggiunto suggerimento per player esterni in caso di incompatibilità.

## [1.1.0] - 2025-12-14
- Versione iniziale stabile con supporto Database e Generazione Playlist.
