# MyPlaylist

Video Playlist Creator and Local Database Manager built with Flutter.

## Overview
MyPlaylist is a desktop application designed to manage your local video collection, extract metadata from NFO files, and generate playlists (Random, Recent, or Filtered) for your favorite media player.

## Documentation
- [English (CHANGELOG.md)](CHANGELOG.md) | [Italiano (CHANGELOG_IT.md)](CHANGELOG_IT.md)
- [English (REFACTORING.md)](REFACTORING.md) | [Italiano (REFACTORING_IT.md)](REFACTORING_IT.md)
- [English (README_EN.md)](README_EN.md) | [Italiano (README_IT.md)](README_IT.md)

## Key Features
- **Modern UI**: Tooltips, real-time progress, and a clean interface.

> [!WARNING]
> **Automatic MKV Conversion**: When "Convert video to MKV" is enabled, any **Rename** or **Metadata Sync** on non-MKV files will trigger an automatic remuxing to MKV. Original files will be backed up to the configured folder.

## Quick Start
1.  Ensure [Flutter](https://flutter.dev/get-started/) is installed.
2.  Run `flutter pub get`.
3.  Run `flutter run -d linux` (or windows).

> [!IMPORTANT]
> On **Windows** and **macOS**, you must manually install **FFmpeg**, **MKVToolNix**, and **GPAC** (MP4Box) for metadata and conversion features. See [README_EN.md](README_EN.md) or [README_IT.md](README_IT.md) for details.

---
**Version**: 3.12.3  
**Last Update**: 31/03/2026

## License
This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
