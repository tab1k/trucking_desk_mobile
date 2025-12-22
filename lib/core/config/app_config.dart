class AppConfig {
  const AppConfig._();

  /// Base URL for backend API. Override via --dart-define=API_BASE_URL
  /// when building or running the app.

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://fura24.kz/api/v1',
  );
}