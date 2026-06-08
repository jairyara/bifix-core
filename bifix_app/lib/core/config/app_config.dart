/// Global configuration for the app.
///
/// The backend/API is developed in parallel and lives elsewhere. While it is
/// not ready we run against in-memory mock repositories. Flip [useMockApi] to
/// `false` (or pass `--dart-define=USE_MOCK_API=false`) to consume the real
/// API at [apiBaseUrl].
class AppConfig {
  const AppConfig._();

  /// Base URL of the external API, **including the `/api/v1` prefix** under
  /// which the Laravel backend serves every route. Override at build/run time:
  ///   flutter run --dart-define=API_BASE_URL=https://api.vikla.app/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.vikla.local/api/v1',
  );

  /// When true, the app uses in-memory mock data instead of hitting the API.
  /// Defaults to true so the frontend runs standalone while the backend is
  /// still being built.
  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: true,
  );
}
