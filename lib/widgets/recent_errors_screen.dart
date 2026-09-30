import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

import '../services/error_reporter_service.dart';

/// Pannello degli errori recenti, riusato nella tab Debug delle impostazioni.
class RecentErrorsPanel extends StatelessWidget {
  const RecentErrorsPanel({super.key, this.maxHeight = 220});

  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: errorReporter,
      builder: (context, _) {
        final errors = errorReporter.errors;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.recentErrors,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (errors.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_sweep,
                      color: Colors.redAccent,
                    ),
                    onPressed: errorReporter.clear,
                    tooltip: l10n.clearErrors,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.white10),
              ),
              child: errors.isNotEmpty
                  ? ListView.separated(
                      shrinkWrap: true,
                      itemCount: errors.length,
                      separatorBuilder: (_, _) => const Divider(height: 12),
                      itemBuilder: (context, index) =>
                          RecentErrorsTile(error: errors[index]),
                    )
                  : Text(
                      l10n.noRecentErrors,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class RecentErrorsTile extends StatelessWidget {
  const RecentErrorsTile({super.key, required this.error});

  final AppError error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          error.title,
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(error.message, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          DateFormat('dd/MM/yyyy HH:mm:ss').format(error.timestamp),
          style: const TextStyle(color: Colors.white24, fontSize: 10),
        ),
      ],
    );
  }
}

/// Elenco degli errori segnalati durante la sessione corrente.
class RecentErrorsScreen extends StatelessWidget {
  const RecentErrorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recentErrors),
        actions: [
          AnimatedBuilder(
            animation: errorReporter,
            builder: (context, _) => errorReporter.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    tooltip: l10n.clearErrors,
                    onPressed: errorReporter.clear,
                  ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: errorReporter,
        builder: (context, _) {
          final errors = errorReporter.errors;
          if (errors.isEmpty) {
            return Center(
              child: Text(
                l10n.noRecentErrors,
                style: const TextStyle(color: Colors.white38),
              ),
            );
          }

          return ListView.separated(
            itemCount: errors.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final error = errors[index];
              return ListTile(
                leading: const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                ),
                title: Text(
                  error.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    SelectableText(error.message),
                    const SizedBox(height: 4),
                    Text(
                      [
                        DateFormat(
                          'dd/MM/yyyy HH:mm:ss',
                        ).format(error.timestamp),
                        if (error.source != null) error.source!,
                      ].join(' - '),
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
