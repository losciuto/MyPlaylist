import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../services/settings_service.dart';
import 'common.dart';

Widget buildTimerTab({
  required BuildContext context,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildSettingsSectionHeader(l10n.timerTitle),
      const SizedBox(height: 10),
      Consumer<SettingsService>(
        builder: (context, settings, child) {
          return SwitchListTile(
            title: Text(l10n.timerEnabled),
            subtitle: Text(l10n.timerEnabledSubtitle),
            value: settings.vlcKillTimerEnabled,
            onChanged: (val) => settings.setVlcKillTimerEnabled(val),
            activeThumbColor: const Color(0xFF4CAF50),
            contentPadding: EdgeInsets.zero,
          );
        },
      ),
      const SizedBox(height: 25),
      Text(
        l10n.timerTime,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      Consumer<SettingsService>(
        builder: (context, settings, child) {
          return TextField(
            decoration: InputDecoration(
              labelText: l10n.timerTime,
              hintText: l10n.timerTimeHint,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: fillColor,
            ),
            controller: TextEditingController(text: settings.vlcKillTimerTime),
            onChanged: (value) {
              final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
              if (regex.hasMatch(value)) {
                settings.setVlcKillTimerTime(value);
              }
            },
            onSubmitted: (value) {
              final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
              if (regex.hasMatch(value)) {
                settings.setVlcKillTimerTime(value);
              }
            },
          );
        },
      ),
      const SizedBox(height: 35),
      Text(
        l10n.timerHelpTitle,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        l10n.timerHelpText,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 13,
        ),
      ),
    ],
  );
}