# Changelog

Tutti i cambiamenti significativi a questo progetto saranno documentati in questo file.

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

### Corretto
- Risolto bug nella logica di confronto titoli che causava aggiornamenti non necessari anche su file già corretti.
- Gestione dei codec nel player interno: migliorata la stabilità e aggiunto suggerimento per player esterni in caso di incompatibilità.

## [1.1.0] - 2025-12-14
- Versione iniziale stabile con supporto Database e Generazione Playlist.
