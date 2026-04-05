import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Simple position data class returned by [GeolocationService].
class GeoPosition {
  final double lat;
  final double lng;
  final double? accuracy;

  const GeoPosition({
    required this.lat,
    required this.lng,
    this.accuracy,
  });

  @override
  String toString() =>
      'GeoPosition(lat: $lat, lng: $lng, accuracy: $accuracy)';
}

/// Lightweight geolocation service that performs silent GPS capture,
/// gated by the device profile's `hasGeolocation` capability (T027).
///
/// Uses a platform method channel so no heavy third-party dependency is
/// required. The native side should implement the `astral/geolocation`
/// channel with a `getCurrentPosition` method that returns
/// `{"lat": double, "lng": double, "accuracy": double?}`.
///
/// Returns `null` when geolocation is unavailable, the device does not
/// support it (e.g. TV), or the platform call fails.
class GeolocationService {
  final _logger = Logger();

  static const _channel = MethodChannel('astral/geolocation');

  /// Whether geolocation is available on this device.
  ///
  /// Should be set from [DeviceProfileProvider.toDeviceMap()]['has_geolocation'].
  final bool hasGeolocation;

  GeolocationService({required this.hasGeolocation});

  /// Silently request the current GPS position.
  ///
  /// Returns `null` if geolocation is not available on this device profile,
  /// if permission is denied, or if the platform call fails for any reason.
  Future<GeoPosition?> getCurrentPosition() async {
    if (!hasGeolocation) {
      _logger.d('GeolocationService: geolocation not available on this device');
      return null;
    }

    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('getCurrentPosition');

      if (result == null) {
        _logger.w('GeolocationService: platform returned null');
        return null;
      }

      final lat = result['lat'] as double?;
      final lng = result['lng'] as double?;
      if (lat == null || lng == null) {
        _logger.w('GeolocationService: missing lat/lng in response');
        return null;
      }

      final position = GeoPosition(
        lat: lat,
        lng: lng,
        accuracy: result['accuracy'] as double?,
      );
      _logger.d('GeolocationService: position acquired — $position');
      return position;
    } on PlatformException catch (e) {
      _logger.e('GeolocationService: platform error', error: e);
      return null;
    } on MissingPluginException {
      _logger.w(
          'GeolocationService: no native implementation for astral/geolocation');
      return null;
    } catch (e) {
      _logger.e('GeolocationService: unexpected error', error: e);
      return null;
    }
  }
}
