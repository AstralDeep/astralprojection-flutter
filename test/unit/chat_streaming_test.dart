// T061 — Chat streaming unit tests: ui_append handling and chatMessages
// accumulation in WebSocketProvider.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astral/state/web_socket_provider.dart';

void main() {
  group('ChatStreaming (T061)', () {
    late WebSocketProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = WebSocketProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('chatMessages starts empty', () {
      expect(provider.chatMessages, isEmpty);
    });

    test('chatMessages list is unmodifiable', () {
      expect(
        () => (provider.chatMessages as List).add({'bad': true}),
        throwsUnsupportedError,
      );
    });

    test('ui_append adds data map to chatMessages', () {
      provider.simulateMessage(jsonEncode({
        'type': 'ui_append',
        'target_id': 'chat-1',
        'data': {'role': 'assistant', 'text': 'Hello!'},
      }));

      expect(provider.chatMessages, hasLength(1));
      expect(provider.chatMessages[0]['role'], 'assistant');
      expect(provider.chatMessages[0]['text'], 'Hello!');
    });

    test('multiple ui_append messages accumulate in order', () {
      provider.simulateMessage(jsonEncode({
        'type': 'ui_append',
        'target_id': 'chat-1',
        'data': {'role': 'user', 'text': 'Hi'},
      }));
      provider.simulateMessage(jsonEncode({
        'type': 'ui_append',
        'target_id': 'chat-1',
        'data': {'role': 'assistant', 'text': 'Hello!'},
      }));
      provider.simulateMessage(jsonEncode({
        'type': 'ui_append',
        'target_id': 'chat-1',
        'data': {'role': 'user', 'text': 'How are you?'},
      }));

      expect(provider.chatMessages, hasLength(3));
      expect(provider.chatMessages[0]['text'], 'Hi');
      expect(provider.chatMessages[1]['text'], 'Hello!');
      expect(provider.chatMessages[2]['text'], 'How are you?');
    });

    test('ui_append without data map does not add to chatMessages', () {
      provider.simulateMessage(jsonEncode({
        'type': 'ui_append',
        'target_id': 'chat-1',
        'data': 'plain string, not a map',
      }));

      expect(provider.chatMessages, isEmpty);
    });

    test('ui_append appends to component tree children', () {
      // Render a component tree with a chat container.
      provider.simulateMessage(jsonEncode({
        'type': 'ui_render',
        'components': [
          {
            'type': 'container',
            'id': 'chat-container',
            'children': [],
          },
        ],
      }));

      expect(provider.components, hasLength(1));
      expect(provider.components[0]['children'], isEmpty);

      // Append a message to the chat container.
      provider.simulateMessage(jsonEncode({
        'type': 'ui_append',
        'target_id': 'chat-container',
        'data': {'type': 'text', 'id': 'msg-1', 'content': 'Hello'},
      }));

      final children = provider.components[0]['children'] as List;
      expect(children, hasLength(1));
      expect((children[0] as Map)['content'], 'Hello');

      // Also added to chatMessages.
      expect(provider.chatMessages, hasLength(1));
    });

    test('ui_append notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.simulateMessage(jsonEncode({
        'type': 'ui_append',
        'target_id': 'chat-1',
        'data': {'role': 'assistant', 'text': 'Test'},
      }));

      expect(notifyCount, greaterThan(0));
    });

    test('ui_render replaces component tree and sets hasReceivedRender', () {
      provider.simulateMessage(jsonEncode({
        'type': 'ui_render',
        'components': [
          {'type': 'text', 'id': 't1', 'content': 'Hello'},
        ],
      }));

      expect(provider.components, hasLength(1));
      expect(provider.hasReceivedRender, isTrue);
    });

    test('session_id message stores the session id', () {
      provider.simulateMessage(jsonEncode({
        'type': 'session_id',
        'session_id': 'abc-123',
      }));

      expect(provider.sessionId, 'abc-123');
    });

    test('chat messages persist across ui_render calls', () {
      // Append a chat message first.
      provider.simulateMessage(jsonEncode({
        'type': 'ui_append',
        'target_id': 'chat-1',
        'data': {'role': 'user', 'text': 'Before render'},
      }));

      // Now receive a full render — chatMessages should remain.
      provider.simulateMessage(jsonEncode({
        'type': 'ui_render',
        'components': [
          {'type': 'container', 'id': 'new-root', 'children': []},
        ],
      }));

      expect(provider.chatMessages, hasLength(1));
      expect(provider.chatMessages[0]['text'], 'Before render');
    });
  });
}
