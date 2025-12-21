# Changelog

All notable changes to this project will be documented in this file.

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
