// T038 — GlassCard widget tests
//
// Verifies that the GlassCard applies a BackdropFilter, renders a
// semi-transparent container with the correct decoration, and passes
// through its child widget.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astral/components/common/glass_card.dart';

void main() {
  group('GlassCard', () {
    testWidgets('renders a BackdropFilter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('BackdropFilter uses blur sigma 12', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Test'),
            ),
          ),
        ),
      );

      final backdropFilter =
          tester.widget<BackdropFilter>(find.byType(BackdropFilter));
      // Verify that the filter is an ImageFilter (blur)
      expect(backdropFilter.filter, isNotNull);
      // Compare against the expected blur filter
      expect(
        backdropFilter.filter,
        equals(ImageFilter.blur(sigmaX: 12, sigmaY: 12)),
      );
    });

    testWidgets('contains semi-transparent surface with correct decoration',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Test'),
            ),
          ),
        ),
      );

      // Find the Container that is a descendant of BackdropFilter
      final containerFinder = find.descendant(
        of: find.byType(BackdropFilter),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      // Verify semi-transparent dark surface color
      expect(
        decoration.color,
        equals(const Color(0xFF1A1E2E).withValues(alpha: 0.6)),
      );

      // Verify border radius
      expect(
        decoration.borderRadius,
        equals(BorderRadius.circular(16.0)),
      );

      // Verify border
      expect(decoration.border, isNotNull);
      final border = decoration.border as Border;
      expect(
        border.top.color,
        equals(const Color(0xFFFFFFFF).withValues(alpha: 0.1)),
      );
    });

    testWidgets('child widget is rendered inside GlassCard', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Hello Glass'),
            ),
          ),
        ),
      );

      expect(find.text('Hello Glass'), findsOneWidget);

      // Verify the text is a descendant of GlassCard
      expect(
        find.descendant(
          of: find.byType(GlassCard),
          matching: find.text('Hello Glass'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses default padding of EdgeInsets.all(16)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Test'),
            ),
          ),
        ),
      );

      final containerFinder = find.descendant(
        of: find.byType(BackdropFilter),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder);
      expect(container.padding, equals(const EdgeInsets.all(16)));
    });

    testWidgets('accepts custom padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              padding: EdgeInsets.all(32),
              child: Text('Test'),
            ),
          ),
        ),
      );

      final containerFinder = find.descendant(
        of: find.byType(BackdropFilter),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder);
      expect(container.padding, equals(const EdgeInsets.all(32)));
    });
  });
}
