import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

/// Campo di testo usato in tutto il dialog di modifica.
Widget editVideoTextField(
  BuildContext context,
  TextEditingController controller,
  String label, [
  bool required = false,
  int maxLines = 1,
  String? tooltip,
]) {
  return TextFormField(
    controller: controller,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white),
    validator: required
        ? (val) => val == null || val.isEmpty
              ? AppLocalizations.of(context)!.requiredField
              : null
        : null,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF4CAF50)),
      ),
      filled: true,
      fillColor: const Color(0xFF3C3C3C),
      suffixIcon: tooltip != null
          ? Tooltip(
              message: tooltip,
              child: const Icon(
                Icons.info_outline,
                color: Colors.blueAccent,
                size: 18,
              ),
            )
          : null,
    ),
  );
}
