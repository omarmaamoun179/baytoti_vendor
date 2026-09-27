/// App-wide configuration constants.
library;

import 'package:flutter/foundation.dart';

/// Wraps the app in `device_preview`'s simulator, for checking layouts against
/// other screen sizes. Debug builds only — it can never reach a release.
///
/// Turn it off for a run without editing this file:
///   flutter run --dart-define=DEVICE_PREVIEW=false
const bool useDevicePreview =
    kDebugMode && bool.fromEnvironment('DEVICE_PREVIEW', defaultValue: true);

/// Root of the backend, `/api/v1` prefix and trailing slash included — the
/// Betouti Laravel API (OpenAPI at `/docs/api.json` on the same host).
///
/// The version prefix, not `auth/`, ends the base: auth is one route group
/// beside `vendor/*`, `notifications` and the rest, and [ApiEndPoint] names
/// each from here.
///
/// The trailing slash is part of the contract with [ApiEndPoint], which
/// appends unprefixed segments — dropping it collapses `/v1/vendor/orders`
/// into `/v1vendor/orders`.
///
/// Override per build without editing this file:
///   flutter run --dart-define=BASE_URL=https://staging.example.com/api/v1/
const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'https://betouti.alqudiry-solutions.com/api/v1/',
);

/// Network timeouts shared by every Dio request.
const Duration connectTimeout = Duration(seconds: 60);
const Duration receiveTimeout = Duration(seconds: 60);

/// Page size used by paginated list endpoints.
const int defaultPageSize = 20;

/// Support contact, for when the app grows a help screen.
const String supportPhoneNumber = '';
const String supportEmail = '';
