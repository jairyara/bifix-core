/// Domain-level error used across repositories and presentation.
///
/// Repositories translate transport errors (Dio, parsing, etc.) into an
/// [AppFailure] so the UI never needs to know about HTTP details.
class AppFailure implements Exception {
  const AppFailure(this.message, {this.statusCode});

  /// Human-readable, user-facing message (in Spanish, the app's locale).
  final String message;

  /// Optional HTTP status code when the failure came from the API.
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'AppFailure($statusCode): $message';
}
