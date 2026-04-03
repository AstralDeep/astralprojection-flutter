import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Detects device capabilities and reports them to the backend via register_ui.
class DeviceProfileProvider extends ChangeNotifier {
  String _deviceType = 'mobile';
  double _screenWidth = 0;
  double _screenHeight = 0;
  double _viewportWidth = 0;
  double _viewportHeight = 0;
  double _pixelRatio = 1.0;
  String _inputModality = 'touch';

  String get deviceType => _deviceType;
  double get screenWidth => _screenWidth;
  double get screenHeight => _screenHeight;
  double get viewportWidth => _viewportWidth;
  double get viewportHeight => _viewportHeight;
  double get pixelRatio => _pixelRatio;
  String get inputModality => _inputModality;

  /// Update profile from MediaQuery data. Call on init and orientation change.
  void updateFromMediaQuery(MediaQueryData mq) {
    final size = mq.size;
    _pixelRatio = mq.devicePixelRatio;
    _viewportWidth = size.width;
    _viewportHeight = size.height;
    _screenWidth = size.width * _pixelRatio;
    _screenHeight = size.height * _pixelRatio;

    final oldType = _deviceType;
    _deviceType = _detectDeviceType(size.width);
    _inputModality = _detectInputModality(_deviceType);

    if (oldType != _deviceType ||
        _viewportWidth != size.width ||
        _viewportHeight != size.height) {
      notifyListeners();
    }
  }

  String _detectDeviceType(double viewportWidth) {
    // Platform-based overrides
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android) {
      // TV detection: Android TV reports large viewport with no touch
      if (viewportWidth > 1024) return 'tv';
      if (viewportWidth <= 480) return 'mobile';
      return 'tablet';
    }
    // macOS / linux / windows default to browser-like behavior
    if (viewportWidth <= 480) return 'mobile';
    if (viewportWidth <= 1024) return 'tablet';
    return 'tv';
  }

  String _detectInputModality(String deviceType) {
    switch (deviceType) {
      case 'tv':
        return 'dpad';
      case 'watch':
        return 'crown';
      default:
        return 'touch';
    }
  }

  /// Capabilities map for register_ui device field.
  Map<String, dynamic> toDeviceMap() {
    return {
      'device_type': _deviceType,
      'screen_width': _screenWidth.round(),
      'screen_height': _screenHeight.round(),
      'viewport_width': _viewportWidth.round(),
      'viewport_height': _viewportHeight.round(),
      'pixel_ratio': _pixelRatio,
      'has_touch': _deviceType == 'mobile' || _deviceType == 'tablet',
      'has_geolocation': _deviceType != 'tv',
      'has_microphone': _deviceType != 'tv',
      'has_camera': _deviceType != 'tv',
      'has_file_system': _deviceType != 'tv' && _deviceType != 'watch',
      'connection_type': 'wifi',
      'user_agent': 'AstralBody-Flutter/1.0',
    };
  }
}
