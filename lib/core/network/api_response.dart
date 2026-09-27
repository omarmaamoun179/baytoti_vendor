import 'package:dio/dio.dart';

import '../domain/failure_mapper.dart';
import '../exceptions/app_exceptions.dart';

/// The `{success, message, data, errors}` envelope every Betouti endpoint
/// returns, plus the `links`/`meta` a paginated one adds alongside them.
///
/// Parsed in one place so no data source re-derives it: the API's own guide is
/// explicit that `success` must be checked rather than inferred from the
/// status code, and that field errors live in `errors`, not in `message`.
///
/// Not every response carries every key — `/countries` answers without
/// `links`/`meta` while `/notifications` includes both — and a dead token is
/// refused with a bare `401 {"message": "Unauthenticated."}`, so everything
/// beyond [statusCode] is optional.
class ApiResponse {
  final int statusCode;
  final bool success;
  final String message;

  /// The business payload. A `Map` for a single resource, a `List` for a
  /// collection, `null` on failure.
  final dynamic data;

  /// Validation details from a 422, keyed by field. Values arrive as a list
  /// of messages per field; [fieldErrors] flattens them for form binding.
  final Map<String, dynamic>? errors;

  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? links;

  const ApiResponse({
    required this.statusCode,
    required this.success,
    this.message = '',
    this.data,
    this.errors,
    this.meta,
    this.links,
  });

  factory ApiResponse.from(Response<dynamic> response) {
    final body = response.data;
    final status = response.statusCode ?? 0;

    // A non-JSON body (an HTML error page, an empty 204) still has to become
    // an ApiResponse rather than blowing up the cast.
    if (body is! Map) {
      return ApiResponse(
        statusCode: status,
        success: status >= 200 && status < 300,
        data: body,
      );
    }

    return ApiResponse(
      statusCode: status,
      // Absent `success` is read from the status code: a few endpoints answer
      // with a bare payload, and treating that as a failure would be wrong.
      success: body['success'] as bool? ?? (status >= 200 && status < 300),
      message: body['message'] as String? ?? '',
      data: body['data'],
      errors: _asMap(body['errors']),
      meta: _asMap(body['meta']),
      links: _asMap(body['links']),
    );
  }

  bool get isOk => statusCode >= 200 && statusCode < 300 && success;

  /// First message per field: `{"email": ["taken", "..."]}` → `{"email": "taken"}`.
  ///
  /// Shares [flattenFieldErrors] with the failure mapper — the same envelope
  /// is flattened on both paths, and two copies of the rule drifted apart is
  /// a bug waiting to happen.
  Map<String, String> get fieldErrors => flattenFieldErrors(errors);

  /// The payload as a map, or an empty one — never a cast error.
  Map<String, dynamic> get dataMap =>
      data is Map ? Map<String, dynamic>.from(data as Map) : const {};

  /// The payload as a list. Falls back to the envelope itself for the
  /// endpoints that answer with a bare array.
  List<dynamic> get dataList => switch (data) {
        final List<dynamic> list => list,
        _ => const [],
      };

  /// Throws unless the call succeeded, carrying the message, the backend code
  /// and the validation details a form needs.
  ///
  /// A 5xx never carries the server's own words: with debugging left on,
  /// Laravel answers an exception with its class, file and trace in
  /// `message`, and the guide is explicit that raw server exceptions are not
  /// for the user — so the generic line goes up instead.
  void ensureOk() {
    if (isOk) return;

    throw RequestException(
      statusCode >= 500
          ? 'server_error'
          : message.isNotEmpty
              ? message
              : 'request_failed',
      statusCode: statusCode,
      errors: errors,
    );
  }

  // ── Pagination ─────────────────────────────────────────────────────

  int get currentPage => meta?['current_page'] as int? ?? 1;
  int get lastPage => meta?['last_page'] as int? ?? 1;
  int get total => meta?['total'] as int? ?? dataList.length;

  /// Rows per page the server applied, which is not always the number asked
  /// for — `/products` caps it at 100 whatever `per_page` says.
  int get perPage => meta?['per_page'] as int? ?? dataList.length;

  /// True while another page exists. Reads `links.next` first — the guide
  /// names it as the authority — and falls back to the page counters.
  bool get hasMore => links?['next'] != null || currentPage < lastPage;

  static Map<String, dynamic>? _asMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;
}

/// Parses a Dio response into an [ApiResponse] and throws on failure.
///
/// The shape every data source method opens with, so the status check cannot
/// be forgotten in one of them.
ApiResponse checkedResponse(Response<dynamic> response) =>
    ApiResponse.from(response)..ensureOk();
