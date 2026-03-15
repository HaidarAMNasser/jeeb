/// Application Configuration
class AppConfig {
  AppConfig._();

  static const String appName = 'Jeeb app';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Developer Info
  static const String developerName = 'Haidar Nasser';
  static const String developerEmail = 'haideramnasser09@gmail.com';

  // Environment
  static const bool isProduction = false;
  static const bool enableLogging = true;

  // API Configuration
  static String get baseUrl {
    return 'https://api.jeeb2.com/api/v1/';
  }

  /// Base URL for user/media assets (profile images etc.). Backend may return relative paths.
  static String get assetsBaseUrl {
    final u = baseUrl;
    final match = RegExp(r'^(https?://[^/]+)').firstMatch(u);
    return match != null ? '${match.group(1)}/' : u;
  }
}
