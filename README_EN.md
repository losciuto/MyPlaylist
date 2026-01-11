# MyPlaylist

Video Playlist Creator and Local Database Manager.

## Features
*   **Folder Scanning**: Import videos with automatic metadata extraction (NFO/Filename).
*   **Database**: Full management (Search, Edit, Bulk Rename).
*   **Playlist**: Generate random, recent, or filtered playlists (inclusion/exclusion). Export .m3u.
*   **TV Series Management**: Full support for TV series folders, recursive episode metadata updates, and automatic `tvshow.nfo` generation.
*   **Advanced Filters**: Ability to include or exclude genres, years, actors and directors via tri-state selection (Include/Exclude/None).
*   **Player**: Internal player (mpv) and external player support (VLC, etc.).
*   **VLC Control**: Advanced VLC support (auto-kill previous instances, remote control launch).
*   **Persistence**: Saves the last generated playlist between sessions.
*   **Session Exclusion**: Random playlists do not repeat videos already proposed in the current session.
*   **Advanced UI**: Tooltips for long titles and real-time processing title display during renaming.

## System Requirements (Linux)
The internal player uses `media_kit` (based on mpv). To support all video codecs (e.g. H.265/HEVC), you must install system libraries:

```bash
sudo apt update
sudo apt install libmpv-dev mpv ubuntu-restricted-extras ffmpeg
```

If you experience black screens or "Codec not found" errors, run the command above.

> **IMPORTANT NOTE**: The internal player generally works well but might fail with advanced proprietary codecs (like H.265/HEVC) due to library licensing limitations, even with system codecs installed.
> **Solution**: For these specific files, please use the **External Player** option (e.g., VLC) which can be configured in the Settings.
> **VLC Features**: If using VLC, the app automatically handles checking/killing previous instances and enables remote control (port 4212) for use with external remote apps.

## Installation & Run
1.  Ensure Flutter is installed.
2.  Run `flutter pub get`
3.  Run `flutter run -d linux` (or windows) or build with `flutter build linux --release`.

## Credits
Built with Flutter.
Author: Massimo
Last Update: 11/01/2026 (v3.0.0)

## License
This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
