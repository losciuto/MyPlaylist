import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../services/settings_service.dart';
import '../../config/app_config.dart';
import 'common.dart';

Widget buildGeneralTab({
  required BuildContext context,
  required TextEditingController defaultSizeController,
  required bool isCheckingUpdates,
  required ValueChanged<String> onDefaultSizeChanged,
  required VoidCallback onCheckForUpdates,
}) {
  final settings = Provider.of<SettingsService>(context);
  final l10n = AppLocalizations.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildSettingsSectionHeader(l10n.generalTab),
      Text(
        l10n.appearanceHeader,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      // Language Selector
      ListTile(
        title: Text(l10n.language),
        trailing: DropdownButton<Locale>(
          value: settings.locale,
          onChanged: (Locale? newLocale) {
            if (newLocale != null) {
              settings.setLocale(newLocale);
            }
          },
          items: [
            DropdownMenuItem(value: Locale('it'), child: Text(l10n.langIt)),
            DropdownMenuItem(value: Locale('en'), child: Text(l10n.langEn)),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Consumer<SettingsService>(
        builder: (context, settings, child) {
          return DropdownButtonFormField<ThemeMode>(
            decoration: InputDecoration(
              labelText: l10n.themeMode,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: fillColor,
            ),
            initialValue: settings.themeMode,
            items: [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text(l10n.systemTheme),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text(l10n.lightTheme),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text(l10n.darkTheme),
              ),
            ],
            onChanged: (ThemeMode? newValue) {
              if (newValue != null) settings.setThemeMode(newValue);
            },
          );
        },
      ),
      const SizedBox(height: 35),
      Text(
        l10n.playlistHeader,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: defaultSizeController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.videosPerPage,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: fillColor,
          helperText: l10n.defaultPlaylistSizeHelp,
        ),
        onChanged: onDefaultSizeChanged,
      ),
      const SizedBox(height: 35),
      Text(
        l10n.updates,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      ListTile(
        title: Text(l10n.checkForUpdates),
        subtitle: Text(l10n.currentVersion(AppConfig.appVersion)),
        trailing: isCheckingUpdates
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton(
                onPressed: onCheckForUpdates,
                child: Text(l10n.checkButton),
              ),
        contentPadding: EdgeInsets.zero,
      ),
    ],
  );
}
