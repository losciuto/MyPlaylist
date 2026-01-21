// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MyPlaylist';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get generalTab => 'General';

  @override
  String get metadataTab => 'Rating';

  @override
  String get playerTab => 'Player';

  @override
  String get remoteTab => 'Remote Control';

  @override
  String get maintenanceTab => 'Maintenance';

  @override
  String get debugTab => 'Debug Log';

  @override
  String get themeMode => 'Theme';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get videosPerPage => 'Videos per page';

  @override
  String get tmdbApiKey => 'TMDB API Key';

  @override
  String get tmdbApiKeyHint => 'Enter your TMDB API Key';

  @override
  String get tmdbInfo => 'API Key is required to fetch missing metadata.';

  @override
  String get playerPath => 'Player Path';

  @override
  String get playerSelection => 'Player Selection';

  @override
  String get playerPreset => 'Player Preset';

  @override
  String get autoDetectPlayer => 'Auto-Detect';

  @override
  String get customPlayer => 'Custom Player';

  @override
  String get testPlayer => 'Test Player';

  @override
  String playerDetected(String name) {
    return 'Player detected: $name';
  }

  @override
  String get playerNotFound => 'No player found. Please configure manually.';

  @override
  String get playerTested => 'Player tested successfully!';

  @override
  String get playerTestFailed => 'Failed to launch player. Check the path.';

  @override
  String get vlcPort => 'VLC RC Port';

  @override
  String get serverEnabled => 'Enable Server';

  @override
  String get serverPort => 'Server Port';

  @override
  String get securityKey => 'Security Key (PSK)';

  @override
  String get listenInterface => 'Listen Interface';

  @override
  String get backupDatabase => 'Backup Database';

  @override
  String get backupDescription => 'Save a security copy of the database.';

  @override
  String get exportButton => 'Export Backup';

  @override
  String get restoreDatabase => 'Restore Database';

  @override
  String get restoreDescription => 'Restore database from a previous file.';

  @override
  String get importButton => 'Import Backup';

  @override
  String get confirmRestoreTitle => 'Confirm Restore';

  @override
  String get confirmRestoreMsg =>
      'Are you sure you want to overwrite the current database? This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get dbRestoredMsg => 'Database restored successfully!';

  @override
  String errorMsg(Object error) {
    return 'Error: $error';
  }

  @override
  String get updates => 'Updates';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String currentVersion(Object version) {
    return 'Current version: $version';
  }

  @override
  String get noUpdates =>
      'No updates available. You are on the latest version!';

  @override
  String get language => 'Language';

  @override
  String get eventLog => 'EVENT LOG';

  @override
  String get refreshLog => 'Refresh Log';

  @override
  String get copyLog => 'Copy Log';

  @override
  String get clearLog => 'Clear Log';

  @override
  String get logCopied => 'Logs copied to clipboard';

  @override
  String get logCleared => 'Logs cleared';

  @override
  String get noLogs => 'No logs available.';

  @override
  String logError(Object error) {
    return 'Error loading logs: $error';
  }

  @override
  String logFile(Object path) {
    return 'File: $path';
  }

  @override
  String get navDatabase => 'Manage DB';

  @override
  String get navPlaylist => 'Playlist';

  @override
  String get navScan => 'Scan';

  @override
  String get colTitle => 'Title';

  @override
  String get colPath => 'Path';

  @override
  String get colDuration => 'Duration';

  @override
  String get colYear => 'Year';

  @override
  String get colRating => 'Rating';

  @override
  String get colSaga => 'Saga';

  @override
  String get colDirectors => 'Directors';

  @override
  String get colGenres => 'Genres';

  @override
  String get colActions => 'Actions';

  @override
  String get searchPlaceholder => 'Search...';

  @override
  String get btnScan => 'Scan Folder';

  @override
  String get btnSelectFolder => 'Select Folder';

  @override
  String get remoteControlSubtitle =>
      'Allows controlling the app via local network';

  @override
  String get networkHeader => 'NETWORK';

  @override
  String get securityHeader => 'SECURITY';

  @override
  String get backupRestoreHeader => 'BACKUP AND RESTORE';

  @override
  String backupSuccessMsg(Object path) {
    return 'Backup saved successfully at:\n$path';
  }

  @override
  String backupErrorMsg(Object error) {
    return 'Backup error: $error';
  }

  @override
  String get invalidDbMsg => 'Please select a valid .db file.';

  @override
  String get dbNotFoundMsg => 'Database not found!';

  @override
  String restoreErrorMsg(Object error) {
    return 'Restore error: $error';
  }

  @override
  String get tmdbApiKeyMissing => 'TMDB API Key missing!';

  @override
  String get tmdbNoResults => 'No results found on TMDB.';

  @override
  String get selectMovieTitle => 'Select Movie';

  @override
  String get tmdbSuccessMsg =>
      'Info downloaded successfully! Restart scan to update.';

  @override
  String genericError(Object error) {
    return 'Error: $error';
  }

  @override
  String get playButtonLabel => 'PLAY';

  @override
  String get tmdbInfoButtonLabel => 'TMDB Info';

  @override
  String get noEpisodesFound => 'No episodes found.';

  @override
  String updateAvailableTitle(Object version) {
    return 'New version available: $version';
  }

  @override
  String get updateAvailableHeader => 'A new update is available!';

  @override
  String get whatsNewHeader => 'What\'s new in this version:';

  @override
  String get downloadButtonLabel => 'Download';

  @override
  String get ignoreButtonLabel => 'Ignore';

  @override
  String yearLabel(Object year) {
    return 'Year: $year';
  }

  @override
  String get stopAllButtonLabel => 'STOP ALL';

  @override
  String get generateNfoTmdbLabel => 'Generate NFO (TMDB)';

  @override
  String get sectionGenres => 'GENRES';

  @override
  String get sectionCast => 'CAST';

  @override
  String get sectionPlot => 'PLOT';

  @override
  String get sectionSaga => 'SAGA';

  @override
  String get sectionFile => 'FILE';

  @override
  String get sectionEpisodes => 'EPISODES';

  @override
  String pageOf(Object current, Object total) {
    return 'Page $current of $total';
  }

  @override
  String get skipVideo => 'Skip this video';

  @override
  String get untitled => 'Untitled';

  @override
  String get scanTitle => 'FOLDER SCAN';

  @override
  String get scanDescription =>
      'Scan folders to update the database with video metadata.\nIt will automatically search for associated .nfo files.';

  @override
  String get scanStats => '📊 Scan Statistics';

  @override
  String get scanStatusReady => 'Ready to scan';

  @override
  String get scanStatusInit => 'Initializing scan...';

  @override
  String videosFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos found',
      one: '1 video found',
      zero: 'No videos found',
    );
    return '$_temp0';
  }

  @override
  String get scanSupportedExt =>
      'Supported extensions: .mp4, .avi, .mkv, .mov, ...';

  @override
  String genPlaylistTitle(Object count) {
    return 'GENERATE PLAYLIST (videos: $count)';
  }

  @override
  String get btnRandom => '🎲 Random Playlist';

  @override
  String get btnRecent => '🕒 Most Recent';

  @override
  String get btnFiltered => '🎲 Filtered\nPlaylist';

  @override
  String get btnManual => '✏️ Manual\nSelection';

  @override
  String btnResetSession(Object count) {
    return 'Reset session history ($count watched)';
  }

  @override
  String get actionsTitle => 'Playlist Actions';

  @override
  String get btnShowPosters => '🎨 Show Posters';

  @override
  String get btnExport => '💾 Export';

  @override
  String get openTempFolder => 'Open temp file folder';

  @override
  String get logTitle => 'Remote Command Logs';

  @override
  String get logWaiting => 'Waiting...';

  @override
  String logLast(Object command) {
    return 'Last: $command';
  }

  @override
  String get noPlaylist => 'No playlist generated';

  @override
  String videosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
      zero: 'No videos',
    );
    return '$_temp0';
  }

  @override
  String currentPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
      zero: 'no videos',
    );
    return 'Current playlist: $_temp0';
  }

  @override
  String playlistExported(Object path) {
    return 'Playlist exported to $path';
  }

  @override
  String playerStarted(Object name) {
    return 'External player started: $name';
  }

  @override
  String folderOpenError(Object error) {
    return 'Cannot open folder: $error';
  }

  @override
  String get inputCountTitle => 'Number of videos';

  @override
  String get inputCountLabel => 'How many videos to include?';

  @override
  String videoCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
      zero: 'no videos',
    );
    return 'Generated playlist of $_temp0.';
  }

  @override
  String get noVideoFound => 'No videos found!';

  @override
  String get filterTitle => 'Advanced Playlist Filters';

  @override
  String get resetFilters => 'Reset Filters';

  @override
  String get tabGeneral => 'General';

  @override
  String get tabGenres => 'Genres';

  @override
  String get tabYears => 'Years';

  @override
  String get tabDirectors => 'Directors';

  @override
  String get tabActors => 'Actors';

  @override
  String get tabSagas => 'Sagas';

  @override
  String get generalSettings => 'GENERAL SETTINGS';

  @override
  String get maxVideos => 'Maximum number of videos:';

  @override
  String get minRating => 'Minimum Rating:';

  @override
  String filterByRating(Object rating) {
    return 'Filter by rating ≥ $rating';
  }

  @override
  String get summary => 'Summary';

  @override
  String includedItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count included',
      one: '1 included',
      zero: 'None included',
    );
    return '$_temp0';
  }

  @override
  String excludedItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count excluded',
      one: '1 excluded',
      zero: 'None excluded',
    );
    return '$_temp0';
  }

  @override
  String get noActiveFilters => 'No active filters';

  @override
  String videosFor(Object title, Object value) {
    return 'Videos for $title: $value';
  }

  @override
  String foundVideos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
      zero: 'no videos',
    );
    return 'Found: $_temp0';
  }

  @override
  String get manualSelectionTitle => 'Manual Video Selection';

  @override
  String get searchHint => 'Search by title, year, director...';

  @override
  String selectedItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
      zero: 'None selected',
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
      zero: 'none',
    );
    return 'Total visible: $_temp0';
  }

  @override
  String get selectAllVisible => 'Select All Visible';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get createPlaylist => 'Create Playlist';

  @override
  String get bulkRenameTitle => 'Bulk Rename Titles';

  @override
  String get bulkRenameMsg =>
      'This operation will search for .nfo files for each video and rename videos to the format \"Title (Year)\".\n\nBoth database and video file metadata will be updated.\n\nThe operation may take some time. Continue?';

  @override
  String get start => 'Start';

  @override
  String get renaming => 'Renaming in progress...';

  @override
  String get processing => 'Processing:';

  @override
  String get tmdbGenTitle => 'TMDB NFO Generation';

  @override
  String get tmdbGenModeMsg =>
      'Choose generation mode:\n\n⚡ AUTOMATIC: Download the first result found (fastest).\n🖐️ INTERACTIVE: Ask to confirm the movie for each video found.';

  @override
  String get tmdbGenAuto => '⚡ AUTOMATIC';

  @override
  String get tmdbGenInteractive => '🖐️ INTERACTIVE';

  @override
  String get tmdbClickAuto => '⚡ Automatic';

  @override
  String get tmdbClickInteractive => '🖐️ Interactive';

  @override
  String get onlyMissingNfo => 'Generate only if .nfo is missing';

  @override
  String get downloadingInfo => 'Downloading Info...';

  @override
  String get genComplete => 'Generation Completed';

  @override
  String genStats(Object created, Object errors, Object skipped) {
    return 'Files created: $created\nSkipped/Not found: $skipped\nErrors: $errors';
  }

  @override
  String get confirmDeleteTitle => 'Confirm Deletion';

  @override
  String confirmDeleteMsg(Object title) {
    return 'Do you want to delete video \"$title\" from database?\nThe physical file will not be removed.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get videoDeleted => 'Video deleted from database';

  @override
  String get confirmClearDb =>
      'Do you want to delete ALL data from the database?';

  @override
  String get yesDelete => 'Yes, Delete';

  @override
  String get dbCleared => 'Database cleared!';

  @override
  String get videoUpdated => 'Video updated successfully';

  @override
  String get editVideoTitle => 'Edit Video';

  @override
  String get loadFromNfo => 'Load from NFO';

  @override
  String get downloadTmdb => 'Download TMDB';

  @override
  String fileLabel(Object name) {
    return 'File: $name';
  }

  @override
  String pathLabel(Object path) {
    return 'Path: $path';
  }

  @override
  String sizeLabel(Object size) {
    return 'Size: $size';
  }

  @override
  String get labelTitle => 'Title';

  @override
  String get labelYear => 'Year';

  @override
  String get labelDuration => 'Duration (min)';

  @override
  String get labelGenres => 'Genres (comma separated)';

  @override
  String get labelDirectors => 'Directors';

  @override
  String get labelActors => 'Actors (comma separated)';

  @override
  String get labelPoster => 'Poster Path';

  @override
  String get labelSaga => 'Saga';

  @override
  String get labelSagaIndex => 'Saga Index';

  @override
  String get labelPlot => 'Plot';

  @override
  String ratingLabel(Object rating) {
    return 'Rating: $rating';
  }

  @override
  String get updateDbOnly => 'Update DB only';

  @override
  String get saveAll => 'Save all (File + DB)';

  @override
  String get requiredField => 'Required field';

  @override
  String get dbUpdatedMsg => 'Database updated (video file untouched)';

  @override
  String get fileUpdateMsg => 'Updating file...';

  @override
  String get successUpdateMsg => 'File and Database updated successfully!';

  @override
  String get errorUpdateMsg => 'File update error (Database updated anyway)';

  @override
  String get nfoLoadedMsg => 'Data loaded from .nfo file!';

  @override
  String get nfoNotFoundMsg => 'File .nfo not found.';

  @override
  String get nfoErrorMsg => 'Error parsing .nfo file.';

  @override
  String get tmdbUpdatedMsg =>
      'Data updated from TMDB (NFO and assets created)';

  @override
  String get seriesLabel => 'SERIES';

  @override
  String get ok => 'OK';

  @override
  String get no => 'No';

  @override
  String get noCommandsMsg => 'No commands found.';

  @override
  String get noVideoInDb => 'No videos in database.';

  @override
  String get sagaTooltip =>
      'The name of the movie collection (e.g. Star Wars Collection)';

  @override
  String get sagaIndexTooltip =>
      'The order of the movie in the collection (1, 2, 3...)';

  @override
  String get infoTitle => 'Information';

  @override
  String get playlistCreator => 'Playlist Creator';

  @override
  String get tmdbGenModeTitle => 'TMDB Generation Mode';

  @override
  String get cancelling => 'Cancelling...';

  @override
  String get paramsNone => 'No parameters';

  @override
  String paramsLabel(Object params) {
    return 'Parameters: $params';
  }

  @override
  String get author => 'Author';

  @override
  String get buildDate => 'Build Date';

  @override
  String get scanInProgress => 'Scan in progress...';

  @override
  String get selectFolderToScan => 'Select folder to scan';

  @override
  String included(Object inclusions) {
    return 'Included: $inclusions';
  }

  @override
  String excluded(Object exclusions) {
    return 'Excluded: $exclusions';
  }

  @override
  String scanFinishedMsg(Object count) {
    return 'Scan finished. Found $count new videos.';
  }

  @override
  String get appearanceHeader => 'APPEARANCE';

  @override
  String get langIt => 'Italian';

  @override
  String get langEn => 'English';

  @override
  String get playlistHeader => 'PLAYLIST';

  @override
  String get defaultPlaylistSizeHelp =>
      'Default number of videos to propose when creating a playlist';

  @override
  String get checkButton => 'Check';

  @override
  String get tmdbHeader => 'TMDB (THE MOVIE DATABASE)';

  @override
  String get executableHeader => 'EXECUTABLE';

  @override
  String get vlcRemoteHeader => 'VLC REMOTE CONTROL';

  @override
  String get serverStatusHeader => 'SERVER STATUS';

  @override
  String get selectDestinationFolder => 'Select destination folder';

  @override
  String get selectBackupFile => 'Select backup file (.db)';

  @override
  String get eventLogHeader => 'EVENT LOG';

  @override
  String updateError(Object error) {
    return 'Error checking for updates: $error';
  }

  @override
  String get databaseManagementTitle => 'DATABASE MANAGEMENT';

  @override
  String videosInDatabase(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
      zero: 'No videos',
    );
    return '🎬 $_temp0 in database';
  }

  @override
  String get searchVideosPlaceholder => 'Search videos...';

  @override
  String get noVideosFound => 'No videos found.';

  @override
  String get clearDatabaseButton => 'Clear Database';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get renameTitlesButton => 'Rename Titles';

  @override
  String get editTooltip => 'Edit';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get opCancelled => 'Operation Cancelled';

  @override
  String get opCompleted => 'Operation Completed';

  @override
  String bulkOpStats(Object errors, Object skipped, Object updated) {
    return 'Updated: $updated\nSkipped: $skipped\nErrors: $errors';
  }

  @override
  String get openGitHubLabel => 'Open GitHub';

  @override
  String get statsTotalVideos => 'Total Videos';

  @override
  String get statsMovies => 'Movies';

  @override
  String get statsSeries => 'Series';

  @override
  String get statsAvgRating => 'Avg Rating';

  @override
  String get statsTopGenres => 'Top Genres';

  @override
  String get statsVideosByYear => 'Videos by Year';

  @override
  String get statsTopSagas => 'Top Sagas/Collections';

  @override
  String get exportPlaylistTitle => 'Export Playlist';

  @override
  String get tabStatistics => 'Statistics';

  @override
  String get settingsAutoSync => 'Auto-Sync';

  @override
  String get settingsAutoSyncSubtitle =>
      'Automatically watch scanned folders for changes';

  @override
  String get settingsWatchedFolders => 'Watched Folders';

  @override
  String get settingsNoWatchedFolders => 'No folders being watched';

  @override
  String get fanartApiKey => 'Fanart.tv API Key';
}
