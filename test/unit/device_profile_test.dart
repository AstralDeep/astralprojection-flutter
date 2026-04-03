// T022 — DeviceProfileProvider unit tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astral/state/device_profile_provider.dart';

void main() {
  group('DeviceProfileProvider', () {
    late DeviceProfileProvider provider;

    setUp(() {
      provider = DeviceProfileProvider();
    });

    group('initial state', () {
      test('deviceType defaults to mobile', () {
        expect(provider.deviceType, 'mobile');
      });

      test('dimensions default to zero', () {
        expect(provider.screenWidth, 0);
        expect(provider.screenHeight, 0);
        expect(provider.viewportWidth, 0);
        expect(provider.viewportHeight, 0);
      });

      test('pixelRatio defaults to 1.0', () {
        expect(provider.pixelRatio, 1.0);
      });

      test('inputModality defaults to touch', () {
        expect(provider.inputModality, 'touch');
      });
    });

    group('_detectDeviceType via updateFromMediaQuery', () {
      // On desktop platforms (Windows test host), detection uses the
      // non-mobile branch: <=480 -> mobile, <=1024 -> tablet, >1024 -> tv

      test('viewport 320 is detected as mobile', () {
        final mq = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        ).copyWith(size: const Size(320, 568));

        provider.updateFromMediaQuery(mq);
        expect(provider.deviceType, 'mobile');
      });

      test('viewport 768 is detected as tablet', () {
        final mq = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        ).copyWith(size: const Size(768, 1024));

        provider.updateFromMediaQuery(mq);
        expect(provider.deviceType, 'tablet');
      });

      test('viewport 1200 is detected as tv', () {
        final mq = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        ).copyWith(size: const Size(1200, 800));

        provider.updateFromMediaQuery(mq);
        expect(provider.deviceType, 'tv');
      });

      test('viewport 480 is mobile (boundary)', () {
        final mq = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        ).copyWith(size: const Size(480, 800));

        provider.updateFromMediaQuery(mq);
        expect(provider.deviceType, 'mobile');
      });

      test('viewport 1024 is tablet (boundary)', () {
        final mq = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        ).copyWith(size: const Size(1024, 768));

        provider.updateFromMediaQuery(mq);
        expect(provider.deviceType, 'tablet');
      });
    });

    group('updateFromMediaQuery updates dimensions', () {
      test('sets viewport and screen dimensions', () {
        final mq = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        ).copyWith(
          size: const Size(400, 800),
          devicePixelRatio: 2.0,
        );

        provider.updateFromMediaQuery(mq);

        expect(provider.viewportWidth, 400);
        expect(provider.viewportHeight, 800);
        expect(provider.pixelRatio, 2.0);
        expect(provider.screenWidth, 800); // 400 * 2.0
        expect(provider.screenHeight, 1600); // 800 * 2.0
      });

      test('notifies listeners on change', () {
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        final mq = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        ).copyWith(size: const Size(500, 900));

        provider.updateFromMediaQuery(mq);

        expect(notifyCount, greaterThan(0));
      });
    });

    group('toDeviceMap', () {
      test('returns correct structure with expected keys', () {
        final mq = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        ).copyWith(
          size: const Size(375, 812),
          devicePixelRatio: 3.0,
        );

        provider.updateFromMediaQuery(mq);
        final map = provider.toDeviceMap();

        expect(map['device_type'], isA<String>());
        expect(map['screen_width'], isA<int>());
        expect(map['screen_height'], isA<int>());
        expect(map['viewport_width'], isA<int>());
        expect(map['viewport_height'], isA<int>());
        expect(map['pixel_ratio'], isA<double>());
        expect(map['has_touch'], isA<bool>());
        expect(map['has_geolocation'], isA<bool>());
        expect(map['has_microphone'], isA<bool>());
        expect(map['has_camera'], isA<bool>());
        expect(map['has_file_system'], isA<bool>());
        expect(map['connection_type'], 'wifi');
        expect(map['user_agent'], 'AstralBody-Flutter/1.0');
      });

      test('mobile device has touch and capabilities', () {
        final mq = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        ).copyWith(size: const Size(375, 812));

        provider.updateFromMediaQuery(mq);
        final map = provider.toDeviceMap();

        expect(map['device_type'], 'mobile');
        expect(map['has_touch'], isTrue);
        expect(map['has_geolocation'], isTrue);
        expect(map['has_file_system'], isTrue);
      });

      test('tv device has no touch and limited capabilities', () {
        final mq = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        ).copyWith(size: const Size(1920, 1080));

        provider.updateFromMediaQuery(mq);
        final map = provider.toDeviceMap();

        expect(map['device_type'], 'tv');
        expect(map['has_touch'], isFalse);
        expect(map['has_geolocation'], isFalse);
        expect(map['has_microphone'], isFalse);
        expect(map['has_camera'], isFalse);
        expect(map['has_file_system'], isFalse);
      });

      test('viewport dimensions are rounded to int', () {
        final mq = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first,
        ).copyWith(size: const Size(375.5, 812.7));

        provider.updateFromMediaQuery(mq);
        final map = provider.toDeviceMap();

        expect(map['viewport_width'], isA<int>());
        expect(map['viewport_height'], isA<int>());
      });
    });
  });
}
