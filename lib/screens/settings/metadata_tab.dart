import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import '../../services/settings_service.dart';
import 'common.dart';

Widget buildMetadataTab({
  required BuildContext context,
  required TextEditingController tmdbApiKeyController,
  required TextEditingController fanartApiKeyController,
  required TextEditingController videoBackupPathController,
  required VoidCallback onPickVideoBackupPath,
  required VoidCallback onStartBulkMetadataSync,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildSettingsSectionHeader(l10n.metadataTab),
      Text(
        l10n.tmdbHeader,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: tmdbApiKeyController,
        decoration: InputDecoration(
          labelText: l10n.tmdbApiKey,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: fillColor,
          helperText: l10n.tmdbApiKeyHint,
        ),
        onChanged: (val) => context.read<SettingsService>().setTmdbApiKey(val),
      ),
      const SizedBox(height: 15),
      TextField(
        controller: fanartApiKeyController,
        decoration: InputDecoration(
          labelText: l10n.fanartApiKey,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: fillColor,
          helperText: l10n.fanartApiKeyHint,
        ),
        onChanged: (val) =>
            context.read<SettingsService>().setFanartApiKey(val),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blueAccent),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                l10n.tmdbInfo,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 35),

      // Auto-Sync Section
      Text(
        l10n.settingsAutoSync,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      Consumer<SettingsService>(
        builder: (context, settings, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: Text(l10n.settingsAutoSync),
                subtitle: Text(l10n.settingsAutoSyncSubtitle),
                value: settings.autoSyncEnabled,
                onChanged: (val) => settings.setAutoSyncEnabled(val),
                activeThumbColor: const Color(0xFF4CAF50),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: Text(l10n.settingsAutoSyncNfo),
                subtitle: Text(l10n.settingsAutoSyncNfoSubtitle),
                value: settings.autoSyncNfoOnEdit,
                onChanged: (val) => settings.setAutoSyncNfoOnEdit(val),
                activeThumbColor: const Color(0xFF4CAF50),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: Text(l10n.settingsFastMetadataEngine),
                subtitle: Text(l10n.settingsFastMetadataEngineSubtitle),
                value: settings.fastMetadataEngineEnabled,
                onChanged: (val) => settings.setFastMetadataEngineEnabled(val),
                activeThumbColor: const Color(0xFF4CAF50),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: Text(l10n.settingsAutoConvertAvi),
                subtitle: Text(l10n.settingsAutoConvertAviSubtitle),
                value: settings.autoConvertToMkv,
                onChanged: (val) => settings.setAutoConvertToMkv(val),
                activeThumbColor: const Color(0xFF4CAF50),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: videoBackupPathController,
                decoration: InputDecoration(
                  labelText: l10n.settingsAviBackupPath,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: onPickVideoBackupPath,
                  ),
                  filled: true,
                  fillColor: fillColor,
                  helperText: l10n.settingsAviBackupPathSubtitle,
                ),
                onChanged: (val) =>
                    context.read<SettingsService>().setVideoBackupPath(val),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: Text(l10n.settingsExcludeConvertedBackup),
                subtitle: Text(l10n.settingsExcludeConvertedBackupSubtitle),
                value: settings.excludeConvertedBackupFromScan,
                onChanged: (val) =>
                    settings.setExcludeConvertedBackupFromScan(val),
                activeThumbColor: const Color(0xFF4CAF50),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.settingsWatchedFolders,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white10),
                ),
                child: settings.watchedDirectories.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            l10n.settingsNoWatchedFolders,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: settings.watchedDirectories.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final dir = settings.watchedDirectories[i];
                          return ListTile(
                            title: Text(
                              p.basename(dir),
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              dir,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () =>
                                  settings.removeWatchedDirectory(dir),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 35),
              Text(
                l10n.manualDbSyncHeader,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                        const Icon(Icons.sync_alt, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 10),
                        Text(
                          l10n.syncMissingTagsLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.syncMissingTagsDesc,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: onStartBulkMetadataSync,
                      icon: const Icon(Icons.batch_prediction),
                      label: Text(l10n.startSyncButton),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
}
