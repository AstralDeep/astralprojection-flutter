// T069 -- Widget test: TvTheme has 1.5x text scale and generous spacing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/platform/tv/tv_theme.dart';

void main() {
  group('TvTheme', () {
    test('textScaleFactor is 1.5', () {
      expect(TvTheme.textScaleFactor, 1.5);
    });

    test('contentPadding is generous (32.0 all sides)', () {
      expect(TvTheme.contentPadding, const EdgeInsets.all(32.0));
    });

    test('focusBorderColor is a high-contrast amber/yellow', () {
      expect(TvTheme.focusBorderColor, const Color(0xFFFFD600));
    });

    test('focusBorderWidth is 3.0', () {
      expect(TvTheme.focusBorderWidth, 3.0);
    });

    test('theme returns a valid ThemeData', () {
      final theme = TvTheme.theme;
      expect(theme, isA<ThemeData>());
    });

    test('theme uses dark brightness', () {
      final theme = TvTheme.theme;
      expect(theme.brightness, Brightness.dark);
    });

    test('theme text sizes are approximately 1.5x base sizes', () {
      final theme = TvTheme.theme;
      // Base bodyMedium is 14pt; at 1.5x it should be 21pt
      expect(theme.textTheme.bodyMedium?.fontSize, 21.0);
      // Base bodyLarge is 16pt; at 1.5x it should be 24pt
      expect(theme.textTheme.bodyLarge?.fontSize, 24.0);
      // Base bodySmall is 12pt; at 1.5x it should be 18pt
      expect(theme.textTheme.bodySmall?.fontSize, 18.0);
      // Base titleLarge is 22pt; at 1.5x it should be 33pt
      expect(theme.textTheme.titleLarge?.fontSize, 33.0);
      // Base headlineMedium is 28pt; at 1.5x it should be 42pt
      expect(theme.textTheme.headlineMedium?.fontSize, 42.0);
    });

    test('theme has generous visual density', () {
      final theme = TvTheme.theme;
      expect(theme.visualDensity.horizontal, 4.0);
      expect(theme.visualDensity.vertical, 4.0);
    });

    test('elevated button has generous padding', () {
      final theme = TvTheme.theme;
      final style = theme.elevatedButtonTheme.style;
      expect(style, isNotNull);

      // Resolve padding (no material states needed, it is fixed)
      final resolved = style!.padding!.resolve({});
      expect(resolved, isNotNull);
      // Horizontal 48, vertical 24
      expect(resolved!.horizontal, greaterThanOrEqualTo(96.0)); // 48 * 2
    });

    test('outlined button has generous padding', () {
      final theme = TvTheme.theme;
      final style = theme.outlinedButtonTheme.style;
      expect(style, isNotNull);

      final resolved = style!.padding!.resolve({});
      expect(resolved, isNotNull);
      expect(resolved!.horizontal, greaterThanOrEqualTo(96.0)); // 48 * 2
    });

    testWidgets('theme applies 1.5x text scale in a widget tree',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TvTheme.theme,
          home: const Scaffold(
            body: Center(child: Text('TV Text')),
          ),
        ),
      );

      // The text widget should be present and using the TV theme
      expect(find.text('TV Text'), findsOneWidget);

      // Verify the theme was applied by checking a known text style
      final style = DefaultTextStyle.of(
        tester.element(find.text('TV Text')),
      ).style;
      // bodyMedium is the default text style; should be 21.0 in TV theme
      expect(style.fontSize, 21.0);
    });

    test('input decoration has generous content padding', () {
      final theme = TvTheme.theme;
      final inputTheme = theme.inputDecorationTheme;
      expect(inputTheme.contentPadding,
          const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0));
    });
  });
}
