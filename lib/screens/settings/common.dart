import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

/// Intestazione di sezione delle impostazioni.
Widget buildSettingsSectionHeader(String title) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4CAF50),
        ),
      ),
      const SizedBox(height: 5),
      const Divider(color: Color(0xFF4CAF50)),
      const SizedBox(height: 25),
    ],
  );
}

/// Voce della barra laterale delle impostazioni.
Widget buildSettingsSidebarItem({
  required BuildContext context,
  required int index,
  required int currentTab,
  required String fallbackLabel,
  required IconData icon,
  required VoidCallback onTap,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isSelected = currentTab == index;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final localizedLabel = switch (index) {
    0 => l10n.generalTab,
    1 => l10n.metadataTab,
    2 => l10n.playerTab,
    3 => l10n.remoteTab,
    4 => l10n.maintenanceTab,
    5 => l10n.debugTab,
    _ => fallbackLabel,
  };

  final foreground = isSelected
      ? const Color(0xFF4CAF50)
      : (isDark ? Colors.white70 : Colors.black87);

  return ListTile(
    selected: isSelected,
    leading: Icon(icon, color: foreground, size: 22),
    title: Text(
      localizedLabel,
      style: TextStyle(
        color: foreground,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 15,
      ),
    ),
    onTap: onTap,
    tileColor: isSelected
        ? (isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05))
        : null,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
  );
}
