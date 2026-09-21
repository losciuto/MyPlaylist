# MyPlaylist Release Notes

## Version 3.14.1 — 2026-04-01

### Changed
- **Migration Strategy**: Fixed legacy database migration from schema 5 to 6. The `is_series` column check now uses the correct SQL column name (not camelCase). Added defensive check before attempting to add the column.
- **Index Fix**: Corrected `videos_isseries_idx` to use `is_series` (SQL name) instead of `isSeries` (camelCase).

---

## Version 3.14.0 — 2026-04-01

### New Features
- **Processing Reason Feedback**: Added detailed technical reasons (e.g. "Fast Engine Disabled", "Metadata Sync") to the Bulk Processing dialog for better transparency, matching the Metadata Sync experience.

### Bug Fixes
- **Backup Path Stability**: Improved directory creation logic during MKV remuxing/backup to prevent `PathNotFoundException` when using custom or missing backup folders.
- **Null Safety**: Resolved "Null check operator" crashes in the Service Tab during background database updates.

### Maintenance
- **Test Coverage**: Added 30 new unit tests (scan logic, database operations, video processing) bringing total to 57 passing tests.
- **Performance**: Optimized `getValuesWithCounts` query with SQL aggregate (CTE + GROUP BY) instead of loading all rows in memory. Added 6 database indexes (genres, year, saga, rating, isSeries, dateAdded). Schema version bumped to 6.
- **Code Quality**: Activated 19 additional lints in `analysis_options.yaml`. Resolved all 250 static analysis issues. Applied `dart format` and `dart fix` across 41 files.

---

### Download
- **Linux**: [myplaylist-linux-x64.tar.gz](https://github.com/losciuto/MyPlaylist/releases/download/v3.14.1/myplaylist-linux-x64.tar.gz) | [myplaylist-linux.deb](https://github.com/losciuto/MyPlaylist/releases/download/v3.14.1/myplaylist-linux.deb)
- **Windows**: [myplaylist-windows-x64.zip](https://github.com/losciuto/MyPlaylist/releases/download/v3.14.1/myplaylist-windows-x64.zip) | [myplaylist-windows-setup.exe](https://github.com/losciuto/MyPlaylist/releases/download/v3.14.1/myplaylist-windows-setup.exe)
- **Android**: [myplaylist-android.apk](https://github.com/losciuto/MyPlaylist/releases/download/v3.14.1/myplaylist-android.apk)
- **macOS**: [myplaylist-macos.zip](https://github.com/losciuto/MyPlaylist/releases/download/v3.14.1/myplaylist-macos.zip)

### Requirements
- **Linux**: Flutter SDK, libmpv-dev, mpv, ffmpeg, mkvtoolnix, gpac
- **Windows**: Flutter SDK, FFmpeg, MKVToolNix, GPAC (in PATH)
- **macOS**: Flutter SDK, ffmpeg, mkvtoolnix, gpac (via Homebrew)
- **Android**: Flutter SDK (build only)

### Full Changelog
See [CHANGELOG.md](CHANGELOG.md) for complete history.