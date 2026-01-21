import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/github_service.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(updateInfo.downloadUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDirectDownload = updateInfo.downloadUrl.toLowerCase().contains('.appimage') || 
                             updateInfo.downloadUrl.toLowerCase().contains('.deb') ||
                             updateInfo.downloadUrl.toLowerCase().contains('.tar.gz');

    return AlertDialog(
      title: Text(l10n.updateAvailableTitle(updateInfo.version)),
      content: SizedBox(
        width: 500,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.updateAvailableHeader,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(l10n.whatsNewHeader),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Text(updateInfo.body),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.ignoreButtonLabel, 
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
             _launchUrl();
             Navigator.of(context).pop();
          },
          icon: Icon(isDirectDownload ? Icons.download : Icons.open_in_new),
          label: Text(isDirectDownload ? l10n.downloadButtonLabel : l10n.openGitHubLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
