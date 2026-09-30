import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

import 'common.dart';
import '../../widgets/recent_errors_screen.dart';
import '../../services/logger_service.dart';

Widget buildDebugTab({
  required BuildContext context,
  required VoidCallback onRefresh,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fillColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildSettingsSectionHeader(l10n.debugTab),
      const RecentErrorsPanel(),
      const SizedBox(height: 20),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.eventLog,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
                tooltip: l10n.refreshLog,
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  final logs = await LoggerService().getLogs();
                  await Clipboard.setData(ClipboardData(text: logs));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.logCopied)));
                },
                tooltip: l10n.copyLog,
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                onPressed: () async {
                  await LoggerService().clearLogs();
                  onRefresh();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.logCleared)));
                },
                tooltip: l10n.clearLog,
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 10),

      Container(
        height: 400,
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white10),
        ),
        child: FutureBuilder<String>(
          future: LoggerService().getLogs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text(
                l10n.logError(snapshot.error.toString()),
                style: const TextStyle(color: Colors.red),
              );
            }

            return SingleChildScrollView(
              child: SelectableText(
                snapshot.data ?? l10n.noLogs,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      FutureBuilder<String?>(
        future: LoggerService().getLogFilePath(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(
              l10n.logFile(snapshot.data!),
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ],
  );
}
