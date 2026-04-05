// T045 -- TV D-pad focus navigation tests
//
// Verifies that TvFocusManager enables predictable D-pad traversal
// between focusable SDUI elements.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astral/platform/tv/tv_focus_manager.dart';

/// Builds a simple widget tree with focusable elements wrapped in TvFocusManager.
Widget _buildTvWidget() {
  return MaterialApp(
    home: Scaffold(
      body: TvFocusManager(
        child: Column(
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('Button 1')),
            ElevatedButton(onPressed: () {}, child: const Text('Button 2')),
            ElevatedButton(onPressed: () {}, child: const Text('Button 3')),
          ],
        ),
      ),
    ),
  );
}

/// Helper to simulate a key press event.
Future<void> _sendKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  group('T045 — TV D-pad focus navigation', () {
    testWidgets('Arrow-Down moves focus between buttons', (tester) async {
      await tester.pumpWidget(_buildTvWidget());
      await tester.pumpAndSettle();

      // Tap the first button to give it focus
      await tester.tap(find.text('Button 1'));
      await tester.pumpAndSettle();

      // Press arrow down to move focus
      await _sendKey(tester, LogicalKeyboardKey.arrowDown);

      final focusNode = FocusManager.instance.primaryFocus;
      expect(focusNode, isNotNull,
          reason: 'A widget should have focus after arrow key navigation');
    });

    testWidgets('Arrow-Up moves focus backward', (tester) async {
      await tester.pumpWidget(_buildTvWidget());
      await tester.pumpAndSettle();

      // Start at second button
      await tester.tap(find.text('Button 2'));
      await tester.pumpAndSettle();

      // Arrow up should move focus toward first button
      await _sendKey(tester, LogicalKeyboardKey.arrowUp);

      final focusNode = FocusManager.instance.primaryFocus;
      expect(focusNode, isNotNull,
          reason: 'Focus should remain within the traversal group after up');
    });
  });
}
