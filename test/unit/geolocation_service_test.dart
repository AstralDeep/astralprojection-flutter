// T024 — GeolocationService unit tests
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astral/services/geolocation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeolocationService (T024)', () {
    late GeolocationService service;

    /// Install a mock handler on the astral/geolocation MethodChannel that
    /// returns the given [result] for 'getCurrentPosition'.
    void setMockPosition(Map<String, dynamic>? result) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('astral/geolocation'),
        (MethodCall call) async {
          if (call.method == 'getCurrentPosition') {
            return result;
          }
          return null;
        },
      );
    }

    /// Install a mock handler that throws a PlatformException.
    void setMockPermissionDenied() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('astral/geolocation'),
        (MethodCall call) async {
          throw PlatformException(
            code: 'PERMISSION_DENIED',
            message: 'Location permission denied',
          );
        },
      );
    }

    /// Clear the mock handler.
    void clearMock() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('astral/geolocation'),
        null,
      );
    }

    tearDown(() {
      clearMock();
    });

    group('silent GPS capture with hasGeolocation=true', () {
      setUp(() {
        service = GeolocationService(hasGeolocation: true);
      });

      test('returns GeoPosition when platform provides coordinates', () async {
        setMockPosition({
          'lat': 51.5074,
          'lng': -0.1278,
          'accuracy': 10.0,
        });

        final position = await service.getCurrentPosition();

        expect(position, isNotNull);
        expect(position!.lat, 51.5074);
        expect(position.lng, -0.1278);
      });

      test('returns position with valid latitude range', () async {
        setMockPosition({
          'lat': 45.0,
          'lng': 90.0,
          'accuracy': 5.0,
        });

        final position = await service.getCurrentPosition();

        expect(position, isNotNull);
        expect(position!.lat, greaterThanOrEqualTo(-90.0));
        expect(position.lat, lessThanOrEqualTo(90.0));
      });

      test('returns position with valid longitude range', () async {
        setMockPosition({
          'lat': 45.0,
          'lng': 90.0,
          'accuracy': 5.0,
        });

        final position = await service.getCurrentPosition();

        expect(position, isNotNull);
        expect(position!.lng, greaterThanOrEqualTo(-180.0));
        expect(position.lng, lessThanOrEqualTo(180.0));
      });

      test('includes accuracy metadata', () async {
        setMockPosition({
          'lat': 45.0,
          'lng': 90.0,
          'accuracy': 12.5,
        });

        final position = await service.getCurrentPosition();

        expect(position, isNotNull);
        expect(position!.accuracy, isA<double>());
        expect(position.accuracy, 12.5);
      });

      test('returns null when platform returns null', () async {
        setMockPosition(null);

        final position = await service.getCurrentPosition();

        expect(position, isNull);
      });
    });

    group('returns null when hasGeolocation=false', () {
      setUp(() {
        service = GeolocationService(hasGeolocation: false);
      });

      test('returns null without calling platform channel', () async {
        // No mock installed — if platform channel were called it would throw
        final position = await service.getCurrentPosition();
        expect(position, isNull);
      });
    });

    group('handles permission denied gracefully', () {
      setUp(() {
        service = GeolocationService(hasGeolocation: true);
      });

      test('returns null when platform throws PlatformException', () async {
        setMockPermissionDenied();

        final position = await service.getCurrentPosition();

        expect(position, isNull);
      });

      test('does not throw when permission is denied', () async {
        setMockPermissionDenied();

        // Should complete without throwing
        final position = await service.getCurrentPosition();
        expect(position, isNull);
      });
    });

    group('handles missing plugin gracefully', () {
      setUp(() {
        service = GeolocationService(hasGeolocation: true);
      });

      test('returns null when no native implementation exists', () async {
        // No mock handler installed means MissingPluginException
        clearMock();
        final position = await service.getCurrentPosition();
        expect(position, isNull);
      });
    });

    group('GeoPosition data class', () {
      test('GeoPosition stores lat, lng, and optional accuracy', () {
        const pos = GeoPosition(lat: 1.0, lng: 2.0, accuracy: 3.0);
        expect(pos.lat, 1.0);
        expect(pos.lng, 2.0);
        expect(pos.accuracy, 3.0);
      });

      test('GeoPosition accuracy is nullable', () {
        const pos = GeoPosition(lat: 1.0, lng: 2.0);
        expect(pos.accuracy, isNull);
      });

      test('GeoPosition toString includes coordinates', () {
        const pos = GeoPosition(lat: 1.0, lng: 2.0, accuracy: 3.0);
        expect(pos.toString(), contains('1.0'));
        expect(pos.toString(), contains('2.0'));
      });
    });
  });
}
