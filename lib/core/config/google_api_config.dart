/// Google Cloud API keys used by the app.
///
/// **Security:** Keys in source or `local.properties` can be extracted from builds.
/// Restrict each key in [Google Cloud Console](https://console.cloud.google.com/) (API + Android/iOS apps).
/// Prefer `--dart-define=GOOGLE_DIRECTIONS_API_KEY=...` for CI and omit [defaultValue].
class GoogleApiConfig {
  GoogleApiConfig._();

  /// Directions API (HTTP). Separate key from Maps SDK is supported.
  static const String directionsApiKey = String.fromEnvironment(
    'GOOGLE_DIRECTIONS_API_KEY',
    defaultValue: 'AIzaSyBjaiHVyaPf6UnOK9Vz787nkNcZK9pgci4',
  );
}
