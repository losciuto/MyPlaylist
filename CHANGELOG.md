# Changelog

All notable changes to this project will be documented in this file.

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
- **Real-time Processing Title**: The bulk rename dialog now displays the title of the video currently being processed.
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
