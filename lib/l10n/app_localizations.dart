import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In it, this message translates to:
  /// **'MyPlaylist'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settingsTitle;

  /// No description provided for @generalTab.
  ///
  /// In it, this message translates to:
  /// **'Generale'**
  String get generalTab;

  /// No description provided for @metadataTab.
  ///
  /// In it, this message translates to:
  /// **'Info Metadati'**
  String get metadataTab;

  /// No description provided for @playerTab.
  ///
  /// In it, this message translates to:
  /// **'Server Player'**
  String get playerTab;

  /// No description provided for @remoteTab.
  ///
  /// In it, this message translates to:
  /// **'Remote Playlist'**
  String get remoteTab;

  /// No description provided for @maintenanceTab.
  ///
  /// In it, this message translates to:
  /// **'Backup/Ripristino'**
  String get maintenanceTab;

  /// No description provided for @debugTab.
  ///
  /// In it, this message translates to:
  /// **'Debug Log'**
  String get debugTab;

  /// No description provided for @themeMode.
  ///
  /// In it, this message translates to:
  /// **'Tema'**
  String get themeMode;

  /// No description provided for @systemTheme.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In it, this message translates to:
  /// **'Chiaro'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In it, this message translates to:
  /// **'Scuro'**
  String get darkTheme;

  /// No description provided for @videosPerPage.
  ///
  /// In it, this message translates to:
  /// **'Video per pagina'**
  String get videosPerPage;

  /// No description provided for @tmdbApiKey.
  ///
  /// In it, this message translates to:
  /// **'TMDB API Key'**
  String get tmdbApiKey;

  /// No description provided for @tmdbApiKeyHint.
  ///
  /// In it, this message translates to:
  /// **'Inserisci la tua chiave API di TMDB'**
  String get tmdbApiKeyHint;

  /// No description provided for @tmdbInfo.
  ///
  /// In it, this message translates to:
  /// **'La chiave API è necessaria per scaricare i metadati mancanti.'**
  String get tmdbInfo;

  /// No description provided for @playerPath.
  ///
  /// In it, this message translates to:
  /// **'Percorso Player'**
  String get playerPath;

  /// No description provided for @playerSelection.
  ///
  /// In it, this message translates to:
  /// **'Selezione Player'**
  String get playerSelection;

  /// No description provided for @playerPreset.
  ///
  /// In it, this message translates to:
  /// **'Preset Player'**
  String get playerPreset;

  /// No description provided for @autoDetectPlayer.
  ///
  /// In it, this message translates to:
  /// **'Rileva Automaticamente'**
  String get autoDetectPlayer;

  /// No description provided for @customPlayer.
  ///
  /// In it, this message translates to:
  /// **'Player Personalizzato'**
  String get customPlayer;

  /// No description provided for @testPlayer.
  ///
  /// In it, this message translates to:
  /// **'Testa Player'**
  String get testPlayer;

  /// No description provided for @playerDetected.
  ///
  /// In it, this message translates to:
  /// **'Player rilevato: {name}'**
  String playerDetected(String name);

  /// No description provided for @playerNotFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun player trovato. Configura manualmente.'**
  String get playerNotFound;

  /// No description provided for @playerTested.
  ///
  /// In it, this message translates to:
  /// **'Player testato con successo!'**
  String get playerTested;

  /// No description provided for @playerTestFailed.
  ///
  /// In it, this message translates to:
  /// **'Impossibile avviare il player. Controlla il percorso.'**
  String get playerTestFailed;

  /// No description provided for @vlcPort.
  ///
  /// In it, this message translates to:
  /// **'Porta RC VLC'**
  String get vlcPort;

  /// No description provided for @serverEnabled.
  ///
  /// In it, this message translates to:
  /// **'Abilita Server'**
  String get serverEnabled;

  /// No description provided for @serverPort.
  ///
  /// In it, this message translates to:
  /// **'Porta Server'**
  String get serverPort;

  /// No description provided for @securityKey.
  ///
  /// In it, this message translates to:
  /// **'Chiave di Sicurezza (PSK)'**
  String get securityKey;

  /// No description provided for @listenInterface.
  ///
  /// In it, this message translates to:
  /// **'Interfaccia di Ascolto'**
  String get listenInterface;

  /// No description provided for @backupDatabase.
  ///
  /// In it, this message translates to:
  /// **'Backup Database'**
  String get backupDatabase;

  /// No description provided for @backupDescription.
  ///
  /// In it, this message translates to:
  /// **'Salva una copia di sicurezza del database.'**
  String get backupDescription;

  /// No description provided for @exportButton.
  ///
  /// In it, this message translates to:
  /// **'Esporta Backup'**
  String get exportButton;

  /// No description provided for @restoreDatabase.
  ///
  /// In it, this message translates to:
  /// **'Ripristina Database'**
  String get restoreDatabase;

  /// No description provided for @restoreDescription.
  ///
  /// In it, this message translates to:
  /// **'Ripristina il database da un file precedente.'**
  String get restoreDescription;

  /// No description provided for @importButton.
  ///
  /// In it, this message translates to:
  /// **'Importa Backup'**
  String get importButton;

  /// No description provided for @confirmRestoreTitle.
  ///
  /// In it, this message translates to:
  /// **'Conferma Ripristino'**
  String get confirmRestoreTitle;

  /// No description provided for @confirmRestoreMsg.
  ///
  /// In it, this message translates to:
  /// **'Sei sicuro di voler sovrascrivere il database corrente? L\'operazione è irreversibile.'**
  String get confirmRestoreMsg;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In it, this message translates to:
  /// **'Conferma'**
  String get confirm;

  /// No description provided for @dbRestoredMsg.
  ///
  /// In it, this message translates to:
  /// **'Database ripristinato con successo!'**
  String get dbRestoredMsg;

  /// No description provided for @errorMsg.
  ///
  /// In it, this message translates to:
  /// **'Errore: {error}'**
  String errorMsg(Object error);

  /// No description provided for @updates.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamenti'**
  String get updates;

  /// No description provided for @checkForUpdates.
  ///
  /// In it, this message translates to:
  /// **'Controlla aggiornamenti'**
  String get checkForUpdates;

  /// No description provided for @currentVersion.
  ///
  /// In it, this message translates to:
  /// **'Versione attuale: {version}'**
  String currentVersion(Object version);

  /// No description provided for @noUpdates.
  ///
  /// In it, this message translates to:
  /// **'Nessun aggiornamento disponibile. Hai l\'ultima versione!'**
  String get noUpdates;

  /// No description provided for @language.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get language;

  /// No description provided for @eventLog.
  ///
  /// In it, this message translates to:
  /// **'REGISTRO EVENTI'**
  String get eventLog;

  /// No description provided for @refreshLog.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna Log'**
  String get refreshLog;

  /// No description provided for @copyLog.
  ///
  /// In it, this message translates to:
  /// **'Copia Log'**
  String get copyLog;

  /// No description provided for @clearLog.
  ///
  /// In it, this message translates to:
  /// **'Pulisci Log'**
  String get clearLog;

  /// No description provided for @logCopied.
  ///
  /// In it, this message translates to:
  /// **'Log copiati negli appunti'**
  String get logCopied;

  /// No description provided for @logCleared.
  ///
  /// In it, this message translates to:
  /// **'Log cancellati'**
  String get logCleared;

  /// No description provided for @noLogs.
  ///
  /// In it, this message translates to:
  /// **'Nessun log presente.'**
  String get noLogs;

  /// No description provided for @logError.
  ///
  /// In it, this message translates to:
  /// **'Errore caricamento log: {error}'**
  String logError(Object error);

  /// No description provided for @logFile.
  ///
  /// In it, this message translates to:
  /// **'File: {path}'**
  String logFile(Object path);

  /// No description provided for @navDatabase.
  ///
  /// In it, this message translates to:
  /// **'Gestione DB'**
  String get navDatabase;

  /// No description provided for @navPlaylist.
  ///
  /// In it, this message translates to:
  /// **'Playlist'**
  String get navPlaylist;

  /// No description provided for @navScan.
  ///
  /// In it, this message translates to:
  /// **'Scansione'**
  String get navScan;

  /// No description provided for @colTitle.
  ///
  /// In it, this message translates to:
  /// **'Titolo'**
  String get colTitle;

  /// No description provided for @colPath.
  ///
  /// In it, this message translates to:
  /// **'Percorso'**
  String get colPath;

  /// No description provided for @colDuration.
  ///
  /// In it, this message translates to:
  /// **'Durata'**
  String get colDuration;

  /// No description provided for @colYear.
  ///
  /// In it, this message translates to:
  /// **'Anno'**
  String get colYear;

  /// No description provided for @colRating.
  ///
  /// In it, this message translates to:
  /// **'Rating'**
  String get colRating;

  /// No description provided for @colSaga.
  ///
  /// In it, this message translates to:
  /// **'Saga'**
  String get colSaga;

  /// No description provided for @colDirectors.
  ///
  /// In it, this message translates to:
  /// **'Registi'**
  String get colDirectors;

  /// No description provided for @colGenres.
  ///
  /// In it, this message translates to:
  /// **'Generi'**
  String get colGenres;

  /// No description provided for @colActions.
  ///
  /// In it, this message translates to:
  /// **'Azioni'**
  String get colActions;

  /// No description provided for @searchPlaceholder.
  ///
  /// In it, this message translates to:
  /// **'Cerca...'**
  String get searchPlaceholder;

  /// No description provided for @btnScan.
  ///
  /// In it, this message translates to:
  /// **'Scansiona Cartella'**
  String get btnScan;

  /// No description provided for @btnSelectFolder.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Cartella'**
  String get btnSelectFolder;

  /// No description provided for @remoteControlSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Permette di controllare l\'app tramite rete locale'**
  String get remoteControlSubtitle;

  /// No description provided for @networkHeader.
  ///
  /// In it, this message translates to:
  /// **'RETE'**
  String get networkHeader;

  /// No description provided for @securityHeader.
  ///
  /// In it, this message translates to:
  /// **'SICUREZZA'**
  String get securityHeader;

  /// No description provided for @backupRestoreHeader.
  ///
  /// In it, this message translates to:
  /// **'BACKUP E RIPRISTINO'**
  String get backupRestoreHeader;

  /// No description provided for @backupSuccessMsg.
  ///
  /// In it, this message translates to:
  /// **'Backup salvato correttamente in:\n{path}'**
  String backupSuccessMsg(Object path);

  /// No description provided for @backupErrorMsg.
  ///
  /// In it, this message translates to:
  /// **'Errore backup: {error}'**
  String backupErrorMsg(Object error);

  /// No description provided for @invalidDbMsg.
  ///
  /// In it, this message translates to:
  /// **'Per favore seleziona un file .db valido.'**
  String get invalidDbMsg;

  /// No description provided for @dbNotFoundMsg.
  ///
  /// In it, this message translates to:
  /// **'Database non trovato!'**
  String get dbNotFoundMsg;

  /// No description provided for @restoreErrorMsg.
  ///
  /// In it, this message translates to:
  /// **'Errore ripristino: {error}'**
  String restoreErrorMsg(Object error);

  /// No description provided for @tmdbApiKeyMissing.
  ///
  /// In it, this message translates to:
  /// **'API Key TMDB mancante!'**
  String get tmdbApiKeyMissing;

  /// No description provided for @tmdbNoResults.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato trovato su TMDB.'**
  String get tmdbNoResults;

  /// No description provided for @selectMovieTitle.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Film'**
  String get selectMovieTitle;

  /// No description provided for @tmdbSuccessMsg.
  ///
  /// In it, this message translates to:
  /// **'Info scaricate con successo! Riavvia la scansione per aggiornare.'**
  String get tmdbSuccessMsg;

  /// No description provided for @genericError.
  ///
  /// In it, this message translates to:
  /// **'Errore: {error}'**
  String genericError(Object error);

  /// No description provided for @playButtonLabel.
  ///
  /// In it, this message translates to:
  /// **'RIPRODUCI'**
  String get playButtonLabel;

  /// No description provided for @tmdbInfoButtonLabel.
  ///
  /// In it, this message translates to:
  /// **'Info TMDB'**
  String get tmdbInfoButtonLabel;

  /// No description provided for @noEpisodesFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun episodio trovato.'**
  String get noEpisodesFound;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In it, this message translates to:
  /// **'Nuova versione disponibile: {version}'**
  String updateAvailableTitle(Object version);

  /// No description provided for @updateAvailableHeader.
  ///
  /// In it, this message translates to:
  /// **'È disponibile un nuovo aggiornamento!'**
  String get updateAvailableHeader;

  /// No description provided for @whatsNewHeader.
  ///
  /// In it, this message translates to:
  /// **'Novità in questa versione:'**
  String get whatsNewHeader;

  /// No description provided for @downloadButtonLabel.
  ///
  /// In it, this message translates to:
  /// **'Scarica'**
  String get downloadButtonLabel;

  /// No description provided for @ignoreButtonLabel.
  ///
  /// In it, this message translates to:
  /// **'Ignora'**
  String get ignoreButtonLabel;

  /// No description provided for @yearLabel.
  ///
  /// In it, this message translates to:
  /// **'Anno: {year}'**
  String yearLabel(Object year);

  /// No description provided for @stopAllButtonLabel.
  ///
  /// In it, this message translates to:
  /// **'INTERROMPI TUTTO'**
  String get stopAllButtonLabel;

  /// No description provided for @generateNfoTmdbLabel.
  ///
  /// In it, this message translates to:
  /// **'Genera NFO (TMDB)'**
  String get generateNfoTmdbLabel;

  /// No description provided for @sectionGenres.
  ///
  /// In it, this message translates to:
  /// **'GENERI'**
  String get sectionGenres;

  /// No description provided for @sectionCast.
  ///
  /// In it, this message translates to:
  /// **'CAST'**
  String get sectionCast;

  /// No description provided for @sectionDirectors.
  ///
  /// In it, this message translates to:
  /// **'Regia'**
  String get sectionDirectors;

  /// No description provided for @sectionPlot.
  ///
  /// In it, this message translates to:
  /// **'TRAMA'**
  String get sectionPlot;

  /// No description provided for @sectionSaga.
  ///
  /// In it, this message translates to:
  /// **'SAGA'**
  String get sectionSaga;

  /// No description provided for @sectionFile.
  ///
  /// In it, this message translates to:
  /// **'FILE'**
  String get sectionFile;

  /// No description provided for @sectionEpisodes.
  ///
  /// In it, this message translates to:
  /// **'EPISODI'**
  String get sectionEpisodes;

  /// No description provided for @pageOf.
  ///
  /// In it, this message translates to:
  /// **'Pagina {current} di {total}'**
  String pageOf(Object current, Object total);

  /// No description provided for @skipVideo.
  ///
  /// In it, this message translates to:
  /// **'Salta questo video'**
  String get skipVideo;

  /// No description provided for @untitled.
  ///
  /// In it, this message translates to:
  /// **'Senza Titolo'**
  String get untitled;

  /// No description provided for @scanTitle.
  ///
  /// In it, this message translates to:
  /// **'SCANSIONE CARTELLE'**
  String get scanTitle;

  /// No description provided for @scanDescription.
  ///
  /// In it, this message translates to:
  /// **'Scansiona le cartelle per aggiornare il database con i metadati dei video.\nCercherà automaticamente i file .nfo associati.'**
  String get scanDescription;

  /// No description provided for @scanStats.
  ///
  /// In it, this message translates to:
  /// **'📊 Statistiche Scansione'**
  String get scanStats;

  /// No description provided for @scanStatusReady.
  ///
  /// In it, this message translates to:
  /// **'Pronto per la scansione'**
  String get scanStatusReady;

  /// No description provided for @scanStatusInit.
  ///
  /// In it, this message translates to:
  /// **'Inizializzazione scansione...'**
  String get scanStatusInit;

  /// No description provided for @videosFoundCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessun video trovato} =1{1 video trovato} other{{count} video trovati}}'**
  String videosFoundCount(int count);

  /// No description provided for @scanSupportedExt.
  ///
  /// In it, this message translates to:
  /// **'Estensioni supportate: .mp4, .avi, .mkv, .mov, ...'**
  String get scanSupportedExt;

  /// No description provided for @genPlaylistTitle.
  ///
  /// In it, this message translates to:
  /// **'GENERA PLAYLIST (video presenti: {count})'**
  String genPlaylistTitle(Object count);

  /// No description provided for @btnRandom.
  ///
  /// In it, this message translates to:
  /// **'🎲 Playlist Casuale'**
  String get btnRandom;

  /// No description provided for @btnRecent.
  ///
  /// In it, this message translates to:
  /// **'🕒 Più Recenti'**
  String get btnRecent;

  /// No description provided for @btnFiltered.
  ///
  /// In it, this message translates to:
  /// **'🎲 Playlist\ncon Filtri'**
  String get btnFiltered;

  /// No description provided for @btnManual.
  ///
  /// In it, this message translates to:
  /// **'✏️ Selezione\nManuale'**
  String get btnManual;

  /// No description provided for @btnResetSession.
  ///
  /// In it, this message translates to:
  /// **'Resetta cronologia sessione ({count} visti)'**
  String btnResetSession(Object count);

  /// No description provided for @actionsTitle.
  ///
  /// In it, this message translates to:
  /// **'Azioni Playlist'**
  String get actionsTitle;

  /// No description provided for @btnShowPosters.
  ///
  /// In it, this message translates to:
  /// **'🎨 Mostra Poster'**
  String get btnShowPosters;

  /// No description provided for @btnExport.
  ///
  /// In it, this message translates to:
  /// **'💾 Esporta'**
  String get btnExport;

  /// No description provided for @openTempFolder.
  ///
  /// In it, this message translates to:
  /// **'Apri cartella file temporaneo'**
  String get openTempFolder;

  /// No description provided for @logTitle.
  ///
  /// In it, this message translates to:
  /// **'Log Comandi Remoti'**
  String get logTitle;

  /// No description provided for @logWaiting.
  ///
  /// In it, this message translates to:
  /// **'In attesa...'**
  String get logWaiting;

  /// No description provided for @logLast.
  ///
  /// In it, this message translates to:
  /// **'Ultimo: {command}'**
  String logLast(Object command);

  /// No description provided for @noPlaylist.
  ///
  /// In it, this message translates to:
  /// **'Nessuna playlist generata'**
  String get noPlaylist;

  /// No description provided for @videosCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessun video} =1{1 video} other{{count} video}}'**
  String videosCount(int count);

  /// No description provided for @currentPlaylist.
  ///
  /// In it, this message translates to:
  /// **'Playlist corrente: {count, plural, =0{nessun video} =1{1 video} other{{count} video}}'**
  String currentPlaylist(int count);

  /// No description provided for @playlistExported.
  ///
  /// In it, this message translates to:
  /// **'Playlist esportata in {path}'**
  String playlistExported(Object path);

  /// No description provided for @playerStarted.
  ///
  /// In it, this message translates to:
  /// **'Avviato player esterno: {name}'**
  String playerStarted(Object name);

  /// No description provided for @folderOpenError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile aprire la cartella: {error}'**
  String folderOpenError(Object error);

  /// No description provided for @inputCountTitle.
  ///
  /// In it, this message translates to:
  /// **'Numero di video'**
  String get inputCountTitle;

  /// No description provided for @inputCountLabel.
  ///
  /// In it, this message translates to:
  /// **'Quanti video vuoi includere?'**
  String get inputCountLabel;

  /// No description provided for @videoCreated.
  ///
  /// In it, this message translates to:
  /// **'Generata playlist di {count, plural, =0{nessun video} =1{1 video} other{{count} video}}.'**
  String videoCreated(int count);

  /// No description provided for @noVideoFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun video trovato!'**
  String get noVideoFound;

  /// No description provided for @filterTitle.
  ///
  /// In it, this message translates to:
  /// **'Filtri Avanzati Playlist'**
  String get filterTitle;

  /// No description provided for @resetFilters.
  ///
  /// In it, this message translates to:
  /// **'Resetta Filtri'**
  String get resetFilters;

  /// No description provided for @tabGeneral.
  ///
  /// In it, this message translates to:
  /// **'Generale'**
  String get tabGeneral;

  /// No description provided for @tabGenres.
  ///
  /// In it, this message translates to:
  /// **'Generi'**
  String get tabGenres;

  /// No description provided for @tabYears.
  ///
  /// In it, this message translates to:
  /// **'Anni'**
  String get tabYears;

  /// No description provided for @tabDirectors.
  ///
  /// In it, this message translates to:
  /// **'Registi'**
  String get tabDirectors;

  /// No description provided for @tabActors.
  ///
  /// In it, this message translates to:
  /// **'Attori'**
  String get tabActors;

  /// No description provided for @tabSagas.
  ///
  /// In it, this message translates to:
  /// **'Saghe'**
  String get tabSagas;

  /// No description provided for @generalSettings.
  ///
  /// In it, this message translates to:
  /// **'IMPOSTAZIONI GENERALI'**
  String get generalSettings;

  /// No description provided for @maxVideos.
  ///
  /// In it, this message translates to:
  /// **'Numero massimo di video:'**
  String get maxVideos;

  /// No description provided for @minRating.
  ///
  /// In it, this message translates to:
  /// **'Rating Minimo:'**
  String get minRating;

  /// No description provided for @filterByRating.
  ///
  /// In it, this message translates to:
  /// **'Filtra per rating ≥ {rating}'**
  String filterByRating(Object rating);

  /// No description provided for @summary.
  ///
  /// In it, this message translates to:
  /// **'Sommario'**
  String get summary;

  /// No description provided for @includedItemsCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessuno incluso} =1{1 incluso} other{{count} inclusi}}'**
  String includedItemsCount(int count);

  /// No description provided for @excludedItemsCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessuno escluso} =1{1 escluso} other{{count} esclusi}}'**
  String excludedItemsCount(int count);

  /// No description provided for @noActiveFilters.
  ///
  /// In it, this message translates to:
  /// **'Nessun filtro attivo'**
  String get noActiveFilters;

  /// No description provided for @videosFor.
  ///
  /// In it, this message translates to:
  /// **'Video per {title}: {value}'**
  String videosFor(Object title, Object value);

  /// No description provided for @foundVideos.
  ///
  /// In it, this message translates to:
  /// **'Trovati: {count, plural, =0{nessun video} =1{1 video} other{{count} video}}'**
  String foundVideos(int count);

  /// No description provided for @manualSelectionTitle.
  ///
  /// In it, this message translates to:
  /// **'Selezione Manuale Video'**
  String get manualSelectionTitle;

  /// No description provided for @searchHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca per titolo, anno, regista...'**
  String get searchHint;

  /// No description provided for @selectedItemsCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =0{Nessuno selezionato} =1{1 selezionato} other{{count} selezionati}}'**
  String selectedItemsCount(int count);

  /// No description provided for @visibleCount.
  ///
  /// In it, this message translates to:
  /// **'Totale visibili: {count, plural, =0{nessuno} =1{1} other{{count}}}'**
  String visibleCount(int count);

  /// No description provided for @selectAllVisible.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Tutti Visibili'**
  String get selectAllVisible;

  /// No description provided for @deselectAll.
  ///
  /// In it, this message translates to:
  /// **'Deseleziona Tutti'**
  String get deselectAll;

  /// No description provided for @createPlaylist.
  ///
  /// In it, this message translates to:
  /// **'Crea Playlist'**
  String get createPlaylist;

  /// No description provided for @bulkRenameTitle.
  ///
  /// In it, this message translates to:
  /// **'Rinomina Titoli in Massa'**
  String get bulkRenameTitle;

  /// No description provided for @bulkRenameMsg.
  ///
  /// In it, this message translates to:
  /// **'Questa operazione cercherà i file .nfo per ogni video e rinominerà i video nel formato \"Titolo (Anno)\".\n\nVerranno aggiornati sia il database che i metadati dei file video.\n\nL\'operazione potrebbe richiedere del tempo. Continuare?'**
  String get bulkRenameMsg;

  /// No description provided for @start.
  ///
  /// In it, this message translates to:
  /// **'Avvia'**
  String get start;

  /// No description provided for @renaming.
  ///
  /// In it, this message translates to:
  /// **'Rinomina in corso...'**
  String get renaming;

  /// No description provided for @processing.
  ///
  /// In it, this message translates to:
  /// **'Elaborazione:'**
  String get processing;

  /// No description provided for @tmdbGenTitle.
  ///
  /// In it, this message translates to:
  /// **'Generazione NFO da TMDB'**
  String get tmdbGenTitle;

  /// No description provided for @tmdbGenModeMsg.
  ///
  /// In it, this message translates to:
  /// **'Scegli la modalità di generazione:\n\n⚡ AUTOMATICO: Scarica il primo risultato trovato (più veloce).\n🖐️ INTERATTIVO: Ti chiede di confermare il film per ogni video trovato.'**
  String get tmdbGenModeMsg;

  /// No description provided for @tmdbGenAuto.
  ///
  /// In it, this message translates to:
  /// **'⚡ AUTOMATICO'**
  String get tmdbGenAuto;

  /// No description provided for @tmdbGenInteractive.
  ///
  /// In it, this message translates to:
  /// **'🖐️ INTERATTIVO'**
  String get tmdbGenInteractive;

  /// No description provided for @tmdbClickAuto.
  ///
  /// In it, this message translates to:
  /// **'⚡ Automatico'**
  String get tmdbClickAuto;

  /// No description provided for @tmdbClickInteractive.
  ///
  /// In it, this message translates to:
  /// **'🖐️ Interattivo'**
  String get tmdbClickInteractive;

  /// No description provided for @onlyMissingNfo.
  ///
  /// In it, this message translates to:
  /// **'Genera solo se manca il file .nfo'**
  String get onlyMissingNfo;

  /// No description provided for @downloadingInfo.
  ///
  /// In it, this message translates to:
  /// **'Scaricamento Info...'**
  String get downloadingInfo;

  /// No description provided for @genComplete.
  ///
  /// In it, this message translates to:
  /// **'Generazione Completata'**
  String get genComplete;

  /// No description provided for @genStats.
  ///
  /// In it, this message translates to:
  /// **'File creati: {created}\nSaltati/Non trovati: {skipped}\nErrori: {errors}'**
  String genStats(Object created, Object errors, Object skipped);

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In it, this message translates to:
  /// **'Conferma Eliminazione'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMsg.
  ///
  /// In it, this message translates to:
  /// **'Vuoi eliminare il video \"{title}\" dal database?\nIl file fisico non verrà rimosso.'**
  String confirmDeleteMsg(Object title);

  /// No description provided for @delete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get delete;

  /// No description provided for @videoDeleted.
  ///
  /// In it, this message translates to:
  /// **'Video eliminato dal database'**
  String get videoDeleted;

  /// No description provided for @confirmClearDb.
  ///
  /// In it, this message translates to:
  /// **'Vuoi cancellare TUTTI i dati dal database?'**
  String get confirmClearDb;

  /// No description provided for @yesDelete.
  ///
  /// In it, this message translates to:
  /// **'Si, Cancella'**
  String get yesDelete;

  /// No description provided for @dbCleared.
  ///
  /// In it, this message translates to:
  /// **'Database pulito!'**
  String get dbCleared;

  /// No description provided for @videoUpdated.
  ///
  /// In it, this message translates to:
  /// **'Video aggiornato correttamente'**
  String get videoUpdated;

  /// No description provided for @editVideoTitle.
  ///
  /// In it, this message translates to:
  /// **'Modifica Video'**
  String get editVideoTitle;

  /// No description provided for @loadFromNfo.
  ///
  /// In it, this message translates to:
  /// **'Carica da NFO'**
  String get loadFromNfo;

  /// No description provided for @downloadTmdb.
  ///
  /// In it, this message translates to:
  /// **'Scarica TMDB'**
  String get downloadTmdb;

  /// No description provided for @fileLabel.
  ///
  /// In it, this message translates to:
  /// **'File: {name}'**
  String fileLabel(Object name);

  /// No description provided for @pathLabel.
  ///
  /// In it, this message translates to:
  /// **'Percorso: {path}'**
  String pathLabel(Object path);

  /// No description provided for @sizeLabel.
  ///
  /// In it, this message translates to:
  /// **'Dimensione: {size}'**
  String sizeLabel(Object size);

  /// No description provided for @labelTitle.
  ///
  /// In it, this message translates to:
  /// **'Titolo'**
  String get labelTitle;

  /// No description provided for @labelYear.
  ///
  /// In it, this message translates to:
  /// **'Anno'**
  String get labelYear;

  /// No description provided for @labelDuration.
  ///
  /// In it, this message translates to:
  /// **'Durata (min)'**
  String get labelDuration;

  /// No description provided for @labelGenres.
  ///
  /// In it, this message translates to:
  /// **'Generi (separati da virgola)'**
  String get labelGenres;

  /// No description provided for @labelDirectors.
  ///
  /// In it, this message translates to:
  /// **'Registi'**
  String get labelDirectors;

  /// No description provided for @labelActors.
  ///
  /// In it, this message translates to:
  /// **'Attori (separati da virgola)'**
  String get labelActors;

  /// No description provided for @labelPoster.
  ///
  /// In it, this message translates to:
  /// **'Path Poster'**
  String get labelPoster;

  /// No description provided for @labelSaga.
  ///
  /// In it, this message translates to:
  /// **'Saga'**
  String get labelSaga;

  /// No description provided for @labelSagaIndex.
  ///
  /// In it, this message translates to:
  /// **'Indice Saga'**
  String get labelSagaIndex;

  /// No description provided for @labelPlot.
  ///
  /// In it, this message translates to:
  /// **'Trama'**
  String get labelPlot;

  /// No description provided for @ratingLabel.
  ///
  /// In it, this message translates to:
  /// **'Voto: {rating}'**
  String ratingLabel(Object rating);

  /// No description provided for @updateDbOnly.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna solo DB'**
  String get updateDbOnly;

  /// No description provided for @saveAll.
  ///
  /// In it, this message translates to:
  /// **'Salva tutto (File + DB)'**
  String get saveAll;

  /// No description provided for @requiredField.
  ///
  /// In it, this message translates to:
  /// **'Campo obbligatorio'**
  String get requiredField;

  /// No description provided for @dbUpdatedMsg.
  ///
  /// In it, this message translates to:
  /// **'Database aggiornato (senza toccare il file video)'**
  String get dbUpdatedMsg;

  /// No description provided for @fileUpdateMsg.
  ///
  /// In it, this message translates to:
  /// **'Aggiornamento file in corso...'**
  String get fileUpdateMsg;

  /// No description provided for @successUpdateMsg.
  ///
  /// In it, this message translates to:
  /// **'File e Database aggiornati con successo!'**
  String get successUpdateMsg;

  /// No description provided for @errorUpdateMsg.
  ///
  /// In it, this message translates to:
  /// **'Errore aggiornamento file (Database comunque aggiornato)'**
  String get errorUpdateMsg;

  /// No description provided for @nfoLoadedMsg.
  ///
  /// In it, this message translates to:
  /// **'Dati caricati dal file .nfo!'**
  String get nfoLoadedMsg;

  /// No description provided for @nfoNotFoundMsg.
  ///
  /// In it, this message translates to:
  /// **'File .nfo non trovato.'**
  String get nfoNotFoundMsg;

  /// No description provided for @nfoErrorMsg.
  ///
  /// In it, this message translates to:
  /// **'Errore nel parsing del file .nfo.'**
  String get nfoErrorMsg;

  /// No description provided for @tmdbUpdatedMsg.
  ///
  /// In it, this message translates to:
  /// **'Dati aggiornati da TMDB (NFO e asset creati)'**
  String get tmdbUpdatedMsg;

  /// No description provided for @seriesLabel.
  ///
  /// In it, this message translates to:
  /// **'SERIE'**
  String get seriesLabel;

  /// No description provided for @ok.
  ///
  /// In it, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @no.
  ///
  /// In it, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noCommandsMsg.
  ///
  /// In it, this message translates to:
  /// **'Nessun comando trovato.'**
  String get noCommandsMsg;

  /// No description provided for @noVideoInDb.
  ///
  /// In it, this message translates to:
  /// **'Nessun video nel database.'**
  String get noVideoInDb;

  /// No description provided for @sagaTooltip.
  ///
  /// In it, this message translates to:
  /// **'Il nome della collezione di film (es. Star Wars Collection)'**
  String get sagaTooltip;

  /// No description provided for @sagaIndexTooltip.
  ///
  /// In it, this message translates to:
  /// **'L\'ordine del film nella collezione (1, 2, 3...)'**
  String get sagaIndexTooltip;

  /// No description provided for @infoTitle.
  ///
  /// In it, this message translates to:
  /// **'Informazioni'**
  String get infoTitle;

  /// No description provided for @playlistCreator.
  ///
  /// In it, this message translates to:
  /// **'Creatore Playlist'**
  String get playlistCreator;

  /// No description provided for @tmdbGenModeTitle.
  ///
  /// In it, this message translates to:
  /// **'Modalità Generazione TMDB'**
  String get tmdbGenModeTitle;

  /// No description provided for @cancelling.
  ///
  /// In it, this message translates to:
  /// **'Annullamento...'**
  String get cancelling;

  /// No description provided for @paramsNone.
  ///
  /// In it, this message translates to:
  /// **'Nessun parametro'**
  String get paramsNone;

  /// No description provided for @paramsLabel.
  ///
  /// In it, this message translates to:
  /// **'Parametri: {params}'**
  String paramsLabel(Object params);

  /// No description provided for @author.
  ///
  /// In it, this message translates to:
  /// **'Autore'**
  String get author;

  /// No description provided for @buildDate.
  ///
  /// In it, this message translates to:
  /// **'Data redazione'**
  String get buildDate;

  /// No description provided for @scanInProgress.
  ///
  /// In it, this message translates to:
  /// **'Scansione in corso...'**
  String get scanInProgress;

  /// No description provided for @selectFolderToScan.
  ///
  /// In it, this message translates to:
  /// **'Seleziona cartella da scansionare'**
  String get selectFolderToScan;

  /// No description provided for @included.
  ///
  /// In it, this message translates to:
  /// **'Inclusioni: {inclusions}'**
  String included(Object inclusions);

  /// No description provided for @excluded.
  ///
  /// In it, this message translates to:
  /// **'Esclusioni: {exclusions}'**
  String excluded(Object exclusions);

  /// No description provided for @scanFinishedMsg.
  ///
  /// In it, this message translates to:
  /// **'Scansione terminata. Trovati {count} nuovi video.'**
  String scanFinishedMsg(Object count);

  /// No description provided for @appearanceHeader.
  ///
  /// In it, this message translates to:
  /// **'ASPETTO'**
  String get appearanceHeader;

  /// No description provided for @langIt.
  ///
  /// In it, this message translates to:
  /// **'Italiano'**
  String get langIt;

  /// No description provided for @langEn.
  ///
  /// In it, this message translates to:
  /// **'Inglese'**
  String get langEn;

  /// No description provided for @playlistHeader.
  ///
  /// In it, this message translates to:
  /// **'PLAYLIST'**
  String get playlistHeader;

  /// No description provided for @defaultPlaylistSizeHelp.
  ///
  /// In it, this message translates to:
  /// **'Numero di video proposti di default alla creazione di una playlist'**
  String get defaultPlaylistSizeHelp;

  /// No description provided for @checkButton.
  ///
  /// In it, this message translates to:
  /// **'Controlla'**
  String get checkButton;

  /// No description provided for @tmdbHeader.
  ///
  /// In it, this message translates to:
  /// **'TMDB (THE MOVIE DATABASE)'**
  String get tmdbHeader;

  /// No description provided for @executableHeader.
  ///
  /// In it, this message translates to:
  /// **'ESEGUIBILE'**
  String get executableHeader;

  /// No description provided for @vlcRemoteHeader.
  ///
  /// In it, this message translates to:
  /// **'CONTROLLO REMOTO VLC'**
  String get vlcRemoteHeader;

  /// No description provided for @serverStatusHeader.
  ///
  /// In it, this message translates to:
  /// **'STATO SERVER'**
  String get serverStatusHeader;

  /// No description provided for @selectDestinationFolder.
  ///
  /// In it, this message translates to:
  /// **'Seleziona cartella di destinazione'**
  String get selectDestinationFolder;

  /// No description provided for @selectBackupFile.
  ///
  /// In it, this message translates to:
  /// **'Seleziona file di backup (.db)'**
  String get selectBackupFile;

  /// No description provided for @eventLogHeader.
  ///
  /// In it, this message translates to:
  /// **'REGISTRO EVENTI'**
  String get eventLogHeader;

  /// No description provided for @updateError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante il controllo aggiornamenti: {error}'**
  String updateError(Object error);

  /// No description provided for @databaseManagementTitle.
  ///
  /// In it, this message translates to:
  /// **'GESTIONE DATABASE'**
  String get databaseManagementTitle;

  /// No description provided for @videosInDatabase.
  ///
  /// In it, this message translates to:
  /// **'🎬 {count, plural, =0{Nessun video} =1{1 video} other{{count} video}} nel database'**
  String videosInDatabase(int count);

  /// No description provided for @searchVideosPlaceholder.
  ///
  /// In it, this message translates to:
  /// **'Cerca video...'**
  String get searchVideosPlaceholder;

  /// No description provided for @noVideosFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun video trovato.'**
  String get noVideosFound;

  /// No description provided for @clearDatabaseButton.
  ///
  /// In it, this message translates to:
  /// **'Pulisci Database'**
  String get clearDatabaseButton;

  /// No description provided for @refreshButton.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna'**
  String get refreshButton;

  /// No description provided for @renameTitlesButton.
  ///
  /// In it, this message translates to:
  /// **'Rinomina Titoli'**
  String get renameTitlesButton;

  /// No description provided for @editTooltip.
  ///
  /// In it, this message translates to:
  /// **'Modifica'**
  String get editTooltip;

  /// No description provided for @deleteTooltip.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get deleteTooltip;

  /// No description provided for @opCancelled.
  ///
  /// In it, this message translates to:
  /// **'Operazione Annullata'**
  String get opCancelled;

  /// No description provided for @opCompleted.
  ///
  /// In it, this message translates to:
  /// **'Operazione Completata'**
  String get opCompleted;

  /// No description provided for @bulkOpStats.
  ///
  /// In it, this message translates to:
  /// **'Aggiornati: {updated}\nSaltati: {skipped}\nErrori: {errors}'**
  String bulkOpStats(Object errors, Object skipped, Object updated);

  /// No description provided for @openGitHubLabel.
  ///
  /// In it, this message translates to:
  /// **'Apri GitHub'**
  String get openGitHubLabel;

  /// No description provided for @statsTotalVideos.
  ///
  /// In it, this message translates to:
  /// **'Totale Video'**
  String get statsTotalVideos;

  /// No description provided for @statsMovies.
  ///
  /// In it, this message translates to:
  /// **'Film'**
  String get statsMovies;

  /// No description provided for @statsSeries.
  ///
  /// In it, this message translates to:
  /// **'Serie TV'**
  String get statsSeries;

  /// No description provided for @statsAvgRating.
  ///
  /// In it, this message translates to:
  /// **'Voto Medio'**
  String get statsAvgRating;

  /// No description provided for @statsTopGenres.
  ///
  /// In it, this message translates to:
  /// **'Generi Top'**
  String get statsTopGenres;

  /// No description provided for @statsVideosByYear.
  ///
  /// In it, this message translates to:
  /// **'Video per Anno'**
  String get statsVideosByYear;

  /// No description provided for @statsTopSagas.
  ///
  /// In it, this message translates to:
  /// **'Saghe/Collezioni Top'**
  String get statsTopSagas;

  /// No description provided for @exportPlaylistTitle.
  ///
  /// In it, this message translates to:
  /// **'Esporta Playlist'**
  String get exportPlaylistTitle;

  /// No description provided for @tabStatistics.
  ///
  /// In it, this message translates to:
  /// **'Statistiche'**
  String get tabStatistics;

  /// No description provided for @settingsAutoSync.
  ///
  /// In it, this message translates to:
  /// **'Auto-Sync'**
  String get settingsAutoSync;

  /// No description provided for @settingsAutoSyncSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Monitora automaticamente le cartelle scansionate per modifiche'**
  String get settingsAutoSyncSubtitle;

  /// No description provided for @settingsWatchedFolders.
  ///
  /// In it, this message translates to:
  /// **'Cartelle Monitorate'**
  String get settingsWatchedFolders;

  /// No description provided for @settingsNoWatchedFolders.
  ///
  /// In it, this message translates to:
  /// **'Nessuna cartella monitorata'**
  String get settingsNoWatchedFolders;

  /// No description provided for @fanartApiKey.
  ///
  /// In it, this message translates to:
  /// **'Fanart.tv API Key'**
  String get fanartApiKey;

  /// No description provided for @settingsAutoSyncNfo.
  ///
  /// In it, this message translates to:
  /// **'Sincronizza NFO su modifica'**
  String get settingsAutoSyncNfo;

  /// No description provided for @settingsAutoSyncNfoSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Salva automaticamente i metadati nel file .nfo quando modifichi un video'**
  String get settingsAutoSyncNfoSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
