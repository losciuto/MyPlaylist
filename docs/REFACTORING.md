# Refactoring and Architecture Document

This document describes the main technical choices and architectural improvements introduced in MyPlaylist version 2.5.0.

## 1. Performance Optimization (Bulk Operations)

One of the main issues encountered in previous versions was extreme slowness during bulk title renaming.

### Problem:
Every call to `updateVideo` via `DatabaseProvider` triggered a `notifyListeners()`, which forced the `DataTable` to reload the entire list from the database and the Flutter framework to rebuild the entire widget tree 160+ times in a few seconds.

### Solution:
We separated data update logic from UI notification logic:
- During the renaming loop, the code interacts directly with `DatabaseHelper.instance` (persistence layer).
- The UI is updated via a lightweight `ValueNotifier<Map<String, dynamic>>` that handles only the progress bar and current title display.
- A single `refreshVideos()` is called after the entire loop finishes, reducing rebuild cycles from N to 1.

## 2. Rename Robustness (Skip Logic)

To make the "Rename Titles" function usable daily without wasting time, we implemented a preventive verification system.

- **Normalization**: Titles are compared after applying `.trim()` and `.toLowerCase()`.
- **NFO Integrity**: If the NFO file doesn't contain a valid title, the file is skipped instead of attempting erroneous renames.
- **Atomicity**: FFmpeg writes new metadata to a temporary file; the original is replaced only if the operation succeeds. In case of error, the original is restored.

## 3. External Player Management (VLC)

Integration with VLC has been enhanced to provide an experience similar to a physical remote control.
- **Process Management**: Before starting a new playback, the app identifies and terminates any previously opened VLC instances to avoid audio/video overlap.
- **Remote Control**: VLC is launched with `--rc-host` parameters to allow TCP interaction (supported by future modules).

## 4. Dynamic UI/UX

- **Auto-Navigation**: Instead of requiring the user to manually select the tab, `HomeScreen` queries the database on startup and places the cursor on the most useful tab (Generate Playlist if data exists, Scan if the database is empty).
- **Operational Feedback**: Introduction of post-operation summary dialogs that clearly indicate how many files were updated, skipped, or failed.

## 5. Session-based Video Exclusion

To improve the discovery experience, we introduced `Set<int> _proposedVideoIds` in `PlaylistProvider`.
- **In-Memory Persistence**: IDs of videos added to a playlist are stored for the entire duration of the program execution.
- **SQL Injection**: `DatabaseHelper` queries (getRandom and getFiltered) now accept an `excludeIds` parameter injected as a `NOT IN (...)` clause in the SQL query, ensuring that already seen videos are not re-proposed until restart or pool exhaustion.
- **Auto-Reset**: If the number of proposed videos equals or exceeds the total number of videos in the database, the memory is cleared to allow a new full viewing cycle.
