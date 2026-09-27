import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

import '../domain/failure.dart';
import '../domain/failure_mapper.dart';
import 'api_error_model.dart';

/// Turns anything thrown by Dio (or anything else) into an [ApiErrorModel].
///
/// Messages are translation keys resolved through `easy_localization`, so the
/// fallback copy lives in `assets/translations/*.json` rather than being
/// hardcoded in one language.
class ApiErrorHandler {
  ApiErrorHandler._();

  static ApiErrorModel handle(dynamic error) {
    _log(error);

    if (error is ApiErrorModel) return error;
    if (error is DioException) return _handleDioError(error);

    return ApiErrorModel(
      message: 'unexpected_error'.tr(),
      type: 'UnknownError',
      statusCode: 500,
    );
  }

  /// Convenience for repositories: `Left(ApiErrorHandler.toFailure(e))`.
  ///
  /// Answers a typed failure so the offline case survives the trip — a Dio
  /// transport error becomes a [NetworkFailure], not a server one. Prefer
  /// `mapExceptionToFailure` where the network layer has already turned the
  /// error into an [AppException]; this is for a raw [DioException].
  static Failure toFailure(dynamic error) {
    final apiError = handle(error);

    return switch (apiError.type) {
      'NetworkError' => NetworkFailure(
          message: apiError.message,
          statusCode: apiError.statusCode,
        ),
      'ValidationError' => ValidationFailure(
          message: apiError.message,
          statusCode: apiError.statusCode ?? 422,
          fieldErrors: flattenFieldErrors(apiError.errors),
        ),
      _ => ServerFailure(
          message: apiError.message,
          statusCode: apiError.statusCode,
        ),
    };
  }

  static ApiErrorModel _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return ApiErrorModel(
          message: 'connection_failed'.tr(),
          type: 'NetworkError',
          statusCode: error.response?.statusCode ?? 503,
        );
      case DioExceptionType.cancel:
        return ApiErrorModel(
          message: 'request_cancelled'.tr(),
          type: 'RequestCancelled',
          statusCode: 499,
        );
      case DioExceptionType.badCertificate:
        return ApiErrorModel(
          message: 'security_certificate_error'.tr(),
          type: 'SecurityError',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);
      case DioExceptionType.unknown:
        return ApiErrorModel(
          message: 'connection_failed'.tr(),
          type: 'NetworkError',
          statusCode: error.response?.statusCode ?? 500,
        );
    }
  }

  static ApiErrorModel _handleBadResponse(Response? response) {
    final int? statusCode = response?.statusCode;
    final dynamic body = response?.data;

    String message = 'server_error'.tr();
    dynamic code;
    Map<String, dynamic>? errors;

    if (body is Map<String, dynamic>) {
      message = body['message']?.toString() ?? message;
      code = body['code'];
      if (body['errors'] is Map<String, dynamic>) {
        errors = body['errors'] as Map<String, dynamic>;
      }
    } else if (body is String && body.isNotEmpty) {
      message = body;
    }

    return ApiErrorModel(
      message: message,
      code: code,
      errors: errors,
      statusCode: statusCode,
      type: switch (statusCode) {
        401 => 'Unauthorized',
        403 => 'Forbidden',
        404 => 'NotFound',
        422 => 'ValidationError',
        final int s when s >= 500 => 'ServerError',
        _ => 'BadRequest',
      },
    );
  }

  static void _log(dynamic error) {
    if (error is DioException) {
      developer.log(
        'API error: ${error.requestOptions.method} '
        '${error.requestOptions.uri} → ${error.response?.statusCode}',
        name: 'ApiErrorHandler',
        error: error,
      );
    } else {
      developer.log('Unhandled error', name: 'ApiErrorHandler', error: error);
    }
  }
}
