# MyPlaylist 

Creatore di Playlist Video e Gestore Database Locale.

## Funzionalità
*   **Scansione Cartelle**: Importa video con estrazione automatica metadati (NFO/Nome file).
*   **Database**: Gestione completa (Ricerca, Modifica, Rinomina Massa).
*   **Playlist**: Generazione casuale, recente (basata su data inserimento persistente) o filtrata (inclusione/esclusione). Export .m3u.
*   **Gestione Serie TV**: Supporto completo per cartelle di serie TV, aggiornamento ricorsivo dei metadati degli episodi e generazione automatica di `tvshow.nfo`.
*   **Filtri Avanzati**: Possibilità di includere o escludere generi, anni, attori e registi mediante selezione tri-state (Includi/Escludi/Nessuno).
*   **Player**: Player interno (mpv) e supporto player esterno (VLC, ecc.).
*   **VLC Control**: Supporto avanzato per VLC (kill automatico processi precedenti, avvio con controllo remoto).
*   **Remote Protocol**: Server TCP AES-GCM per il controllo remoto dal client VLC Remote, con supporto anteprima playlist.
*   **Persistenza**: Salva l'ultima playlist generata tra le sessioni.
*   **Esclusione Sessione**: Le playlist casuali non ripetono video già proposti nella stessa sessione.
*   **Gestione Doppioni Avanzata**: Rilevamento automatico copie doppie, confronto side-by-side dei metadati tecnici (ffprobe) con supporto raggruppamento per serie TV. Possibilità di eliminare copie dal DB o dal Disco in modo permanente, e funzione "Ignora" per nascondere falsi positivi in modo persistente.
*   **UI Advanced**: Tooltip sui titoli lunghi e visualizzazione del video in elaborazione durante la rinomina.

> [!WARNING]
> **Conversione Automatica in MKV**: Se l'opzione "Converti video in MKV" è attiva nelle Impostazioni, ogni operazione di **Rinomina Massa** o **Sincronizzazione Metadati** su file non-MKV (MP4, AVI, MOV, ecc.) ne comporterà il remuxing automatico in formato MKV. Il file originale verrà spostato nella cartella di backup configurata (di default `Converted_Backups` nella root del disco video).

## Requisiti di Sistema (Linux)
Il player interno utilizza `media_kit` (basato su mpv). Per supportare tutti i codec video (es. H.265/HEVC), è necessario installare le librerie di sistema:

```bash
sudo apt update
sudo apt install libmpv-dev mpv ubuntu-restricted-extras ffmpeg
```

Se riscontri schermo nero o "Codec not found", esegui il comando sopra.

## Requisiti di Sistema (Windows & macOS)
A differenza di Linux, i pacchetti per Windows e macOS non includono automaticamente gli strumenti di sistema necessari per la gestione avanzata dei metadati e la conversione dei file.

### 🪟 Windows
Per il corretto funzionamento delle funzioni di conversione (Remuxing in MKV) e l'iniezione dei tag (Rating, Poster, Trama), è necessario installare manualmente i seguenti strumenti:
1.  **FFmpeg**: [ffmpeg.org](https://ffmpeg.org/download.html)
2.  **MKVToolNix**: [mkvtoolnix.download](https://mkvtoolnix.download/downloads.html) (per la conversione in MKV)
3.  **GPAC (MP4Box)**: [gpac.wp.imt.fr](https://gpac.wp.imt.fr/downloads/) (per i metadati MP4)

**Consiglio**: Installa questi strumenti tramite un gestore pacchetti (es. `choco install ffmpeg mkvtoolnix gpac`) e assicurati che siano presenti nel `PATH` di sistema.

### 🍎 macOS
Il modo più semplice per installare i requisiti è tramite **Homebrew**:
```bash
brew install ffmpeg mkvtoolnix gpac
```

Per usufruire della **Modifica Ultra-Rapida dei Metadati** (scaricando il lavoro da FFmpeg e alterando l'header dei file Mkv e Mp4 in pochissimi millisecondi in-place), ti consigliamo caldamente di installare anche questi strumenti:

```bash
sudo apt install mkvtoolnix gpac
```

> **NOTA IMPORTANTE**: Il player interno potrebbe non riprodurre correttamente video con codec proprietari avanzati (come H.265/HEVC) anche con le librerie di sistema installate, a causa di limitazioni di licensing delle librerie bundle.
> **Soluzione**: In questi casi, utilizzare l'opzione **Player Esterno** (es. VLC) configurabile nelle Impostazioni.
> **VLC Features**: Se usi VLC, l'app gestirà automaticamente la chiusura delle istanze precedenti e abiliterà il controllo remoto (porta 4242) per l'uso con app esterne.

### 🔌 Impostazione consigliata: VLC HTTP API
Se impieghi l'app companion **VlcRemote** (dal telefono) per controllare *MyPlaylist*, ti raccomandiamo caldamente di abilitare l'API Web di VLC. Questo permetterà a VlcRemote di mostrarti in modo nativo le locandine dei film e leggere le playlist senza errori di formattazione.

**Come abilitare la Web API su VLC:**
1. Apri **VLC** normalmente.
2. Vai su **Strumenti** -> **Preferenze**.
3. In basso a sinistra, alla voce "Mostra le impostazioni", spunta **Tutto**.
4. Nel menù laterale sinistro, clicca su **Interfacce primarie** e, a destra, metti la spunta su **Web**.
5. Espandi la voce **Interfacce primarie** (a sinistra) -> **Interfacce principali** -> **Lua**.
6. A destra, inserisci una **Password** nel campo "Interfaccia HTTP" (ad es. `1234`).
7. **Salva** e chiudi VLC.
*(Ora basterà inserire la stessa password nella pagina Server dell'app VlcRemote e MyPlaylist avvierà automaticamente VLC con entrambe le interfacce attive!)*

## Installazione e Avvio
1.  Assicurati di avere Flutter installato.
2.  Esegui `flutter pub get`
3.  Esegui `flutter run -d linux` (o windows) o compila con `flutter build linux --release`.

## Crediti
Sviluppato con Flutter.
Autore: Massimo
Ultimo Aggiornamento: 31/03/2026 (v3.12.3)

## Licenza
Questo progetto è distribuito sotto licenza GNU General Public License v3.0 - vedi il file [LICENSE](LICENSE) per i dettagli.
