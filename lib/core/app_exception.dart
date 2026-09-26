/// Error thrown by the API layer. Carries the PeerTube error payload when the
/// server answered with a structured JSON error.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.type,
    this.details,
  });

  /// Human readable message (already localised by the server when available).
  final String message;

  /// HTTP status code, when the request reached the server.
  final int? statusCode;

  /// PeerTube error `code`/`type` field, e.g. `invalid_grant`.
  final String? type;

  /// Raw error body, kept for debugging.
  final Object? details;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  /// True when the server rejected the request because of a missing/expired
  /// two factor code.
  bool get isTwoFactorRequired => type == 'missing_two_factor';

  @override
  String toString() => message;
}
