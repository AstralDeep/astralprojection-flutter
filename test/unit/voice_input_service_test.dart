// T022 — VoiceInputService structural / API surface tests
//
// VoiceInputService depends on the record package AudioRecorder and a live
// WebSocket, which cannot be easily mocked in unit tests without build_runner.
// These tests verify the class API surface and basic construction.
import 'package:flutter_test/flutter_test.dart';

import 'package:astral/services/voice_input_service.dart';

void main() {
  group('VoiceInputService (T022)', () {
    late VoiceInputService service;

    setUp(() {
      service = VoiceInputService();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('has a transcripts stream getter', () {
      expect(service.transcripts, isA<Stream<String>>());
    });

    test('isStreaming is initially false', () {
      expect(service.isStreaming, isFalse);
    });

    test('transcripts stream is a broadcast stream', () {
      // Should be able to listen multiple times without error
      final sub1 = service.transcripts.listen((_) {});
      final sub2 = service.transcripts.listen((_) {});
      // Clean up
      sub1.cancel();
      sub2.cancel();
    });

    test('dispose does not throw when called without starting', () async {
      // dispose on a fresh service should not throw
      await service.dispose();
    });

    test('stopStreaming does not throw when not streaming', () async {
      // Should be a no-op
      await service.stopStreaming();
      expect(service.isStreaming, isFalse);
    });

    test('service exposes startStreaming method', () {
      // Verify the method exists (we cannot call it without a real mic)
      expect(service.startStreaming, isA<Function>());
    });

    test('service exposes stopStreaming method', () {
      expect(service.stopStreaming, isA<Function>());
    });
  });
}
