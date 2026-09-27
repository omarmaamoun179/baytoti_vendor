/// A backend or transport error, normalized into one shape.
///
/// Data sources throw this; repositories convert it into a
/// [Failure](../domain/failure.dart) before it crosses into the domain layer.
class ApiErrorModel implements Exception {
  final String message;

  /// Backend error code, when the response carries one (see [StatusCode]).
  final dynamic code;

  /// Field-level validation errors, keyed by field name.
  final Map<String, dynamic>? errors;

  final int? statusCode;

  /// Coarse bucket — `NetworkError`, `ServerError`, `Unauthorized`, …
  final String? type;

  final DateTime timestamp;

  ApiErrorModel({
    required this.message,
    this.code,
    this.errors,
    this.statusCode,
    this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) => ApiErrorModel(
        message: (json['message'] ?? 'Unknown error occurred') as String,
        code: json['code'],
        errors: json['errors'] as Map<String, dynamic>?,
        statusCode: json['statusCode'] as int?,
        type: json['type'] as String?,
        timestamp: DateTime.tryParse((json['timestamp'] ?? '') as String),
      );

  Map<String, dynamic> toJson() => {
        'message': message,
        'code': code,
        'errors': errors,
        'statusCode': statusCode,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() => 'ApiErrorModel($statusCode, $type): $message';
}
