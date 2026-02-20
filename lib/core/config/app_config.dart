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
    return isProduction
        ? 'https://api.production.com'
        : 'https://api.development.com';
  }
}
