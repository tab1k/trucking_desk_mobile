class AppConfig {
  const AppConfig._();

  /// Base URL for backend API. Override via --dart-define=API_BASE_URL
  /// when building or running the app.

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.31.99:8000/api/v1',
  );
}
