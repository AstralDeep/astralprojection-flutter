// T068 -- Widget test: TvFocusManager wraps content with FocusTraversalGroup
// and handles D-pad shortcuts.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/platform/tv/tv_focus_manager.dart';

void main() {
  group('TvFocusManager', () {
    testWidgets('wraps child with FocusTraversalGroup', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TvFocusManager(
              child: Text('Hello TV'),
            ),
          ),
        ),
      );

      // TvFocusManager adds its own FocusTraversalGroup (MaterialApp/Scaffold
      // also add some). Verify one exists as a direct descendant.
      expect(
        find.descendant(
          of: find.byType(TvFocusManager),
          matching: find.byType(FocusTraversalGroup),
        ),
        findsOneWidget,
      );
      expect(find.text('Hello TV'), findsOneWidget);
    });

    testWidgets('wraps child with Shortcuts widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TvFocusManager(
              child: Text('Shortcuts test'),
            ),
          ),
        ),
      );

      expect(find.byType(Shortcuts), findsWidgets);
    });

    testWidgets('arrow down moves focus to next focusable widget',
        (tester) async {
      final focusNode1 = FocusNode(debugLabel: 'button1');
      final focusNode2 = FocusNode(debugLabel: 'button2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvFocusManager(
              child: Column(
                children: [
                  Focus(
                    focusNode: focusNode1,
                    child: const Text('Button 1'),
                  ),
                  Focus(
                    focusNode: focusNode2,
                    child: const Text('Button 2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Give initial focus to button1
      focusNode1.requestFocus();
      await tester.pump();
      expect(focusNode1.hasFocus, isTrue);

      // Simulate arrow down
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      // Focus should have moved to button2
      expect(focusNode2.hasFocus, isTrue);

      // Clean up
      focusNode1.dispose();
      focusNode2.dispose();
    });

    testWidgets('arrow up moves focus to previous focusable widget',
        (tester) async {
      final focusNode1 = FocusNode(debugLabel: 'button1');
      final focusNode2 = FocusNode(debugLabel: 'button2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvFocusManager(
              child: Column(
                children: [
                  Focus(
                    focusNode: focusNode1,
                    child: const Text('Button 1'),
                  ),
                  Focus(
                    focusNode: focusNode2,
                    child: const Text('Button 2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Give initial focus to button2
      focusNode2.requestFocus();
      await tester.pump();
      expect(focusNode2.hasFocus, isTrue);

      // Simulate arrow up
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      // Focus should have moved to button1
      expect(focusNode1.hasFocus, isTrue);

      // Clean up
      focusNode1.dispose();
      focusNode2.dispose();
    });

    testWidgets('registers Enter key as ActivateIntent', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TvFocusManager(
              child: Text('Activate test'),
            ),
          ),
        ),
      );

      // Find the Shortcuts widget inside TvFocusManager
      final shortcutsWidget = tester.widget<Shortcuts>(
        find.descendant(
          of: find.byType(TvFocusManager),
          matching: find.byType(Shortcuts),
        ),
      );

      final shortcuts = shortcutsWidget.shortcuts;

      // Verify Enter maps to ActivateIntent
      final enterBinding =
          shortcuts[const SingleActivator(LogicalKeyboardKey.enter)];
      expect(enterBinding, isA<ActivateIntent>());

      // Verify Select maps to ActivateIntent
      final selectBinding =
          shortcuts[const SingleActivator(LogicalKeyboardKey.select)];
      expect(selectBinding, isA<ActivateIntent>());
    });

    testWidgets('registers all four arrow keys as DirectionalFocusIntent',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TvFocusManager(
              child: Text('Arrows test'),
            ),
          ),
        ),
      );

      final shortcutsWidget = tester.widget<Shortcuts>(
        find.descendant(
          of: find.byType(TvFocusManager),
          matching: find.byType(Shortcuts),
        ),
      );

      final shortcuts = shortcutsWidget.shortcuts;

      expect(
        shortcuts[const SingleActivator(LogicalKeyboardKey.arrowUp)],
        isA<DirectionalFocusIntent>(),
      );
      expect(
        shortcuts[const SingleActivator(LogicalKeyboardKey.arrowDown)],
        isA<DirectionalFocusIntent>(),
      );
      expect(
        shortcuts[const SingleActivator(LogicalKeyboardKey.arrowLeft)],
        isA<DirectionalFocusIntent>(),
      );
      expect(
        shortcuts[const SingleActivator(LogicalKeyboardKey.arrowRight)],
        isA<DirectionalFocusIntent>(),
      );
    });
  });
}
