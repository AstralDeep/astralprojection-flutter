// T020 — WebSocketProvider unit tests
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astral/state/web_socket_provider.dart';

void main() {
  group('WebSocketProvider', () {
    late WebSocketProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = WebSocketProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('initial state', () {
      test('is not connected', () {
        expect(provider.connected, isFalse);
      });

      test('has empty components list', () {
        expect(provider.components, isEmpty);
      });

      test('has no session id', () {
        expect(provider.sessionId, isNull);
      });

      test('has no error', () {
        expect(provider.error, isNull);
      });

      test('has not received render', () {
        expect(provider.hasReceivedRender, isFalse);
      });

      test('has empty chat messages', () {
        expect(provider.chatMessages, isEmpty);
      });
    });

    group('sendEvent', () {
      test('does nothing when not connected', () {
        // Should not throw — just silently returns
        expect(
          () => provider.sendEvent('click', {'id': 'btn1'}),
          returnsNormally,
        );
      });
    });

    group('send', () {
      test('does nothing when not connected', () {
        expect(
          () => provider.send({'type': 'test'}),
          returnsNormally,
        );
      });
    });

    group('loadCachedTree', () {
      test('restores components from SharedPreferences', () async {
        final tree = [
          {'type': 'text', 'id': 'cached-1', 'content': 'Hello cached'},
          {'type': 'button', 'id': 'cached-2', 'label': 'Click'},
        ];

        SharedPreferences.setMockInitialValues({
          'sdui_cached_tree': jsonEncode(tree),
        });

        await provider.loadCachedTree();

        expect(provider.components, hasLength(2));
        expect(provider.components[0]['id'], 'cached-1');
        expect(provider.components[1]['id'], 'cached-2');
      });

      test('does not set hasReceivedRender for cached data', () async {
        SharedPreferences.setMockInitialValues({
          'sdui_cached_tree': jsonEncode([
            {'type': 'text', 'id': 't1'}
          ]),
        });

        await provider.loadCachedTree();

        expect(provider.hasReceivedRender, isFalse);
      });

      test('handles missing cache gracefully', () async {
        SharedPreferences.setMockInitialValues({});

        await provider.loadCachedTree();

        expect(provider.components, isEmpty);
      });

      test('handles malformed cache gracefully', () async {
        SharedPreferences.setMockInitialValues({
          'sdui_cached_tree': 'not-valid-json{{{',
        });

        // Should not throw
        await provider.loadCachedTree();
        expect(provider.components, isEmpty);
      });
    });

    group('disconnect', () {
      test('resets connected and hasReceivedRender', () {
        provider.disconnect();

        expect(provider.connected, isFalse);
        expect(provider.hasReceivedRender, isFalse);
      });
    });

    group('chatMessages', () {
      test('returns unmodifiable list', () {
        final msgs = provider.chatMessages;
        expect(msgs, isA<List<Map<String, dynamic>>>());
        expect(
          () => (msgs as List).add({'bad': true}),
          throwsUnsupportedError,
        );
      });
    });

    group('onThemeReceived', () {
      test('can set and clear theme callback', () {
        Map<String, dynamic>? received;
        provider.onThemeReceived = (config) => received = config;
        // Just verifying setter doesn't throw
        expect(received, isNull);
        provider.onThemeReceived = null;
      });
    });

    group('reRegister', () {
      test('does nothing when not connected', () {
        expect(
          () => provider.reRegister(
            token: 'tok',
            device: {'device_type': 'mobile'},
            capabilities: ['text', 'button'],
          ),
          returnsNormally,
        );
      });
    });
  });
}
