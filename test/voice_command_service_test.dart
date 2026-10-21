import 'package:flutter_test/flutter_test.dart';
import 'package:my_playlist/services/voice/voice_command_service.dart';

void main() {
  group('Normalizzazione degli id dei microfoni', () {
    test('Toglie le virgolette restituite da PulseAudio', () {
      expect(
        VoiceCommandService.normalizeDeviceId(
          '"alsa_input.usb-Microsoft_Microsoft___LifeCam_HD-3000-02.mono-fallback"',
        ),
        'alsa_input.usb-Microsoft_Microsoft___LifeCam_HD-3000-02.mono-fallback',
      );
    });

    test('Lascia invariati gli id gia\' puliti', () {
      expect(
        VoiceCommandService.normalizeDeviceId(
          'alsa_input.pci-0000_00_1b.0.analog-stereo',
        ),
        'alsa_input.pci-0000_00_1b.0.analog-stereo',
      );
    });

    test('Rimuove anche gli spazi attorno', () {
      expect(
        VoiceCommandService.normalizeDeviceId('  "pulse_input.mic"  '),
        'pulse_input.mic',
      );
    });

    test('Non mutila una stringa con una sola virgoletta', () {
      expect(VoiceCommandService.normalizeDeviceId('"'), '"');
    });
  });
}
