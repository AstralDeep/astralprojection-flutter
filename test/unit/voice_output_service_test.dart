// T023 — VoiceOutputService structural / API surface tests
//
// VoiceOutputService internally creates its own AudioPlayer, so we cannot
// inject a mock without modifying production code. These tests verify the
// class API surface, enum values, and basic construction.
import 'package:flutter_test/flutter_test.dart';

import 'package:astral/services/voice_output_service.dart';

void main() {
  group('VoiceOutputService (T023)', () {
    test('VoiceOutputState enum has idle, playing, and error', () {
      expect(VoiceOutputState.values, contains(VoiceOutputState.idle));
      expect(VoiceOutputState.values, contains(VoiceOutputState.playing));
      expect(VoiceOutputState.values, contains(VoiceOutputState.error));
      expect(VoiceOutputState.values, hasLength(3));
    });

    test('initial state is idle', () {
      final service = VoiceOutputService();
      expect(service.state, VoiceOutputState.idle);
      service.dispose();
    });

    test('exposes playAudio method', () {
      final service = VoiceOutputService();
      expect(service.playAudio, isA<Function>());
      service.dispose();
    });

    test('exposes stopAudio method', () {
      final service = VoiceOutputService();
      expect(service.stopAudio, isA<Function>());
      service.dispose();
    });

    test('exposes dispose method', () {
      final service = VoiceOutputService();
      expect(service.dispose, isA<Function>());
      service.dispose();
    });

    test('state getter returns VoiceOutputState', () {
      final service = VoiceOutputService();
      expect(service.state, isA<VoiceOutputState>());
      service.dispose();
    });
  });
}
