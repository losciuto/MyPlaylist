import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../services/settings_service.dart';
import 'common.dart';

Widget buildPlayerTab({
  required BuildContext context,
  required TextEditingController playerPathController,
  required TextEditingController vlcPortController,
  required VoidCallback onPickPlayerPath,
  required ValueChanged<String> onVlcPortChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildSettingsSectionHeader(l10n.playerTab),
      Text(
        l10n.executableHeader,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: playerPathController,
        decoration: InputDecoration(
          labelText: l10n.playerPath,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: onPickPlayerPath,
          ),
          filled: true,
          fillColor: fillColor,
        ),
        onChanged: (val) => context.read<SettingsService>().setPlayerPath(val),
      ),
      const SizedBox(height: 35),
      Text(
        l10n.vlcRemoteHeader,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: vlcPortController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.vlcPort,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: fillColor,
        ),
        onChanged: onVlcPortChanged,
      ),
    ],
  );
}
