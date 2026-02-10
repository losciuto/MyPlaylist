# MyPlaylist 

Creatore di Playlist Video e Gestore Database Locale.

## Funzionalità
*   **Scansione Cartelle**: Importa video con estrazione automatica metadati (NFO/Nome file).
*   **Database**: Gestione completa (Ricerca, Modifica, Rinomina Massa).
*   **Playlist**: Generazione casuale, recente o filtrata (inclusione/esclusione). Export .m3u.
*   **Gestione Serie TV**: Supporto completo per cartelle di serie TV, aggiornamento ricorsivo dei metadati degli episodi e generazione automatica di `tvshow.nfo`.
*   **Filtri Avanzati**: Possibilità di includere o escludere generi, anni, attori e registi mediante selezione tri-state (Includi/Escludi/Nessuno).
*   **Player**: Player interno (mpv) e supporto player esterno (VLC, ecc.).
*   **VLC Control**: Supporto avanzato per VLC (kill automatico processi precedenti, avvio con controllo remoto).
*   **Remote Protocol**: Server TCP AES-GCM per il controllo remoto dal client VLC Remote, con supporto anteprima playlist.
*   **Persistenza**: Salva l'ultima playlist generata tra le sessioni.
*   **Esclusione Sessione**: Le playlist casuali non ripetono video già proposti nella stessa sessione.
*   **UI Advanced**: Tooltip sui titoli lunghi e visualizzazione del video in elaborazione durante la rinomina.

## Requisiti di Sistema (Linux)
Il player interno utilizza `media_kit` (basato su mpv). Per supportare tutti i codec video (es. H.265/HEVC), è necessario installare le librerie di sistema:

```bash
sudo apt update
sudo apt install libmpv-dev mpv ubuntu-restricted-extras ffmpeg
```

Se riscontri schermo nero o "Codec not found", esegui il comando sopra.

> **NOTA IMPORTANTE**: Il player interno potrebbe non riprodurre correttamente video con codec proprietari avanzati (come H.265/HEVC) anche con le librerie di sistema installate, a causa di limitazioni di licensing delle librerie bundle.
> **Soluzione**: In questi casi, utilizzare l'opzione **Player Esterno** (es. VLC) configurabile nelle Impostazioni.
> **VLC Features**: Se usi VLC, l'app gestirà automaticamente la chiusura delle istanze precedenti e abiliterà il controllo remoto (porta 4212) per l'uso con app esterne.

## Installazione e Avvio
1.  Assicurati di avere Flutter installato.
2.  Esegui `flutter pub get`
3.  Esegui `flutter run -d linux` (o windows) o compila con `flutter build linux --release`.

## Crediti
Sviluppato con Flutter.
Autore: Massimo
Ultimo Aggiornamento: 08/02/2026 (v3.6.1)

## Licenza
Questo progetto è distribuito sotto licenza GNU General Public License v3.0 - vedi il file [LICENSE](LICENSE) per i dettagli.
