import 'package:flutter/material.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

enum ConfirmStyle { elevated, filled, text }

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel,
    this.style = ConfirmStyle.elevated,
    this.destructive = false,
    this.confirmColor,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final ConfirmStyle style;
  final bool destructive;
  final Color? confirmColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = confirmColor ?? (destructive ? Colors.red : null);

    final confirmButton = switch (style) {
      ConfirmStyle.elevated => ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: color == null
            ? null
            : ElevatedButton.styleFrom(backgroundColor: color),
        child: Text(confirmLabel),
      ),
      ConfirmStyle.filled => FilledButton(
        onPressed: () => Navigator.pop(context, true),
        style: color == null
            ? null
            : FilledButton.styleFrom(backgroundColor: color),
        child: Text(confirmLabel),
      ),
      ConfirmStyle.text => TextButton(
        onPressed: () => Navigator.pop(context, true),
        style: color == null
            ? null
            : TextButton.styleFrom(foregroundColor: color),
        child: Text(confirmLabel),
      ),
    };

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel ?? l10n.cancel),
        ),
        confirmButton,
      ],
    );
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  ConfirmStyle style = ConfirmStyle.elevated,
  bool destructive = false,
  Color? confirmColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      style: style,
      destructive: destructive,
      confirmColor: confirmColor,
    ),
  );
  return result == true;
}
