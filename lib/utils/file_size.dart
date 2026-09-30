import 'dart:io';

/// Formatta una dimensione in byte con unità leggibili.
/// Restituisce `?` se il file non esiste o non è leggibile.
String formatFileSize(int? bytes) {
  if (bytes == null || bytes < 0) return '?';
  if (bytes >= 1000000000) {
    return '${(bytes / 1000000000).toStringAsFixed(2)} GB';
  }
  if (bytes >= 1000000) {
    return '${(bytes / 1000000).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).toStringAsFixed(0)} KB';
}

/// Legge la dimensione di un file in byte, o `null` se il file non esiste
/// o non è accessibile.
Future<int?> readFileSizeBytes(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) return await file.length();
  } on Object catch (_) {
    return null;
  }
  return null;
}
