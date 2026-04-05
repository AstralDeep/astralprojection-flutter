import 'dart:io';

/// Reads `.env` credentials from the AstralBody repo for integration tests.
///
/// Falls back to `--dart-define` values if the `.env` file is not found.
/// Usage:
///   final env = EnvHelper.load();
///   final user = env['KEYCLOAK_TEST_USER'];
///   final pass = env['KEYCLOAK_TEST_PASSWORD'];
class EnvHelper {
  static Map<String, String>? _cache;

  /// Load environment variables from the AstralBody `.env` file.
  ///
  /// Searches for `.env` in common relative paths from the Flutter repo.
  /// Returns a map of key-value pairs. Values may contain special characters.
  static Map<String, String> load() {
    if (_cache != null) return _cache!;

    final envMap = <String, String>{};

    // Try to find the .env file relative to the Flutter project root
    final candidates = [
      '../AstralBody/.env',
      '../../AstralBody/.env',
      '../MCP/AstralBody/.env',
      // Absolute fallback for CI or known dev machine
      'c:/Users/sear234/Desktop/Containers/MCP/AstralBody/.env',
    ];

    File? envFile;
    for (final path in candidates) {
      final f = File(path);
      if (f.existsSync()) {
        envFile = f;
        break;
      }
    }

    if (envFile != null) {
      final lines = envFile.readAsLinesSync();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final eqIndex = trimmed.indexOf('=');
        if (eqIndex <= 0) continue;
        final key = trimmed.substring(0, eqIndex).trim();
        var value = trimmed.substring(eqIndex + 1).trim();
        // Strip surrounding quotes (single or double)
        if ((value.startsWith("'") && value.endsWith("'")) ||
            (value.startsWith('"') && value.endsWith('"'))) {
          value = value.substring(1, value.length - 1);
        }
        envMap[key] = value;
      }
    }

    // Overlay with --dart-define values (take precedence)
    const dartDefineKeys = [
      'KEYCLOAK_TEST_USER',
      'KEYCLOAK_TEST_PASSWORD',
      'BACKEND_HOST',
      'BACKEND_PORT',
      'MOCK_AUTH',
    ];
    for (final key in dartDefineKeys) {
      final val = String.fromEnvironment(key);
      if (val.isNotEmpty) {
        envMap[key] = val;
      }
    }

    _cache = envMap;
    return envMap;
  }

  /// Get a specific env value, or null if not found.
  static String? get(String key) => load()[key];

  /// Get the test username from env.
  static String get testUser =>
      get('KEYCLOAK_TEST_USER') ?? 'test_user';

  /// Get the test password from env.
  static String get testPassword =>
      get('KEYCLOAK_TEST_PASSWORD') ?? '';

  /// Get the backend host.
  static String get backendHost =>
      get('BACKEND_HOST') ?? 'localhost';

  /// Get the backend port.
  static int get backendPort =>
      int.tryParse(get('BACKEND_PORT') ?? '8001') ?? 8001;
}
