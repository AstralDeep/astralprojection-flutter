// T062 — WebSocket auto-reconnect with exponential backoff unit tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astral/state/web_socket_provider.dart';

void main() {
  group('WebSocket Reconnect (T062)', () {
    late WebSocketProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = WebSocketProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('reconnectDelay', () {
      test('attempt 0 gives 1 second delay', () {
        provider.reconnectAttemptForTest = 0;
        expect(provider.reconnectDelay(), const Duration(seconds: 1));
      });

      test('attempt 1 gives 2 second delay', () {
        provider.reconnectAttemptForTest = 1;
        expect(provider.reconnectDelay(), const Duration(seconds: 2));
      });

      test('attempt 2 gives 4 second delay', () {
        provider.reconnectAttemptForTest = 2;
        expect(provider.reconnectDelay(), const Duration(seconds: 4));
      });

      test('attempt 3 gives 8 second delay', () {
        provider.reconnectAttemptForTest = 3;
        expect(provider.reconnectDelay(), const Duration(seconds: 8));
      });

      test('attempt 4 gives 16 second delay', () {
        provider.reconnectAttemptForTest = 4;
        expect(provider.reconnectDelay(), const Duration(seconds: 16));
      });

      test('attempt 5 is capped at 30 seconds (2^5=32 > 30)', () {
        provider.reconnectAttemptForTest = 5;
        expect(provider.reconnectDelay(), const Duration(seconds: 30));
      });

      test('attempt 10 is still capped at 30 seconds', () {
        provider.reconnectAttemptForTest = 10;
        expect(provider.reconnectDelay(), const Duration(seconds: 30));
      });
    });

    group('exponential backoff sequence', () {
      test('produces 1, 2, 4, 8, 16, 30, 30 for attempts 0-6', () {
        final expected = [1, 2, 4, 8, 16, 30, 30];
        for (var i = 0; i < expected.length; i++) {
          provider.reconnectAttemptForTest = i;
          expect(
            provider.reconnectDelay(),
            Duration(seconds: expected[i]),
            reason: 'attempt $i should delay ${expected[i]}s',
          );
        }
      });
    });

    group('reconnect state', () {
      test('reconnectAttempt starts at 0', () {
        expect(provider.reconnectAttempt, 0);
      });

      test('reconnectEnabled defaults to true', () {
        expect(provider.reconnectEnabled, isTrue);
      });

      test('reconnectEnabled can be toggled', () {
        provider.reconnectEnabled = false;
        expect(provider.reconnectEnabled, isFalse);
        provider.reconnectEnabled = true;
        expect(provider.reconnectEnabled, isTrue);
      });

      test('disconnect with triggeredByUser resets reconnect attempt', () {
        provider.reconnectAttemptForTest = 5;
        provider.disconnect(triggeredByUser: true);
        expect(provider.reconnectAttempt, 0);
      });

      test('disconnect without triggeredByUser preserves reconnect attempt',
          () {
        provider.reconnectAttemptForTest = 3;
        provider.disconnect();
        expect(provider.reconnectAttempt, 3);
      });
    });

    group('maxReconnectDelaySec', () {
      test('is 30', () {
        expect(WebSocketProvider.maxReconnectDelaySec, 30);
      });
    });
  });
}
