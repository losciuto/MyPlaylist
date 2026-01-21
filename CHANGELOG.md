# Changelog

All notable changes to this project will be documented in this file.
## [3.4.0] - 2026-01-21

### Added
- **Auto-Sync**: Background file watcher to automatically detect new videos and sync them to the database. Includes customizable watched folders in Settings.
- **Fanart.tv Integration**: Fetch high-quality logos, clearart, and disc art for movies.
- **Table Virtualization**: Drastically improved database table performance for large collections using optimized virtualization (`ListView.builder`).
- **Linux Code Signing**: Support for GPG signing in CI/CD pipeline.

### Fixed
- **Edit Dialog**: Resolved layout crashes ("render box no size") and improved responsive layout for the editing window.
- **Critical Layout**: Fixed infinite height issue with `Expanded` widgets inside scroll views.



### Added
- **TV Series Management**: Implemented series folder handling. Folders containing "Series", "Serie", "Seriale", "TV Show", or a `tvshow.nfo` file are now treated as a single entity in the database.
    - **NFO Generation**: Added support for creating `tvshow.nfo` and standard assets (`poster.jpg`, `fanart.jpg`, `clearlogo.png`) for series.
    - **Recursive Metadata Sync**: Bulk renaming and metadata updates now propagate to all episodes in a series folder.
    - **Smart Episode Titles**: Automated title formatting for episodes (e.g., "Series - S01E01 Episode Title") with noise cleaning.
    - **Plot Propagation**: Series plot is automatically written to the metadata of all individual episode files.
- **Enhanced UI**:
    - **Uniform Manual Selection**: Refactored the list to be consistent; detailed series info and episode selection are now in the standard Preview Dialog.
    - **Series Badges**: Visual indicators (TV icon and badges) in Database management, Grid, and Selection dialogs.
- **Bulk Series Operations**: Extended bulk rename and NFO generation to support television content type.
- **Database Schema v2**: Updated database to support the new "Series" content type with automatic migration.

## [2.9.0] - 2026-01-02

### Added
- **Delete Video Record**: Added a delete icon button to the Database Management tab to remove individual video records from the database.
- **NFO Generation Filter**: New option "Generate only if missing .nfo" in the bulk NFO generation dialog to avoid overwriting existing metadata.

## [2.8.0] - 2025-12-31

### Added
- **Exclusion Filters**: Implemented tri-state selection (Include/Exclude/None) in the filter dialog for genres, years, actors, and directors.
- **SQL Exclusion Logic**: Updated database queries to support negative matching for playlist generation.
- **Improved UI for Filters**: Custom tri-state toggle widget for a better user experience in advanced filtering.


## [2.7.0] - 2025-12-23

### Added
- **Power Parser for Ratings**: Implemented dual-strategy (XML DOM + Regex) rating extraction from NFO files.
- **NFO Naming Fallback**: Added support for `movie.nfo` when video-specific NFO files are not found.
- **Rating Visibility**: Added rating display to Database Management table, Poster Grid, and Manual Selection dialog.

### Fixed
- **Zero Rating Bug**: Resolved issue where all videos displayed 0.0 ratings despite having valid data in NFO files.
- **Nested Tag Support**: Improved parser to handle complex Kodi-style `<ratings>` structures with `default="true"` attributes.

## [2.6.1] - 2025-12-21

- Documentation update and version synchronization.

## [2.6.0] - 2025-12-21

### Added

- **"Echo-Safe" Remote Control Protocol**: Implemented mutual exclusion and echo filtering in the control server for interference-free client-server communication.
- **Playlist Preview**: New remote command (`preview`) allowing clients to receive the list of generated titles without immediately starting the player.
- **Advanced VLC Management**: Optimized VLC process management for more reliable startup and shutdown.

### Added
- **Session Exclusion**: Random playlist generation (including filters) now excludes videos already proposed during the current session.
*   **Advanced UI**: Tooltips for long titles and real-time processing title display during renaming.
*   **Series Management**: Automatic detection of TV series folders (based on names like "Series", "Serie", "Seriale" or `tvshow.nfo` files) for sequential playback.
- **Tooltips**: Added tooltips to the database table to view the full title of truncated entries.

### Fixed
- Refined rename skip logic to be fully case-insensitive and more robust.

## [2.5.0] - 2025-12-20

### Added
- "Bulk Title Rename" functionality in the DB Management tab.
- Detailed progress dialog for bulk operations.
- Ability to cancel bulk renaming with automatic temporary file cleanup.
- Support for auto-killing previous VLC instances before playback.
- Info Dialog with version and build date.

### Improved
- Drastic performance optimization for database updates (UI refreshes only at the end of the process).
- Intelligent skip logic for renaming: correctly updated videos are automatically skipped.
- NFO Metadata Handling: More robust extraction of title, year, genres, actors, directors, and plot.
- Initial Navigation: The app now opens on the 'Generate Playlist' tab if videos are already present in the database.

### Fixed
- Fixed bug in title comparison logic that caused unnecessary updates on already correct files.
- Internal player codec handling: improved stability and added suggestions for external players in case of incompatibility.

## [1.1.0] - 2025-12-14
- Initial stable release with Database support and Playlist Generation.
