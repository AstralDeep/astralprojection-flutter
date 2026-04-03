// T076 — Widget test: WatchTheme compact layout for ~200px viewport
//
// Verifies that:
// - WatchTheme.theme is dark mode
// - Font sizes are compact (bodyMedium <= 12)
// - Card margins are tight
// - Button padding is compact
// - Visual density is compact
// - maxViewportWidth is ~200px

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astral/platform/watch/watch_theme.dart';

void main() {
  group('T076 — WatchTheme compact layout', () {
    late ThemeData theme;

    setUp(() {
      theme = WatchTheme.theme;
    });

    test('theme is dark mode', () {
      expect(theme.brightness, Brightness.dark);
    });

    test('scaffold background is pure black', () {
      expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
    });

    test('bodyMedium font size is compact (<=12)', () {
      final bodyMedium = theme.textTheme.bodyMedium;
      expect(bodyMedium, isNotNull);
      expect(bodyMedium!.fontSize, lessThanOrEqualTo(12));
    });

    test('bodyLarge font size is compact (<=14)', () {
      final bodyLarge = theme.textTheme.bodyLarge;
      expect(bodyLarge, isNotNull);
      expect(bodyLarge!.fontSize, lessThanOrEqualTo(14));
    });

    test('headlineMedium font size is compact (<=18)', () {
      final headlineMedium = theme.textTheme.headlineMedium;
      expect(headlineMedium, isNotNull);
      expect(headlineMedium!.fontSize, lessThanOrEqualTo(18));
    });

    test('labelSmall font size is very small (<=10)', () {
      final labelSmall = theme.textTheme.labelSmall;
      expect(labelSmall, isNotNull);
      expect(labelSmall!.fontSize, lessThanOrEqualTo(10));
    });

    test('card margin is tight', () {
      final cardTheme = theme.cardTheme;
      final margin = cardTheme.margin as EdgeInsets?;
      expect(margin, isNotNull);
      expect(margin!.vertical, lessThanOrEqualTo(8.0));
    });

    test('icon size is compact', () {
      expect(theme.iconTheme.size, lessThanOrEqualTo(18.0));
    });

    test('visual density is compact', () {
      expect(theme.visualDensity, VisualDensity.compact);
    });

    test('maxViewportWidth is approximately 200px', () {
      expect(WatchTheme.maxViewportWidth, closeTo(200.0, 20.0));
    });

    test('contentPadding is tight', () {
      final padding = WatchTheme.contentPadding;
      expect(padding.left, lessThanOrEqualTo(8.0));
      expect(padding.top, lessThanOrEqualTo(8.0));
      expect(padding.right, lessThanOrEqualTo(8.0));
      expect(padding.bottom, lessThanOrEqualTo(8.0));
    });

    testWidgets('theme renders correctly in a constrained 200px viewport',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WatchTheme.theme,
          home: const SizedBox(
            width: 200,
            height: 250,
            child: Scaffold(
              body: Center(child: Text('Glanceable')),
            ),
          ),
        ),
      );

      expect(find.text('Glanceable'), findsOneWidget);
    });

    test('divider theme is compact', () {
      final dividerTheme = theme.dividerTheme;
      expect(dividerTheme.space, lessThanOrEqualTo(8.0));
      expect(dividerTheme.thickness, lessThanOrEqualTo(1.0));
    });

    test('progress indicator is thin', () {
      final progressTheme = theme.progressIndicatorTheme;
      expect(progressTheme.linearMinHeight, lessThanOrEqualTo(4.0));
    });

    test('tap target size is shrink-wrapped', () {
      expect(
        theme.materialTapTargetSize,
        MaterialTapTargetSize.shrinkWrap,
      );
    });
  });
}
