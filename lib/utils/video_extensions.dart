class VideoExtensions {
  /// Defines all video extensions supported by the application.
  /// Keep them all lowercase and starting with a dot.
  static const List<String> supported = [
    // Standard MP4
    '.mp4', '.m4v', '.m4a', // media_kit supports audio too if needed, but keeping primarily video
    // Matroska
    '.mkv', '.webm',
    // AVI
    '.avi',
    // QuickTime
    '.mov', '.qt',
    // Windows Media
    '.wmv', '.asf',
    // Flash Video
    '.flv', '.f4v',
    // MPEG
    '.mpg', '.mpeg', '.m2v', '.mpg2', '.mp2',
    // Transport Streams
    '.ts', '.mts', '.m2ts',
    // DVD/VCD
    '.vob', '.ifo',
    // Ogg
    '.ogv', '.ogg',
    // RealMedia
    '.rm', '.rmvb',
    // Other Formats
    '.amv', '.divx', '.3gp', '.3g2', '.mxf', '.yuv',
    // Streaming/Playlist formats (supported by media_kit)
    '.m3u', '.m3u8'
  ];
}
