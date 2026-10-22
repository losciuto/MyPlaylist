import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../services/voice/voice_command.dart';
import '../services/voice/voice_command_service.dart';
import '../services/voice/voice_language.dart';

/// Scheda dedicata ai comandi vocali.
///
/// L'ascolto si attiva solo da qui: non esiste un push-to-talk globale ne'
/// una parola di attivazione.
class VoiceTab extends StatefulWidget {
  const VoiceTab({super.key});

  @override
  State<VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<VoiceTab> {
  @override
  void initState() {
    super.initState();
    // L'elenco dei microfoni si carica all'apertura della scheda.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final voice = context.read<VoiceCommandService>();
      voice.loadInputDevices();
      // Se il modello e' gia' in locale il motore parte subito: cosi' il
      // microfono non resta disattivato anche se il modello non e' stato
      // avviato in questa sessione.
      voice.prepareIfModelPresent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final voice = context.watch<VoiceCommandService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF3C3C3C) : Colors.grey[200]!;

    if (!voice.isPlatformSupported) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                l10n.voiceErrorUnsupportedPlatform,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Con poco spazio i pannelli passano sotto uno all'altro e la
        // scheda diventa scorrevole: evita che i pannelli si comprimano
        // troppo e che il testo venga tagliato.
        final bool compact = constraints.maxHeight < 620;

        final Widget header = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.voiceTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConfig.seedColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.voiceSubtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        );

        final Widget language = _LanguageAndModel(
          voice: voice,
          fillColor: fillColor,
        );
        final Widget listen = _ListenPanel(voice: voice, fillColor: fillColor);
        final Widget history = _HistoryPanel(
          voice: voice,
          fillColor: fillColor,
        );
        final Widget help = _HelpPanel(fillColor: fillColor);

        if (compact) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 16),
                  language,
                  const SizedBox(height: 16),
                  listen,
                  const SizedBox(height: 16),
                  SizedBox(height: 240, child: history),
                  const SizedBox(height: 16),
                  SizedBox(height: 280, child: help),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          language,
                          const SizedBox(height: 16),
                          listen,
                          const SizedBox(height: 16),
                          Expanded(child: history),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: help),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageAndModel extends StatelessWidget {
  const _LanguageAndModel({required this.voice, required this.fillColor});

  final VoiceCommandService voice;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.voiceLanguage,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButton<VoiceLanguage>(
                  value: voice.language,
                  underline: const SizedBox.shrink(),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: VoiceLanguage.italian,
                      child: Text(l10n.voiceLanguageIt),
                    ),
                    DropdownMenuItem(
                      value: VoiceLanguage.english,
                      child: Text(l10n.voiceLanguageEn),
                    ),
                  ],
                  onChanged: voice.isPreparing
                      ? null
                      : (language) {
                          if (language != null) voice.setLanguage(language);
                        },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.voiceModelTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 6),
                _ModelStatus(voice: voice, fillColor: fillColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelStatus extends StatelessWidget {
  const _ModelStatus({required this.voice, required this.fillColor});

  final VoiceCommandService voice;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (voice.isPreparing) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              l10n.voiceModelDownloading,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      );
    }

    final bool ready =
        voice.status == VoiceStatus.ready ||
        voice.status == VoiceStatus.listening;

    if (ready) {
      return Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: AppConfig.seedColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n.voiceModelReady,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.voiceModelMissing,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.voiceModelMissingHint(voice.language.modelSizeText),
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: voice.isPreparing ? null : voice.prepare,
          icon: const Icon(Icons.download, size: 18),
          label: Text(l10n.voiceModelDownload),
        ),
      ],
    );
  }
}

class _ListenPanel extends StatelessWidget {
  const _ListenPanel({required this.voice, required this.fillColor});

  final VoiceCommandService voice;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isListening = voice.isListening;
    final isPreparing = voice.isPreparing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          IconButton(
            // Il pulsante resta attivo anche senza modello pronto: la
            // preparazione parte automaticamente al primo ascolto.
            onPressed: () =>
                isListening ? voice.stopListening() : voice.startListening(),
            iconSize: 44,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: isPreparing
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Icon(
                    isListening ? Icons.stop_circle : Icons.mic,
                    color: isListening ? Colors.redAccent : AppConfig.seedColor,
                  ),
            tooltip: isListening ? l10n.voiceStopListening : l10n.voiceListen,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isListening
                      ? l10n.voiceListening
                      : (isPreparing
                            ? l10n.voiceModelDownloading
                            : l10n.voiceWaiting),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isListening ? Colors.redAccent : Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  voice.partialTranscript.isEmpty
                      ? l10n.voicePartialTranscript('')
                      : l10n.voicePartialTranscript(voice.partialTranscript),
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                if (voice.error != VoiceError.none) ...[
                  const SizedBox(height: 6),
                  Text(
                    _errorText(l10n, voice),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _MicrophoneSelector(voice: voice),
                const SizedBox(height: 10),
                _InputLevelMeter(voice: voice),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _errorText(AppLocalizations l10n, VoiceCommandService voice) {
    switch (voice.error) {
      case VoiceError.none:
        return '';
      case VoiceError.unsupportedPlatform:
        return l10n.voiceErrorUnsupportedPlatform;
      case VoiceError.nativeLibraryMissing:
        return l10n.voiceErrorNativeLibrary;
      case VoiceError.modelDownloadFailed:
      case VoiceError.modelLoadFailed:
        return l10n.voiceErrorModelLoad(voice.errorDetails ?? '');
      case VoiceError.microphoneDenied:
        return l10n.voiceErrorMicDenied;
      case VoiceError.recorderUnavailable:
        return l10n.voiceErrorRecorder(voice.errorDetails ?? '');
    }
  }
}

class _MicrophoneSelector extends StatelessWidget {
  const _MicrophoneSelector({required this.voice});

  final VoiceCommandService voice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Text(
          l10n.voiceMicrophone,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButton<String?>(
            value: voice.selectedDeviceId,
            isExpanded: true,
            isDense: true,
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem<String?>(
                child: Text(
                  l10n.voiceMicrophoneDefault,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (final device in voice.inputDevices)
                DropdownMenuItem<String?>(
                  value: device.id,
                  child: Text(device.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: voice.loadingDevices ? null : voice.setInputDevice,
          ),
        ),
        IconButton(
          onPressed: voice.loadingDevices ? null : voice.loadInputDevices,
          icon: const Icon(Icons.refresh, size: 18),
          tooltip: l10n.voiceMicrophoneRefresh,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _InputLevelMeter extends StatelessWidget {
  const _InputLevelMeter({required this.voice});

  final VoiceCommandService voice;

  /// Soglia in dBFS sotto la quale il segnale e' considerato silenzio.
  static const double minLevelDb = -60;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<double>(
      valueListenable: voice.inputLevel,
      builder: (BuildContext context, double level, Widget? child) {
        final double fraction = _fraction(level);
        final bool hasSignal = level > minLevelDb;
        return Row(
          children: [
            Text(
              l10n.voiceInputLevel,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      Container(color: Colors.white12),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(color: _color(fraction)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 56,
              child: Text(
                hasSignal ? '${level.round()} dB' : '--',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: hasSignal ? Colors.white70 : Colors.white38,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Converte il livello in dBFS nella frazione riempita della barra.
  static double _fraction(double level) {
    if (level <= minLevelDb) return 0;
    return ((level - minLevelDb) / -minLevelDb).clamp(0.0, 1.0);
  }

  static Color _color(double fraction) {
    if (fraction < 0.6) return Colors.greenAccent;
    if (fraction < 0.85) return Colors.amberAccent;
    return Colors.redAccent;
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.voice, required this.fillColor});

  final VoiceCommandService voice;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Text(
                  l10n.voiceHistoryTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (voice.history.isNotEmpty)
                TextButton.icon(
                  onPressed: voice.clearHistory,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(
                    l10n.voiceClearHistory,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Flexible(
            child: voice.history.isEmpty
                ? Center(
                    child: Text(
                      l10n.voiceHistoryEmpty,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: voice.history.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: Colors.white10, height: 12),
                    itemBuilder: (context, index) {
                      final entry = voice.history[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            entry.succeeded
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            size: 16,
                            color: entry.succeeded
                                ? AppConfig.seedColor
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '"${entry.transcript}"',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                Text(
                                  _feedbackText(l10n, entry),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HelpPanel extends StatelessWidget {
  const _HelpPanel({required this.fillColor});

  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final entries = <String>[
      l10n.voiceHelpPlaylist,
      l10n.voiceHelpPause,
      l10n.voiceHelpNext,
      l10n.voiceHelpVolume,
      l10n.voiceHelpSeek,
      l10n.voiceHelpStop,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.voiceHelpTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.mic_none,
                          size: 14,
                          color: AppConfig.seedColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _feedbackText(AppLocalizations l10n, VoiceLogEntry entry) {
  switch (entry.feedback) {
    case VoiceFeedback.playlistRandom:
      return l10n.voiceFeedbackPlaylistRandom(entry.number ?? 0);
    case VoiceFeedback.playlistRecent:
      return l10n.voiceFeedbackPlaylistRecent(entry.number ?? 0);
    case VoiceFeedback.playlistPlay:
      return l10n.voiceFeedbackPlaylistPlay;
    case VoiceFeedback.stopped:
      return l10n.voiceFeedbackStopped;
    case VoiceFeedback.paused:
      return l10n.voiceFeedbackPaused;
    case VoiceFeedback.resumed:
      return l10n.voiceFeedbackResumed;
    case VoiceFeedback.next:
      return l10n.voiceFeedbackNext;
    case VoiceFeedback.previous:
      return l10n.voiceFeedbackPrevious;
    case VoiceFeedback.volumeUp:
      return l10n.voiceFeedbackVolumeUp;
    case VoiceFeedback.volumeDown:
      return l10n.voiceFeedbackVolumeDown;
    case VoiceFeedback.volumeSet:
      return l10n.voiceFeedbackVolumeSet(entry.number ?? 0);
    case VoiceFeedback.seekForward:
      return l10n.voiceFeedbackSeekForward(entry.number ?? 0);
    case VoiceFeedback.seekBackward:
      return l10n.voiceFeedbackSeekBackward(entry.number ?? 0);
    case VoiceFeedback.notRecognized:
      return l10n.voiceFeedbackNotRecognized;
    case VoiceFeedback.vlcUnreachable:
      return l10n.voiceFeedbackVlcError;
  }
}
