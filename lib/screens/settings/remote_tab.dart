import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../services/settings_service.dart';
import 'common.dart';

Widget buildRemoteTab({
  required BuildContext context,
  required TextEditingController remotePortController,
  required TextEditingController remoteSecretController,
  required TextEditingController serverInterfaceController,
  required bool obscureSecret,
  required ValueChanged<String> onRemotePortChanged,
  required ValueChanged<String> onRemoteSecretChanged,
  required ValueChanged<String> onServerInterfaceChanged,
  required VoidCallback onToggleSecretVisibility,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      buildSettingsSectionHeader(l10n.remoteTab),
      Text(
        l10n.serverStatusHeader,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 5),
      Consumer<SettingsService>(
        builder: (context, settings, child) {
          return SwitchListTile(
            title: Text(l10n.serverEnabled),
            subtitle: Text(l10n.remoteControlSubtitle),
            value: settings.remoteServerEnabled,
            onChanged: (val) => settings.setRemoteServerEnabled(val),
            activeThumbColor: const Color(0xFF4CAF50),
            contentPadding: EdgeInsets.zero,
          );
        },
      ),
      const SizedBox(height: 25),
      Text(
        l10n.networkHeader,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: serverInterfaceController,
              decoration: InputDecoration(
                labelText: l10n.listenInterface,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: fillColor,
              ),
              onChanged: onServerInterfaceChanged,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: remotePortController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.serverPort,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: fillColor,
              ),
              onChanged: onRemotePortChanged,
            ),
          ),
        ],
      ),
      const SizedBox(height: 25),
      Text(
        l10n.securityHeader,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: remoteSecretController,
        decoration: InputDecoration(
          labelText: l10n.securityKey,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: fillColor,
          suffixIcon: IconButton(
            icon: Icon(obscureSecret ? Icons.visibility : Icons.visibility_off),
            onPressed: () => onToggleSecretVisibility(),
          ),
        ),
        onChanged: onRemoteSecretChanged,
        obscureText: obscureSecret,
      ),
    ],
  );
}
