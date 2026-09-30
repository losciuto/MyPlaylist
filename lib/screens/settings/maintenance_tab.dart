import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

import 'common.dart';

Widget buildMaintenanceTab({
  required BuildContext context,
  required VoidCallback onExportDatabase,
  required VoidCallback onImportDatabase,
  required VoidCallback onResetPriorityList,
  required VoidCallback onStartBulkMetadataSync,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildSettingsSectionHeader(l10n.maintenanceTab),
      Text(
        l10n.backupRestoreHeader,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),

      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.save_alt, color: Color(0xFF4CAF50)),
                const SizedBox(width: 10),
                Text(
                  l10n.backupDatabase,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.backupDescription,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: onExportDatabase,
              icon: const Icon(Icons.download),
              label: Text(l10n.exportButton),
            ),
          ],
        ),
      ),

      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restore, color: Colors.orangeAccent),
                const SizedBox(width: 10),
                Text(
                  l10n.restoreDatabase,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.restoreDescription,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: onImportDatabase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
              ),
              icon: const Icon(Icons.upload),
              label: Text(l10n.importButton),
            ),
          ],
        ),
      ),

      const SizedBox(height: 30),

      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_toggle_off, color: Colors.blueAccent),
                const SizedBox(width: 10),
                Text(
                  l10n.resetPriorityList,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.resetPriorityDescription,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: onResetPriorityList,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent[700],
              ),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.resetPriorityList),
            ),
          ],
        ),
      ),
    ],
  );
}
