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

/// Root of the backend, version prefix and trailing slash included.
///
/// The default is the base URL the design's API contract names ("Baytouti
/// API Spec"); no server answers there yet, and the app runs on fixtures
/// until one does (`useMockData`).
///
/// The trailing slash is part of the contract with [ApiEndPoint], which
/// appends unprefixed segments — dropping it collapses `/v1/vendor/orders`
/// into `/v1vendor/orders`.
///
/// Override per build without editing this file:
///   flutter run --dart-define=BASE_URL=https://staging.example.com/api/v1/
const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'https://api.baytouti.com/v1/',
);

/// Network timeouts shared by every Dio request.
const Duration connectTimeout = Duration(seconds: 60);
const Duration receiveTimeout = Duration(seconds: 60);

/// Page size used by paginated list endpoints.
const int defaultPageSize = 20;

/// Support contact, for when the app grows a help screen.
const String supportPhoneNumber = '';
const String supportEmail = '';
