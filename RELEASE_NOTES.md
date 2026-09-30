# MyPlaylist Release Notes

## Version 3.15.0 — 2026-09-30

### New Features
- **Recent Errors panel**: errors that used to disappear into the console are now collected and shown in the app. A badge on the main bar counts them, and the panel is also available under Settings > Debug.
- **Retry on failure**: the playlist filter and manual selection dialogs show the error and a "Retry" button instead of closing silently.

### Bug Fixes
- **Duplicate sizes were wrong**: the duplicates manager formatted a 500 MB file as "500.0 GB". A single shared formatter now handles bytes, KB, MB and GB for both the duplicates manager and the compare dialog.
- **Scan messages were not translated**: scan progress and result texts were English-only. The scan state is now typed and the text is resolved with the current locale.
- **Leaks and silent failures**: listeners, controllers, subscriptions and process timers are now released on the affected screens, and the remaining silent catches were reviewed one by one (the ones left are intentional existence probes and fallbacks).

### Changes
- Metadata and update dialogs use real localized keys; 13 icon buttons gained a tooltip; 119 scattered `debugPrint` calls now go through `LoggerService`.
- The Settings screen and the video edit dialog are split into focused widgets.

### Maintenance
- Database access goes through an injected `VideoRepository` instead of the `AppDatabase` singleton.
- Backup/import, confirmation dialogs, duplicate removal and external process execution (mkvpropedit, MP4Box with timeout) are implemented once and shared.
- Tests grew from 109 to 172, and the project still passes `dart format`, `flutter analyze` and a Linux release build.

---

## Version 3.14.4 — 2026-09-29

### Bug Fixes
- **Filtered playlist SQL**: Fixed the recursive query used to load filter values. The "Playlist with filters" dialog now opens and lists genres, years, actors, directors and sagas correctly.

---

## Version 3.14.3 — 2026-09-27

### Changes
- **"Series" is now a filter of the manual selection**: the Playlist tab had a "Series Playlist" button that asked for a count and built a series playlist on its own. It is now a filter inside the "Manual Selection" dialog — All / Series only / Films only — so you see only the wanted videos and decide yourself what goes in. The tab keeps four buttons.

### Removed
- The automatic series playlist generation. Nothing else used it; the `SERIE` badge in the selection list is unchanged.

---

## Version 3.14.2 — 2026-09-27

### New Features
- **In-App Updater**: The Service tab checks GitHub for a newer release and offers to install it. On Android the APK is downloaded and its SHA-256 verified before being swapped in; everywhere else the app sends you to the release page.

### Bug Fixes
- **Launcher icons**: the app shipped the wrong icon on macOS and none at all on Linux. All platform icons are regenerated from a real RGBA PNG, the Linux build now installs a desktop entry and a full hicolor icon set, and the `.deb` no longer installs a 1024x1024 file into a 128x128 slot.
- **Linux window icon**: the icon is now set reliably, and a missing asset no longer fails silently.

### Maintenance
- Dropped the unused `web/` target, which could not be built and broke the icon generator.

---

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
- **Linux**: [myplaylist-linux-x64.tar.gz](https://github.com/losciuto/MyPlaylist/releases/download/v3.14.4/myplaylist-linux-x64.tar.gz) | [myplaylist-linux.deb](https://github.com/losciuto/MyPlaylist/releases/download/v3.14.4/myplaylist-linux.deb)
- **Windows**: [myplaylist-windows-x64.zip](https://github.com/losciuto/MyPlaylist/releases/download/v3.14.4/myplaylist-windows-x64.zip) | [myplaylist-windows-setup.exe](https://github.com/losciuto/MyPlaylist/releases/download/v3.14.4/myplaylist-windows-setup.exe)
- **Android**: [myplaylist-android.apk](https://github.com/losciuto/MyPlaylist/releases/download/v3.14.4/myplaylist-android.apk)
- **macOS**: [myplaylist-macos.zip](https://github.com/losciuto/MyPlaylist/releases/download/v3.14.4/myplaylist-macos.zip)

### Requirements
- **Linux**: Flutter SDK, libmpv-dev, mpv, ffmpeg, mkvtoolnix, gpac
- **Windows**: Flutter SDK, FFmpeg, MKVToolNix, GPAC (in PATH)
- **macOS**: Flutter SDK, ffmpeg, mkvtoolnix, gpac (via Homebrew)
- **Android**: Flutter SDK (build only)

### Full Changelog
See [CHANGELOG.md](CHANGELOG.md) for complete history.