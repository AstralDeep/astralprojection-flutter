// T046 -- TV theme tests
//
// Verifies that TvTheme applies the correct text scale factor,
// content padding, and generous focus/touch targets for TV layouts.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astral/platform/tv/tv_theme.dart';

void main() {
  group('T046 — TV theme constants', () {
    test('textScaleFactor is 1.5x', () {
      expect(TvTheme.textScaleFactor, 1.5);
    });

    test('contentPadding is 32px on all sides', () {
      expect(TvTheme.contentPadding, const EdgeInsets.all(32.0));
    });

    test('focusBorderColor is amber #FFD600', () {
      expect(TvTheme.focusBorderColor, const Color(0xFFFFD600));
    });

    test('focusBorderWidth is 3px', () {
      expect(TvTheme.focusBorderWidth, 3.0);
    });
  });

  group('T046 — TV ThemeData', () {
    late ThemeData tvTheme;

    setUp(() {
      tvTheme = TvTheme.theme;
    });

    test('theme uses dark brightness', () {
      expect(tvTheme.brightness, Brightness.dark);
    });

    test('visual density is maximal for generous touch/focus targets', () {
      expect(tvTheme.visualDensity.horizontal, 4.0);
      expect(tvTheme.visualDensity.vertical, 4.0);
    });

    test('body text sizes are scaled up for 10ft readability', () {
      // bodyLarge should be at least 24px (roughly 16 * 1.5)
      expect(tvTheme.textTheme.bodyLarge?.fontSize, greaterThanOrEqualTo(24));
      // bodyMedium should be at least 21px (roughly 14 * 1.5)
      expect(tvTheme.textTheme.bodyMedium?.fontSize, greaterThanOrEqualTo(21));
    });

    test('elevated button has generous padding', () {
      final buttonStyle = tvTheme.elevatedButtonTheme.style;
      expect(buttonStyle, isNotNull);

      // Resolve the padding from the button style
      final padding = buttonStyle!.padding?.resolve({});
      expect(padding, isNotNull, reason: 'Button should have explicit padding');

      // Horizontal padding should be >= 48 for TV-size targets
      final horizontal = (padding as EdgeInsets).left;
      expect(horizontal, greaterThanOrEqualTo(48.0));

      // Vertical padding should be >= 24
      final vertical = padding.top;
      expect(vertical, greaterThanOrEqualTo(24.0));
    });

    test('outlined button has generous padding', () {
      final buttonStyle = tvTheme.outlinedButtonTheme.style;
      expect(buttonStyle, isNotNull);

      final padding = buttonStyle!.padding?.resolve({}) as EdgeInsets;
      expect(padding.left, greaterThanOrEqualTo(48.0));
      expect(padding.top, greaterThanOrEqualTo(24.0));
    });

    testWidgets('1.5x text scale applied via MediaQuery in TV layout',
        (tester) async {
      // Simulate applying the TV text scale factor via MediaQuery
      await tester.pumpWidget(
        MaterialApp(
          theme: TvTheme.theme,
          home: Builder(
            builder: (context) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(TvTheme.textScaleFactor),
                ),
                child: const Scaffold(
                  body: Padding(
                    padding: TvTheme.contentPadding,
                    child: Text('TV Test'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify text renders
      expect(find.text('TV Test'), findsOneWidget);

      // Verify the padding is applied (32px on all sides)
      final padding = tester.widget<Padding>(find.byType(Padding).last);
      expect(padding.padding, TvTheme.contentPadding);
    });

    testWidgets('32px content padding applied correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TvTheme.theme,
          home: const Scaffold(
            body: Padding(
              padding: TvTheme.contentPadding,
              child: Text('Padded Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final padding = tester.widget<Padding>(find.byType(Padding).last);
      final edgeInsets = padding.padding as EdgeInsets;
      expect(edgeInsets.left, 32.0);
      expect(edgeInsets.right, 32.0);
      expect(edgeInsets.top, 32.0);
      expect(edgeInsets.bottom, 32.0);
    });
  });
}
