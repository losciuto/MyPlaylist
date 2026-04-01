// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'MyPlaylist';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get generalTab => 'Generale';

  @override
  String get metadataTab => 'Info Metadati';

  @override
  String get playerTab => 'Server Player';

  @override
  String get remoteTab => 'Remote Playlist';

  @override
  String get maintenanceTab => 'Backup/Ripristino';

  @override
  String get debugTab => 'Debug Log';

  @override
  String get themeMode => 'Tema';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get lightTheme => 'Chiaro';

  @override
  String get darkTheme => 'Scuro';

  @override
  String get videosPerPage => 'Video per pagina';

  @override
  String get tmdbApiKey => 'TMDB API Key';

  @override
  String get tmdbApiKeyHint => 'Inserisci la tua chiave API di TMDB';

  @override
  String get tmdbInfo =>
      'La chiave API è necessaria per scaricare i metadati mancanti.';

  @override
  String get playerPath => 'Percorso Player';

  @override
  String get playerSelection => 'Selezione Player';

  @override
  String get playerPreset => 'Preset Player';

  @override
  String get autoDetectPlayer => 'Rileva Automaticamente';

  @override
  String get customPlayer => 'Player Personalizzato';

  @override
  String get testPlayer => 'Testa Player';

  @override
  String playerDetected(String name) {
    return 'Player rilevato: $name';
  }

  @override
  String get playerNotFound => 'Nessun player trovato. Configura manualmente.';

  @override
  String get playerTested => 'Player testato con successo!';

  @override
  String get playerTestFailed =>
      'Impossibile avviare il player. Controlla il percorso.';

  @override
  String get vlcPort => 'Porta RC VLC';

  @override
  String get serverEnabled => 'Abilita Server';

  @override
  String get serverPort => 'Porta Server';

  @override
  String get securityKey => 'Chiave di Sicurezza (PSK)';

  @override
  String get listenInterface => 'Interfaccia di Ascolto';

  @override
  String get backupDatabase => 'Backup Database';

  @override
  String get backupDescription => 'Salva una copia di sicurezza del database.';

  @override
  String get exportButton => 'Esporta Backup';

  @override
  String get restoreDatabase => 'Ripristina Database';

  @override
  String get restoreDescription =>
      'Ripristina il database da un file precedente.';

  @override
  String get importButton => 'Importa Backup';

  @override
  String get confirmRestoreTitle => 'Conferma Ripristino';

  @override
  String get confirmRestoreMsg =>
      'Sei sicuro di voler sovrascrivere il database corrente? L\'operazione è irreversibile.';

  @override
  String get cancel => 'Annulla';

  @override
  String get confirm => 'Conferma';

  @override
  String get dbRestoredMsg => 'Database ripristinato con successo!';

  @override
  String errorMsg(Object error) {
    return 'Errore: $error';
  }

  @override
  String get updates => 'Aggiornamenti';

  @override
  String get checkForUpdates => 'Controlla aggiornamenti';

  @override
  String currentVersion(Object version) {
    return 'Versione attuale: $version';
  }

  @override
  String get noUpdates =>
      'Nessun aggiornamento disponibile. Hai l\'ultima versione!';

  @override
  String get language => 'Lingua';

  @override
  String get eventLog => 'REGISTRO EVENTI';

  @override
  String get refreshLog => 'Aggiorna Log';

  @override
  String get copyLog => 'Copia Log';

  @override
  String get clearLog => 'Pulisci Log';

  @override
  String get logCopied => 'Log copiati negli appunti';

  @override
  String get logCleared => 'Log cancellati';

  @override
  String get noLogs => 'Nessun log presente.';

  @override
  String logError(Object error) {
    return 'Errore caricamento log: $error';
  }

  @override
  String logFile(Object path) {
    return 'File: $path';
  }

  @override
  String get navDatabase => 'Gestione DB';

  @override
  String get navPlaylist => 'Playlist';

  @override
  String get navScan => 'Scansione';

  @override
  String get navPriority => 'Priorità';

  @override
  String get navService => 'Servizio';

  @override
  String get labelDateAdded => 'Data Inserimento';

  @override
  String get labelTime => 'Ora';

  @override
  String get colTitle => 'Titolo';

  @override
  String get colPath => 'Percorso';

  @override
  String get colDuration => 'Durata';

  @override
  String get colYear => 'Anno';

  @override
  String get colRating => 'Rating';

  @override
  String get colSaga => 'Saga';

  @override
  String get colDirectors => 'Registi';

  @override
  String get colGenres => 'Generi';

  @override
  String get colActions => 'Azioni';

  @override
  String get searchPlaceholder => 'Cerca...';

  @override
  String get btnScan => 'Scansiona Cartella';

  @override
  String get btnSelectFolder => 'Seleziona Cartella';

  @override
  String get remoteControlSubtitle =>
      'Permette di controllare l\'app tramite rete locale';

  @override
  String get networkHeader => 'RETE';

  @override
  String get securityHeader => 'SICUREZZA';

  @override
  String get backupRestoreHeader => 'BACKUP E RIPRISTINO';

  @override
  String backupSuccessMsg(Object path) {
    return 'Backup salvato correttamente in:\n$path';
  }

  @override
  String backupErrorMsg(Object error) {
    return 'Errore backup: $error';
  }

  @override
  String get invalidDbMsg => 'Per favore seleziona un file .db valido.';

  @override
  String get dbNotFoundMsg => 'Database non trovato!';

  @override
  String restoreErrorMsg(Object error) {
    return 'Errore ripristino: $error';
  }

  @override
  String get tmdbApiKeyMissing => 'API Key TMDB mancante!';

  @override
  String get tmdbNoResults => 'Nessun risultato trovato su TMDB.';

  @override
  String get selectMovieTitle => 'Seleziona Film';

  @override
  String get tmdbSuccessMsg =>
      'Info scaricate con successo! Riavvia la scansione per aggiornare.';

  @override
  String genericError(Object error) {
    return 'Errore: $error';
  }

  @override
  String get playButtonLabel => 'RIPRODUCI';

  @override
  String get tmdbInfoButtonLabel => 'Info TMDB';

  @override
  String get noEpisodesFound => 'Nessun episodio trovato.';

  @override
  String updateAvailableTitle(Object version) {
    return 'Nuova versione disponibile: $version';
  }

  @override
  String get updateAvailableHeader => 'È disponibile un nuovo aggiornamento!';

  @override
  String get whatsNewHeader => 'Novità in questa versione:';

  @override
  String get downloadButtonLabel => 'Scarica';

  @override
  String get ignoreButtonLabel => 'Ignora';

  @override
  String yearLabel(Object year) {
    return 'Anno: $year';
  }

  @override
  String get stopAllButtonLabel => 'INTERROMPI TUTTO';

  @override
  String get generateNfoTmdbLabel => 'Genera NFO (TMDB)';

  @override
  String get sectionGenres => 'GENERI';

  @override
  String get sectionCast => 'CAST';

  @override
  String get sectionDirectors => 'Regia';

  @override
  String get sectionPlot => 'TRAMA';

  @override
  String get sectionSaga => 'SAGA';

  @override
  String get sectionFile => 'FILE';

  @override
  String get sectionEpisodes => 'EPISODI';

  @override
  String pageOf(Object current, Object total) {
    return 'Pagina $current di $total';
  }

  @override
  String get skipVideo => 'Salta questo video';

  @override
  String get untitled => 'Senza Titolo';

  @override
  String get scanTitle => 'SCANSIONE CARTELLE';

  @override
  String get scanDescription =>
      'Scansiona le cartelle per aggiornare il database con i metadati dei video.\nCercherà automaticamente i file .nfo associati.';

  @override
  String get scanStats => '📊 Statistiche Scansione';

  @override
  String get scanStatusReady => 'Pronto per la scansione';

  @override
  String get scanStatusInit => 'Inizializzazione scansione...';

  @override
  String videosFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video trovati',
      one: '1 video trovato',
      zero: 'Nessun video trovato',
    );
    return '$_temp0';
  }

  @override
  String get scanSupportedExt =>
      'Estensioni supportate: .mp4, .avi, .mkv, .mov, ...';

  @override
  String genPlaylistTitle(Object count) {
    return 'GENERA PLAYLIST (video presenti: $count)';
  }

  @override
  String get btnRandom => '🎲 Playlist Casuale';

  @override
  String get btnRecent => '🕒 Più Recenti';

  @override
  String get btnFiltered => '🎲 Playlist\ncon Filtri';

  @override
  String get btnManual => '✏️ Selezione\nManuale';

  @override
  String btnResetSession(Object count) {
    return 'Resetta cronologia sessione ($count visti)';
  }

  @override
  String get actionsTitle => 'Azioni Playlist';

  @override
  String get btnShowPosters => '🎨 Mostra Poster';

  @override
  String get btnExport => '💾 Esporta';

  @override
  String get openTempFolder => 'Apri cartella file temporaneo';

  @override
  String get logTitle => 'Log Comandi Remoti';

  @override
  String get logWaiting => 'In attesa...';

  @override
  String logLast(Object command) {
    return 'Ultimo: $command';
  }

  @override
  String get noPlaylist => 'Nessuna playlist generata';

  @override
  String videosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video',
      one: '1 video',
      zero: 'Nessun video',
    );
    return '$_temp0';
  }

  @override
  String currentPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video',
      one: '1 video',
      zero: 'nessun video',
    );
    return 'Playlist corrente: $_temp0';
  }

  @override
  String playlistExported(Object path) {
    return 'Playlist esportata in $path';
  }

  @override
  String playerStarted(Object name) {
    return 'Avviato player esterno: $name';
  }

  @override
  String folderOpenError(Object error) {
    return 'Impossibile aprire la cartella: $error';
  }

  @override
  String get inputCountTitle => 'Numero di video';

  @override
  String get inputCountLabel => 'Quanti video vuoi includere?';

  @override
  String videoCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video',
      one: '1 video',
      zero: 'nessun video',
    );
    return 'Generata playlist di $_temp0.';
  }

  @override
  String get noVideoFound => 'Nessun video trovato!';

  @override
  String get filterTitle => 'Filtri Avanzati Playlist';

  @override
  String get resetFilters => 'Resetta Filtri';

  @override
  String get tabGeneral => 'Generale';

  @override
  String get tabGenres => 'Generi';

  @override
  String get tabYears => 'Anni';

  @override
  String get tabDirectors => 'Registi';

  @override
  String get tabActors => 'Attori';

  @override
  String get tabSagas => 'Saghe';

  @override
  String get generalSettings => 'IMPOSTAZIONI GENERALI';

  @override
  String get maxVideos => 'Numero massimo di video:';

  @override
  String get minRating => 'Rating Minimo:';

  @override
  String filterByRating(Object rating) {
    return 'Filtra per rating ≥ $rating';
  }

  @override
  String get summary => 'Sommario';

  @override
  String includedItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inclusi',
      one: '1 incluso',
      zero: 'Nessuno incluso',
    );
    return '$_temp0';
  }

  @override
  String excludedItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count esclusi',
      one: '1 escluso',
      zero: 'Nessuno escluso',
    );
    return '$_temp0';
  }

  @override
  String get noActiveFilters => 'Nessun filtro attivo';

  @override
  String videosFor(Object title, Object value) {
    return 'Video per $title: $value';
  }

  @override
  String foundVideos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video',
      one: '1 video',
      zero: 'nessun video',
    );
    return 'Trovati: $_temp0';
  }

  @override
  String get manualSelectionTitle => 'Selezione Manuale Video';

  @override
  String get searchHint => 'Cerca per titolo, anno, regista...';

  @override
  String selectedItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selezionati',
      one: '1 selezionato',
      zero: 'Nessuno selezionato',
    );
    return '$_temp0';
  }

  @override
  String visibleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count',
      one: '1',
      zero: 'nessuno',
    );
    return 'Totale visibili: $_temp0';
  }

  @override
  String get selectAllVisible => 'Seleziona Tutti Visibili';

  @override
  String get deselectAll => 'Deseleziona Tutti';

  @override
  String get createPlaylist => 'Crea Playlist';

  @override
  String get bulkRenameTitle => 'Rinomina Titoli in Massa';

  @override
  String get bulkRenameMsg =>
      'Questa operazione cercherà i file .nfo per ogni video e rinominerà i video nel formato \"Titolo (Anno)\".\n\nVerranno aggiornati sia il database che i metadati dei file video.\n\nL\'operazione potrebbe richiedere del tempo. Continuare?';

  @override
  String get start => 'Avvia';

  @override
  String get renaming => 'Rinomina in corso...';

  @override
  String get processing => 'Elaborazione:';

  @override
  String get tmdbGenTitle => 'Generazione NFO da TMDB';

  @override
  String get tmdbGenModeMsg =>
      'Scegli la modalità di generazione:\n\n⚡ AUTOMATICO: Scarica il primo risultato trovato (più veloce).\n🖐️ INTERATTIVO: Ti chiede di confermare il film per ogni video trovato.';

  @override
  String get tmdbGenAuto => '⚡ AUTOMATICO';

  @override
  String get tmdbGenInteractive => '🖐️ INTERATTIVO';

  @override
  String get tmdbClickAuto => '⚡ Automatico';

  @override
  String get tmdbClickInteractive => '🖐️ Interattivo';

  @override
  String get onlyMissingNfo => 'Genera solo se manca il file .nfo';

  @override
  String get downloadingInfo => 'Scaricamento Info...';

  @override
  String get genComplete => 'Generazione Completata';

  @override
  String genStats(Object created, Object errors, Object skipped) {
    return 'File creati: $created\nSaltati/Non trovati: $skipped\nErrori: $errors';
  }

  @override
  String genStatsDetailed(
    Object errors,
    Object skipped,
    Object sync,
    Object updated,
  ) {
    return 'Aggiornati: $updated\nGià presenti: $sync\nNon trovati: $skipped\nErrori: $errors';
  }

  @override
  String get confirmDeleteTitle => 'Conferma Eliminazione';

  @override
  String confirmDeleteMsg(Object title) {
    return 'Vuoi eliminare il video \"$title\" dal database?\nIl file fisico non verrà rimosso.';
  }

  @override
  String get delete => 'Elimina';

  @override
  String get videoDeleted => 'Video eliminato dal database';

  @override
  String get confirmClearDb => 'Vuoi cancellare TUTTI i dati dal database?';

  @override
  String get yesDelete => 'Si, Cancella';

  @override
  String get dbCleared => 'Database pulito!';

  @override
  String get videoUpdated => 'Video aggiornato correttamente';

  @override
  String get editVideoTitle => 'Modifica Video';

  @override
  String get loadFromNfo => 'Carica da NFO';

  @override
  String get downloadTmdb => 'Scarica TMDB';

  @override
  String fileLabel(Object name) {
    return 'File: $name';
  }

  @override
  String pathLabel(Object path) {
    return 'Percorso: $path';
  }

  @override
  String sizeLabel(Object size) {
    return 'Dimensione: $size';
  }

  @override
  String get labelTitle => 'Titolo';

  @override
  String get labelYear => 'Anno';

  @override
  String get labelDuration => 'Durata (min)';

  @override
  String get labelGenres => 'Generi (separati da virgola)';

  @override
  String get labelDirectors => 'Registi';

  @override
  String get labelActors => 'Attori (separati da virgola)';

  @override
  String get labelPoster => 'Path Poster';

  @override
  String get labelSaga => 'Saga';

  @override
  String get labelSagaIndex => 'Indice Saga';

  @override
  String get labelPlot => 'Trama';

  @override
  String ratingLabel(Object rating) {
    return 'Voto: $rating';
  }

  @override
  String get updateDbOnly => 'Aggiorna solo DB';

  @override
  String get saveAll => 'Salva tutto (File + DB)';

  @override
  String get saveToNfo => 'Salva su NFO';

  @override
  String get requiredField => 'Campo obbligatorio';

  @override
  String get dbUpdatedMsg =>
      'Database aggiornato (senza toccare il file video)';

  @override
  String get fileUpdateMsg => 'Aggiornamento file in corso...';

  @override
  String get successUpdateMsg => 'File e Database aggiornati con successo!';

  @override
  String get errorUpdateMsg =>
      'Errore aggiornamento file (Database comunque aggiornato)';

  @override
  String get nfoLoadedMsg => 'Dati caricati dal file .nfo!';

  @override
  String get nfoNotFoundMsg => 'File .nfo non trovato.';

  @override
  String get nfoErrorMsg => 'Errore nel parsing del file .nfo.';

  @override
  String get tmdbUpdatedMsg => 'Dati aggiornati da TMDB (NFO e asset creati)';

  @override
  String get seriesLabel => 'SERIE';

  @override
  String get ok => 'OK';

  @override
  String get no => 'No';

  @override
  String get noCommandsMsg => 'Nessun comando trovato.';

  @override
  String get noVideoInDb => 'Nessun video nel database.';

  @override
  String get sagaTooltip =>
      'Il nome della collezione di film (es. Star Wars Collection)';

  @override
  String get sagaIndexTooltip =>
      'L\'ordine del film nella collezione (1, 2, 3...)';

  @override
  String get infoTitle => 'Informazioni';

  @override
  String get playlistCreator => 'Creatore Playlist';

  @override
  String get tmdbGenModeTitle => 'Modalità Generazione TMDB';

  @override
  String get cancelling => 'Annullamento...';

  @override
  String get paramsNone => 'Nessun parametro';

  @override
  String paramsLabel(Object params) {
    return 'Parametri: $params';
  }

  @override
  String get author => 'Autore';

  @override
  String get buildDate => 'Data redazione';

  @override
  String get scanInProgress => 'Scansione in corso...';

  @override
  String get selectFolderToScan => 'Seleziona cartella da scansionare';

  @override
  String included(Object inclusions) {
    return 'Inclusioni: $inclusions';
  }

  @override
  String excluded(Object exclusions) {
    return 'Esclusioni: $exclusions';
  }

  @override
  String scanFinishedMsg(Object count) {
    return 'Scansione terminata. Trovati $count nuovi video.';
  }

  @override
  String get appearanceHeader => 'ASPETTO';

  @override
  String get langIt => 'Italiano';

  @override
  String get langEn => 'Inglese';

  @override
  String get playlistHeader => 'PLAYLIST';

  @override
  String get defaultPlaylistSizeHelp =>
      'Numero di video proposti di default alla creazione di una playlist';

  @override
  String get checkButton => 'Controlla';

  @override
  String get tmdbHeader => 'TMDB (THE MOVIE DATABASE)';

  @override
  String get executableHeader => 'ESEGUIBILE';

  @override
  String get vlcRemoteHeader => 'CONTROLLO REMOTO VLC';

  @override
  String get serverStatusHeader => 'STATO SERVER';

  @override
  String get selectDestinationFolder => 'Seleziona cartella di destinazione';

  @override
  String get selectBackupFile => 'Seleziona file di backup (.db)';

  @override
  String get eventLogHeader => 'REGISTRO EVENTI';

  @override
  String updateError(Object error) {
    return 'Errore durante il controllo aggiornamenti: $error';
  }

  @override
  String get databaseManagementTitle => 'GESTIONE DATABASE';

  @override
  String videosInDatabase(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video',
      one: '1 video',
      zero: 'Nessun video',
    );
    return '🎬 $_temp0 nel database';
  }

  @override
  String get searchVideosPlaceholder => 'Cerca video...';

  @override
  String get noVideosFound => 'Nessun video trovato.';

  @override
  String get clearDatabaseButton => 'Pulisci Database';

  @override
  String get refreshButton => 'Aggiorna';

  @override
  String get btnSyncDates => 'Sincronizza Date';

  @override
  String get renameTitlesButton => 'Rinomina Titoli';

  @override
  String get editTooltip => 'Modifica';

  @override
  String get deleteTooltip => 'Elimina';

  @override
  String get opCancelled => 'Operazione Annullata';

  @override
  String get opCompleted => 'Operazione Completata';

  @override
  String bulkOpStats(Object errors, Object skipped, Object updated) {
    return 'Aggiornati: $updated\nSaltati: $skipped\nErrori: $errors';
  }

  @override
  String bulkOpStatsDetailed(
    Object errors,
    Object failed,
    Object sync,
    Object updated,
  ) {
    return 'Aggiornati: $updated\nGià corretti: $sync\nGià in elenco (ignorati): $failed\nNuovi errori: $errors';
  }

  @override
  String get openGitHubLabel => 'Apri GitHub';

  @override
  String get statsTotalVideos => 'Totale Video';

  @override
  String get statsMovies => 'Film';

  @override
  String get statsSeries => 'Serie TV';

  @override
  String get statsAvgRating => 'Voto Medio';

  @override
  String get statsTopGenres => 'Generi Top';

  @override
  String get statsVideosByYear => 'Video per Anno';

  @override
  String get statsTopSagas => 'Saghe/Collezioni Top';

  @override
  String get exportPlaylistTitle => 'Esporta Playlist';

  @override
  String get tabStatistics => 'Statistiche';

  @override
  String get settingsAutoSync => 'Auto-Sync';

  @override
  String get settingsAutoSyncSubtitle =>
      'Monitora automaticamente le cartelle scansionate per modifiche';

  @override
  String get settingsWatchedFolders => 'Cartelle Monitorate';

  @override
  String get settingsNoWatchedFolders => 'Nessuna cartella monitorata';

  @override
  String get fanartApiKey => 'Fanart.tv API Key';

  @override
  String get settingsAutoSyncNfo => 'Sincronizza NFO su modifica';

  @override
  String get settingsAutoSyncNfoSubtitle =>
      'Salva automaticamente i metadati nel file .nfo quando modifichi un video';

  @override
  String get settingsFastMetadataEngine =>
      'Usa metodi ultra-rapidi per Metadati';

  @override
  String get settingsFastMetadataEngineSubtitle =>
      'Richiede mkvtoolnix e MP4Box. Se assenti, userà FFmpeg come fallback.';

  @override
  String get resetPriorityList => 'Reset Lista Priorità';

  @override
  String get resetPriorityDescription =>
      'Riporta tutte le date di inserimento alla data di modifica originale del file sul disco. Utile per \'pulire\' la lista priorità e ricominciare da zero.';

  @override
  String get confirmResetPriority =>
      'Vuoi resettare tutte le date di inserimento?';

  @override
  String get duplicatesButton => 'Doppioni';

  @override
  String get confirmClearDbMsg =>
      'Vuoi cancellare TUTTI i dati dal database?\n\nVerranno rimosse anche le cartelle monitorate dall\'Auto-Sync.';

  @override
  String get manualDbSyncHeader => 'SYNC MANUALE DEL DATABASE';

  @override
  String get syncMissingTagsLabel => 'Sincronizza tag file mancanti';

  @override
  String get syncMissingTagsDesc =>
      'Scansiona tutta la libreria e salva nei file (MP4/MKV) i metadati del database che non sono ancora impressi, come Locandine e Valutazioni, così da renderle visibili sulle app esterne (es. VlcRemote).';

  @override
  String get startSyncButton => 'Avvia Sincronizzazione';

  @override
  String get bulkSyncTitle => 'Sincronizzazione Massiva Metadati';

  @override
  String get bulkSyncDesc =>
      'Questa operazione ispezionerà tutti i video nel database per verificare se i file fisici possiedono i tag. Se i tag (Trama, Rating, o Poster) sono assenti, sfrutterà FFmpeg per inserirli.\n\nPotrebbe volerci del tempo per directory molto corpose. Vuoi procedere?';

  @override
  String get startSyncDialogButton => 'Inizia Sincronizzazione';

  @override
  String get syncInterrupted => 'Sincronizzazione Interrotta';

  @override
  String get syncCompleted => 'Sincronizzazione Completata';

  @override
  String syncResultMsg(String examined, String updated, String skipped) {
    return 'Operazione terminata.\n\nFile esaminati: $examined\nAggiornati: $updated\nInvariati/Saltati: $skipped';
  }

  @override
  String get batchProcessingTitle => 'Elaborazione Batch...';

  @override
  String fileXofY(String current, String total) {
    return 'File $current di $total';
  }

  @override
  String syncUpdated(String count) {
    return 'Aggiornati: $count';
  }

  @override
  String syncSkipped(String count) {
    return 'Saltati: $count';
  }

  @override
  String syncMethodLabel(String method) {
    return 'Metodo: $method';
  }

  @override
  String syncReasonLabel(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get syncReasonFastDisabled => 'Motore rapido disattivato';

  @override
  String syncReasonUnsupportedFormat(String ext) {
    return 'Formato non supportato ($ext)';
  }

  @override
  String syncReasonToolNotFound(String tool) {
    return '$tool non trovato';
  }

  @override
  String syncReasonToolFailed(String tool) {
    return 'Errore $tool (fallback)';
  }

  @override
  String get syncReasonTimeout => 'Timeout (troppo lento)';

  @override
  String get settingsAutoConvertAvi => 'Converti video in MKV';

  @override
  String get settingsAutoConvertAviSubtitle =>
      'In fase di rinomina o modifica, esegue il remuxing automatico in MKV per i formati non compressi (AVI, MP4, MOV, ecc.) e sposta l\'originale nella cartella di backup';

  @override
  String get stopButton => 'Interrompi';

  @override
  String get closeButton => 'Chiudi';

  @override
  String get fanartApiKeyHint => 'Opzionale: per loghi e sfondi migliori';

  @override
  String failedRenamesTitle(String count) {
    return 'File Ignorati/Falliti ($count)';
  }

  @override
  String get clearListTitle => 'Pulisci Lista';

  @override
  String get clearListMsg =>
      'Vuoi rimuovere tutti i file ignorati? L\'app proverà di nuovo a rinominarli alla prossima esecuzione.';

  @override
  String get clearListTooltip => 'Pulisci Tutto';

  @override
  String get noFailedFiles => 'Nessun file fallito o ignorato.';

  @override
  String get removeFromListTooltip => 'Rimuovi dalla lista e ritenta';

  @override
  String get stopScanButton => 'Ferma Scansione';

  @override
  String get scanStoppedByUser => 'Scansione interrotta dall\'utente.';

  @override
  String get processingLabel => 'In elaborazione:';

  @override
  String get maintenanceHeader => 'MANUTENZIONE';

  @override
  String get backupRestoreSectionHeader => 'BACKUP E RIPRISTINO';

  @override
  String get duplicatesManager => 'Gestione Doppioni';

  @override
  String duplicatesFoundInfo(String groups, String files) {
    return '$groups gruppi trovati · $files file duplicati';
  }

  @override
  String duplicatesRemovedFromDb(String title) {
    return 'Rimosso dal database: $title';
  }

  @override
  String duplicatesDeletedFiles(String count, String title) {
    return 'Eliminati $count file di $title';
  }

  @override
  String get duplicatesDeleteFromDiskTitle => 'Elimina da disco';

  @override
  String duplicatesDeleteFromDiskMsg(String file) {
    return 'Verranno eliminati il file video e tutti i file associati (NFO, poster, fanart, ecc.).\n\n$file\n\nConfermi?';
  }

  @override
  String get duplicatesNoDuplicates => 'Nessun doppione trovato!';

  @override
  String get duplicatesAllUnique => 'Tutti i titoli nell\'archivio sono unici.';

  @override
  String duplicatesRestoreIgnoredBtn(String count) {
    return 'Ripristina $count gruppi ignorati';
  }

  @override
  String duplicatesCopies(String title, String count) {
    return '$title  ·  $count copie';
  }

  @override
  String get duplicatesCompareBtn => 'Confronta';

  @override
  String get duplicatesDetailsLabel => 'Dettagli';

  @override
  String get duplicatesDbOnlyBtn => 'Solo DB';

  @override
  String get duplicatesPlusDiskBtn => '+ Disco';

  @override
  String get duplicatesFooterInfo =>
      '\"Solo DB\" rimuove il record ma lascia i file intatti. \"Disco\" elimina permanentemente tutti i file associati.';

  @override
  String duplicatesResetIgnoredTooltip(String count) {
    return '$count gruppi ignorati — clicca per ripristinarli';
  }

  @override
  String duplicatesResetIgnoredLabel(String count) {
    return 'Reset ignorati ($count)';
  }

  @override
  String duplicatesDeleteFromDiskMsg2(String file) {
    return 'Verranno eliminati definitivamente:\n• Il file video\n• NFO, poster, fanart e tutti i file associati\n\n$file\n\nConfermi?';
  }

  @override
  String get duplicatesCompareDialogTitle => 'Confronto doppioni';

  @override
  String get duplicatesCompareDialogFooter =>
      'Scegli quale copia eliminare. \"Solo DB\" rimuove il record. \"+ Disco\" elimina anche tutti i file dalla cartella.';

  @override
  String get duplicateIgnoreBtn => 'Ignora';

  @override
  String get duplicatePlayBtn => 'Riproduci';

  @override
  String get duplicateSecFile => '📁 FILE';

  @override
  String get duplicateSecVideo => '🎬 VIDEO';

  @override
  String get duplicateSecAudio => '🔊 AUDIO';

  @override
  String get duplicateSecDb => '🗂 METADATI DB';

  @override
  String get duplicateLblSize => 'Dimensione';

  @override
  String get duplicateLblContainer => 'Contenitore';

  @override
  String get duplicateLblStatus => 'Stato';

  @override
  String get duplicateStatusNotFound => '⚠ File non trovato';

  @override
  String get duplicateLblCodec => 'Codec';

  @override
  String get duplicateLblResolution => 'Risoluzione';

  @override
  String get duplicateLblFrameRate => 'Frame rate';

  @override
  String get duplicateLblBitrateVideo => 'Bitrate video';

  @override
  String get duplicateLblBitrateTotal => 'Bitrate totale';

  @override
  String get duplicateLblChannels => 'Canali';

  @override
  String get duplicateLblSampleRate => 'Sample rate';

  @override
  String get duplicateLblTitleDb => 'Titolo (DB)';

  @override
  String get duplicateLblYear => 'Anno';

  @override
  String get duplicateLblDurationDb => 'Durata (DB)';

  @override
  String get duplicateLblDurationFile => 'Durata (file)';

  @override
  String get duplicateLblGenres => 'Generi';

  @override
  String get duplicateLblRating => 'Voto';

  @override
  String get duplicateLblSaga => 'Saga';

  @override
  String get duplicateLblPlot => 'Trama';

  @override
  String duplicateChannelsVal(String count) {
    return '$count canali';
  }

  @override
  String playerError(String event) {
    return 'Errore Player: $event';
  }

  @override
  String get playerNoFile => 'Nessun file video trovato per la riproduzione.';

  @override
  String get filterByPerson => 'Filtra per questa persona';

  @override
  String get infoTmdbTitle => 'Info TMDB';

  @override
  String get viewFileMetadata => 'Vedi Meta File';

  @override
  String get fileMetadataTitle => 'Metadati Raw del File';

  @override
  String get addTag => 'Aggiungi Tag';

  @override
  String get saveToFile => 'Salva nel File';

  @override
  String get btnFileMetadata => 'Metadati da File';

  @override
  String get settingsAviBackupPath => 'Cartella backup video convertiti';

  @override
  String get settingsAviBackupPathSubtitle =>
      'Percorso dove spostare i file originali dopo la conversione in MKV (lascia vuoto per default)';

  @override
  String get settingsExcludeConvertedBackup =>
      'Escludi backup filmati convertiti dalla scansione';

  @override
  String get settingsExcludeConvertedBackupSubtitle =>
      'Se attivo, la cartella dei file originali (prima del remuxing in MKV) verrà saltata durante la ricerca di nuovi video';

  @override
  String get convertingToMkv => 'Remuxing in MKV in corso...';
}
