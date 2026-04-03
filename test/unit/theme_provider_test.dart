// T023 — ThemeProvider unit tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astral/state/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    late ThemeProvider provider;

    setUp(() {
      provider = ThemeProvider();
    });

    group('initial state', () {
      test('has no backend theme', () {
        expect(provider.backendTheme, isNull);
      });

      test('hasBackendTheme is false', () {
        expect(provider.hasBackendTheme, isFalse);
      });
    });

    group('applyBackendTheme', () {
      test('creates a ThemeData from color config', () {
        provider.applyBackendTheme({
          'colors': {
            'primary': '#FF0000',
            'secondary': '#00FF00',
            'background': '#FFFFFF',
            'surface': '#F0F0F0',
            'error': '#FF0000',
            'on_primary': '#FFFFFF',
            'on_surface': '#000000',
          },
        });

        expect(provider.backendTheme, isNotNull);
        expect(provider.hasBackendTheme, isTrue);
        expect(provider.backendTheme, isA<ThemeData>());
      });

      test('sets primary color from hex', () {
        provider.applyBackendTheme({
          'colors': {'primary': '#FF0000'},
        });

        final theme = provider.backendTheme!;
        expect(theme.colorScheme.primary, const Color(0xFFFF0000));
      });

      test('sets secondary color from hex', () {
        provider.applyBackendTheme({
          'colors': {'secondary': '#00FF00'},
        });

        final theme = provider.backendTheme!;
        expect(theme.colorScheme.secondary, const Color(0xFF00FF00));
      });

      test('applies typography base font size', () {
        provider.applyBackendTheme({
          'typography': {'base_font_size': 16},
        });

        final theme = provider.backendTheme!;
        expect(theme.textTheme.bodyMedium?.fontSize, 16.0);
        expect(theme.textTheme.bodyLarge?.fontSize, closeTo(18.4, 0.1));
        expect(theme.textTheme.bodySmall?.fontSize, closeTo(13.6, 0.1));
      });

      test('applies font family via text theme', () {
        provider.applyBackendTheme({
          'typography': {'font_family': 'Roboto Mono'},
        });

        final theme = provider.backendTheme!;
        // fontFamily is applied through the ThemeData constructor and reflected
        // in the text theme's default font family
        expect(theme.textTheme.bodyMedium?.fontFamily, 'Roboto Mono');
      });

      test('applies spacing density', () {
        provider.applyBackendTheme({
          'spacing': {'density': -1.0},
        });

        final theme = provider.backendTheme!;
        expect(theme.visualDensity.horizontal, -1.0);
        expect(theme.visualDensity.vertical, -1.0);
      });

      test('notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.applyBackendTheme({
          'colors': {'primary': '#336699'},
        });

        expect(notified, isTrue);
      });
    });

    group('clearBackendTheme', () {
      test('resets backendTheme to null', () {
        provider.applyBackendTheme({
          'colors': {'primary': '#FF0000'},
        });
        expect(provider.backendTheme, isNotNull);

        provider.clearBackendTheme();
        expect(provider.backendTheme, isNull);
        expect(provider.hasBackendTheme, isFalse);
      });

      test('notifies listeners', () {
        provider.applyBackendTheme({
          'colors': {'primary': '#FF0000'},
        });

        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearBackendTheme();
        expect(notified, isTrue);
      });
    });

    group('color parsing', () {
      test('#FF0000 parses to red', () {
        provider.applyBackendTheme({
          'colors': {'primary': '#FF0000'},
        });
        expect(
            provider.backendTheme!.colorScheme.primary, const Color(0xFFFF0000));
      });

      test('#00FF00 parses to green', () {
        provider.applyBackendTheme({
          'colors': {'primary': '#00FF00'},
        });
        expect(
            provider.backendTheme!.colorScheme.primary, const Color(0xFF00FF00));
      });

      test('#0000FF parses to blue', () {
        provider.applyBackendTheme({
          'colors': {'primary': '#0000FF'},
        });
        expect(
            provider.backendTheme!.colorScheme.primary, const Color(0xFF0000FF));
      });

      test('8-digit hex with alpha is supported', () {
        provider.applyBackendTheme({
          'colors': {'primary': '#80FF0000'},
        });
        expect(
            provider.backendTheme!.colorScheme.primary, const Color(0x80FF0000));
      });

      test('missing colors use defaults', () {
        // Empty config — all colors should fall back to defaults
        provider.applyBackendTheme({});

        final theme = provider.backendTheme!;
        // Primary defaults to Colors.blue
        expect(theme.colorScheme.primary, Colors.blue);
        // Secondary defaults to Colors.blueAccent
        expect(theme.colorScheme.secondary, Colors.blueAccent);
        // Error defaults to Colors.red
        expect(theme.colorScheme.error, Colors.red);
      });

      test('invalid color string falls back to default', () {
        provider.applyBackendTheme({
          'colors': {'primary': 'not-a-color'},
        });

        final theme = provider.backendTheme!;
        // Should use default blue
        expect(theme.colorScheme.primary, Colors.blue);
      });

      test('null color value falls back to default', () {
        provider.applyBackendTheme({
          'colors': {'primary': null},
        });

        final theme = provider.backendTheme!;
        expect(theme.colorScheme.primary, Colors.blue);
      });
    });

    group('default typography', () {
      test('base font size defaults to 14 when not provided', () {
        provider.applyBackendTheme({});

        final theme = provider.backendTheme!;
        expect(theme.textTheme.bodyMedium?.fontSize, 14.0);
      });

      test('visual density defaults to standard when not provided', () {
        provider.applyBackendTheme({});

        final theme = provider.backendTheme!;
        expect(theme.visualDensity, VisualDensity.standard);
      });
    });
  });
}
