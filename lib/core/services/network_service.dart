import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:requests_inspector/requests_inspector.dart';

import '../exceptions/app_exceptions.dart';
import '../utils/constants.dart';
import '../utils/custom_printer.dart';
import 'network_service_util.dart';

export 'network_service_util.dart';

/// The app's HTTP surface.
///
/// Returns the raw [Response] with `validateStatus` always true, so a 4xx is
/// a normal return rather than a throw — data sources read `statusCode` and
/// decide. Only transport failures ([ConnectionException]), duplicate calls
/// ([RedundantRequestException]) and a refused session
/// ([SessionExpiredException]) come back as exceptions.
///
/// The API issues Sanctum tokens, which cannot be refreshed: a 401 on a call
/// sent with the stored token means the session is over. `skipAuthRefresh`
/// opts a call out — the public endpoints, where a 401 means wrong
/// credentials rather than a dead token.
abstract class NetworkService {
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  });

  Future<Response> post(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  });

  Future<Response> patch(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  });

  Future<Response> put(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  });

  Future<Response> delete(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  });

  Future<Response> downloadFile(
    String url,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<Uint8List> readBytes(String url);

  Future<Map<String, dynamic>> getDefaultHeaders([String? language]);

  /// Flattens nested maps/lists into `a.b` and `a[0]` query keys.
  Map<String, dynamic>? formatQueryIfNeeded(
    Map<String, dynamic>? queryParameters,
  );
}

class NetworkServiceImpl implements NetworkService {
  NetworkServiceImpl(this._util, {this.onSessionExpired});

  final NetworkServiceUtil _util;

  /// Called once when the server refuses the stored token, after the token is
  /// cleared. The app wires this to the auth feature, which forgets the rest
  /// of the session — core stays free of any dependency on a feature or on
  /// the router.
  final Future<void> Function()? onSessionExpired;

  /// Without timeouts a stalled request hangs its caller forever with no
  /// error to surface — the UI just sits on its spinner.
  final Dio _dio = Dio(
    BaseOptions(
      validateStatus: (_) => true,
      connectTimeout: connectTimeout,
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: receiveTimeout,
    ),
  )..interceptors.addAll([
      // Feeds the in-app request inspector — shake or long-press to open it.
      // Debug only: it retains every request body and response in memory, and
      // a release build has no way to show them anyway.
      if (kDebugMode) RequestsInspectorInterceptor(),
    ]);

  String? _requestName;

  final List<String> _pendingRequests = <String>[];

  // ── Public verbs ───────────────────────────────────────────────────

  @override
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _send(
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        skipAuthRefresh: skipAuthRefresh,
        call: (resolved) => _request(
          url,
          method: 'GET',
          queryParameters: resolved.queryParameters,
          headers: resolved.headers,
          skipAuthRefresh: skipAuthRefresh,
        ),
      );

  @override
  Future<Response> post(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _send(
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        data: data,
        skipAuthRefresh: skipAuthRefresh,
        call: (resolved) => _request(
          url,
          method: 'POST',
          data: data,
          queryParameters: resolved.queryParameters,
          headers: resolved.headers,
          skipAuthRefresh: skipAuthRefresh,
        ),
      );

  @override
  Future<Response> patch(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _send(
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        data: data,
        skipAuthRefresh: skipAuthRefresh,
        call: (resolved) => _request(
          url,
          method: 'PATCH',
          data: data,
          queryParameters: resolved.queryParameters,
          headers: resolved.headers,
          skipAuthRefresh: skipAuthRefresh,
        ),
      );

  @override
  Future<Response> put(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _send(
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        data: data,
        skipAuthRefresh: skipAuthRefresh,
        call: (resolved) => _request(
          url,
          method: 'PUT',
          data: data,
          queryParameters: resolved.queryParameters,
          headers: resolved.headers,
          skipAuthRefresh: skipAuthRefresh,
        ),
      );

  @override
  Future<Response> delete(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool skipAuthRefresh = false,
  }) =>
      _send(
        url: url,
        headers: headers,
        queryParameters: queryParameters,
        data: data,
        skipAuthRefresh: skipAuthRefresh,
        call: (resolved) => _request(
          url,
          method: 'DELETE',
          data: data,
          queryParameters: resolved.queryParameters,
          headers: resolved.headers,
          skipAuthRefresh: skipAuthRefresh,
        ),
      );

  // ── Shared pipeline ────────────────────────────────────────────────

  /// Resolves headers, guards against a duplicate in-flight call, and maps
  /// transport failures — the part every verb repeated before.
  Future<Response> _send({
    required String url,
    required Map<String, dynamic>? headers,
    required Map<String, dynamic>? queryParameters,
    required Future<Response> Function(_ResolvedRequest) call,
    Object? data,
    bool skipAuthRefresh = false,
  }) async {
    _requestName = _extractName(url);
    final resolvedHeaders = headers ?? await getDefaultHeaders();
    final requestId = _generateRequestId(
      url: url,
      queryParameters: queryParameters,
      headers: resolvedHeaders,
      data: data,
    );

    if (_pendingRequests.contains(requestId)) {
      throw RedundantRequestException('Request is already pending for $url');
    }
    _pendingRequests.add(requestId);

    return _connectionExceptionCatcher(
      () => call(
        _ResolvedRequest(
          headers: resolvedHeaders,
          queryParameters: formatQueryIfNeeded(queryParameters),
        ),
      ),
    ).whenComplete(() => _pendingRequests.remove(requestId));
  }

  /// One implementation for all five verbs, including ending a refused
  /// session.
  Future<Response> _request(
    String url, {
    required String method,
    required Map<String, dynamic> headers,
    Map<String, dynamic>? queryParameters,
    Object? data,
    bool skipAuthRefresh = false,
  }) async {
    final requestName = _requestName;
    _logRequest(requestName, url, queryParameters, headers, data);

    final response = await _dio.request(
      url,
      data: data,
      queryParameters: queryParameters,
      options: Options(method: method, headers: headers),
    );
    _logResponse(requestName, response);
    _requestName = null;

    // A call sent without a token had no session to lose; its 401 goes back
    // to the data source like any other refusal.
    final authorization = headers['Authorization'];
    if (!skipAuthRefresh &&
        response.statusCode == 401 &&
        authorization != null) {
      await _endSession(authorization);
      throw const SessionExpiredException();
    }

    return response;
  }

  @override
  Future<Uint8List> readBytes(String url) async {
    final response = await _connectionExceptionCatcher(
      () => _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      ),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  @override
  Future<Response> downloadFile(
    String url,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) =>
      _connectionExceptionCatcher(
        () => _dio.download(
          url,
          savePath,
          queryParameters: formatQueryIfNeeded(queryParameters),
          options: Options(headers: headers ?? {}),
        ),
      );

  @override
  Future<Map<String, dynamic>> getDefaultHeaders([String? language]) async {
    final accessToken = await _util.getCurrentAccessToken();
    final languageCode = await _util.getLanguageCode() ?? language ?? 'ar';

    return <String, String>{
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // The standard header beside the backend family's own, so the server
      // can answer in the app's language whichever it reads.
      'Accept-Language': languageCode,
      'x-app-version': await _util.getAppVersion(),
      'x-platform-type': _util.getPlatformType(),
      'x-custom-lang': languageCode,
    };
  }

  // ── Session ────────────────────────────────────────────────────────

  /// The end of a refused session while it is under way, so the calls refused
  /// at the same moment join it instead of each ending the session again.
  ///
  /// Assigned with `??=` and no await in front, so two 401s that interleave
  /// cannot both slip past the guard.
  Future<void>? _sessionEnding;

  Future<void> _endSession(Object authorization) =>
      _sessionEnding ??= _forgetRefusedToken(authorization)
          .whenComplete(() => _sessionEnding = null);

  /// A second session-ending path, separate from a deliberate logout: it is
  /// reached from inside a request, so it drops the token at once — the calls
  /// still out stop sending it — and hands the rest to [onSessionExpired].
  ///
  /// Only the session the call was sent under is ended. A stored token that
  /// has changed since belongs to a session that is already gone, or to a
  /// new sign-in this call has no say over.
  Future<void> _forgetRefusedToken(Object authorization) async {
    final token = await _util.getCurrentAccessToken();
    if (token == null || authorization != 'Bearer $token') return;

    await _util.clearCurrentUserData();
    await onSessionExpired?.call();
  }

  // ── Helpers ────────────────────────────────────────────────────────

  String _generateRequestId({
    Object? url,
    Object? queryParameters,
    Object? headers,
    Object? data,
  }) =>
      '${url ?? ''}${queryParameters ?? ''}${headers ?? ''}${data ?? ''}';

  String _extractName(String url) =>
      url.split('?').first.split('/').last.toUpperCase();

  void _logRequest(
    String? requestName,
    String url,
    Map<String, dynamic>? params,
    Map<String, dynamic> headers, [
    Object? data,
  ]) {
    if (requestName == null) return;
    CustomPrinter.logRequestPretty(
      title: requestName,
      url: url,
      params: params,
      header: headers,
    );
    CustomPrinter.logBody(requestName, data);
  }

  void _logResponse(String? requestName, Response<dynamic> response) {
    if (requestName == null) return;
    CustomPrinter.logJsonResponsePretty(
      title: requestName,
      response: response,
    );
  }

  /// Turns every transport failure into [ConnectionException].
  ///
  /// The exception TYPE is matched first: a stalled request surfaces as a
  /// timeout whose message reads "receive timeout", which the string checks
  /// below would miss — it would then fall through as a server error and skip
  /// any offline fallback.
  Future<T> _connectionExceptionCatcher<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (_connectionFailures.contains(e.type)) {
        throw const ConnectionException();
      }
      if (_looksOffline(e.toString())) throw const ConnectionException();
      rethrow;
    } catch (e) {
      if (_looksOffline(e.toString())) throw const ConnectionException();
      rethrow;
    }
  }

  static const Set<DioExceptionType> _connectionFailures = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  static bool _looksOffline(String message) => const [
        'SocketException',
        'HttpException',
        'time out',
        'HandshakeException',
        'Failed host lookup',
      ].any(message.contains);

  @override
  Map<String, dynamic>? formatQueryIfNeeded(
    Map<String, dynamic>? queryParameters,
  ) {
    if (queryParameters == null) return null;
    final formatted = <String, dynamic>{};

    for (final entry in queryParameters.entries) {
      if (entry.value is Map || entry.value is List) {
        formatted.addEntries(_flatten(entry.key, entry.value));
      } else {
        formatted[entry.key] = entry.value;
      }
    }
    return formatted;
  }

  /// `{filter: {min: 1}}` → `filter.min=1`; `{ids: [1,2]}` → `ids[0]=1`.
  List<MapEntry<String, dynamic>> _flatten(String key, Object? value) {
    if (value is! Map && value is! List) return [MapEntry(key, value)];

    final entries = <MapEntry<String, dynamic>>[];

    if (value is List) {
      for (var i = 0; i < value.length; i++) {
        entries.addAll(_flatten('$key[$i]', value[i]));
      }
    } else if (value is Map) {
      for (final entry in value.entries) {
        entries.addAll(_flatten('$key.${entry.key}', entry.value));
      }
    }
    return entries;
  }
}

/// Headers and query resolved once, before the call is made.
class _ResolvedRequest {
  final Map<String, dynamic> headers;
  final Map<String, dynamic>? queryParameters;

  const _ResolvedRequest({required this.headers, this.queryParameters});
}
