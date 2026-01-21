import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();

  factory LoggerService() {
    return _instance;
  }

  LoggerService._internal();

  File? _logFile;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _logFile = File(p.join(appDir.path, 'myplaylist_app.log'));
      
      // Basic rotation: if file is too big (> 5MB), rename it to .old
      if (await _logFile!.exists()) {
        final length = await _logFile!.length();
        if (length > 5 * 1024 * 1024) {
           final oldFile = File('${_logFile!.path}.old');
           if (await oldFile.exists()) {
             await oldFile.delete();
           }
           await _logFile!.rename(oldFile.path);
           _logFile = File(p.join(appDir.path, 'myplaylist_app.log')); // Recreate file handle
        }
      }

      await info('LoggerService initialized. App version: 3.2.0');
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize LoggerService: $e');
    }
  }

  Future<void> _writeLine(String level, String message) async {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final line = '[$timestamp] [$level] $message\n';
    
    // Always print to console in debug mode
    if (kDebugMode) {
      debugPrint(line.trim());
    }

    if (_logFile != null) {
      try {
        await _logFile!.writeAsString(line, mode: FileMode.append);
      } catch (e) {
        debugPrint('Failed to write to log file: $e');
      }
    }
  }

  Future<void> info(String message) async {
    await _writeLine('INFO', message);
  }

  Future<void> warning(String message) async {
    await _writeLine('WARN', message);
  }

  Future<void> error(String message, [dynamic error, StackTrace? stackTrace]) async {
    var msg = message;
    if (error != null) {
      msg += ' | Error: $error';
    }
    if (stackTrace != null) {
      msg += '\nStackTrace: $stackTrace';
    }
    await _writeLine('ERROR', msg);
  }

  Future<String> getLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      return await _logFile!.readAsString();
    }
    return 'No logs found.';
  }

  Future<void> clearLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.writeAsString(''); // Clear content
      await info('Logs cleared by user.');
    }
  }
  
  Future<String?> getLogFilePath() async {
    return _logFile?.path;
  }
}
