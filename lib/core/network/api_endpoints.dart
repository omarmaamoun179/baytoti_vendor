import '../utils/constants.dart';

/// Every server path the vendor app calls, taken from the design's API
/// contract ("Baytouti API Spec" in the Claude Design project).
///
/// No server implements it yet — every feature runs on fixtures while
/// `useMockData` is true, and these paths are what a remote data source
/// will call when one is written. Check each against the real API then:
/// the contract is a design document, not a published spec.
///
/// Paths are relative to [baseUrl] — which already carries the version
/// prefix and a trailing slash — and built through [_url] so the join is
/// done once. Ids are opaque strings (`ord_2041`), per the contract.
class ApiEndPoint {
  ApiEndPoint._();

  static String _url(String path) => '$baseUrl$path';

  // ── Auth (public) ──────────────────────────────────────────────────
  /// `{phone, mode: login|signup, full_name?}` → `{request_id, expires_in,
  /// resend_after, digits}`.
  static String get requestOtp => _url('auth/request-otp');

  /// `{request_id, code}` → `{access_token, refresh_token, is_new_user,
  /// user}`.
  static String get verifyOtp => _url('auth/verify-otp');
  static String get resendOtp => _url('auth/resend-otp');
  static String get refreshToken => _url('auth/refresh');

  // ── Auth (authenticated) ───────────────────────────────────────────
  static String get logout => _url('auth/logout');
  static String get me => _url('me');

  // ── Onboarding ─────────────────────────────────────────────────────
  /// `POST` — the family's application: name, city, phone, documents.
  static String get vendorApplications => _url('vendor/applications');

  /// `GET` — where the application stands, step by step. Every other vendor
  /// endpoint answers `403 vendor_not_approved` until it is `approved`.
  static String get vendorApplication => _url('vendor/application');

  /// Multipart; answers `{upload_id, url, width, height}`. Photos and
  /// documents are attached by `upload_id`, never by URL.
  static String get uploads => _url('uploads');

  // ── Dashboard ──────────────────────────────────────────────────────
  static String get vendorDashboard => _url('vendor/dashboard');

  // ── Orders ─────────────────────────────────────────────────────────
  /// `?state=all|new|preparing|done`; the answer carries every tab's count.
  static String get vendorOrders => _url('vendor/orders');
  static String vendorOrder(String id) => _url('vendor/orders/$id');

  /// `{status}` — the order's `next_status`; the server owns the machine.
  static String vendorOrderStatus(String id) =>
      _url('vendor/orders/$id/status');

  /// `{reason, note}`.
  static String vendorOrderReject(String id) =>
      _url('vendor/orders/$id/reject');

  // ── Catalogue ──────────────────────────────────────────────────────
  static String get vendorProducts => _url('vendor/products');
  static String vendorProduct(String id) => _url('vendor/products/$id');

  /// `{published}` — `422 product_pending_review` before approval.
  static String vendorProductVisibility(String id) =>
      _url('vendor/products/$id/visibility');

  static String get vendorCategories => _url('vendor/categories');

  // ── Offers ─────────────────────────────────────────────────────────
  static String get vendorOffers => _url('vendor/offers');
  static String vendorOffer(String id) => _url('vendor/offers/$id');

  // ── Store ──────────────────────────────────────────────────────────
  static String get vendorStore => _url('vendor/store');

  // ── Notifications ──────────────────────────────────────────────────
  static String get vendorNotifications => _url('vendor/notifications');

  /// Named after the customer app's `POST /notifications/read`; the
  /// contract lists no vendor twin.
  static String get vendorNotificationsRead =>
      _url('vendor/notifications/read');

  // ── Push ───────────────────────────────────────────────────────────
  static String get devices => _url('devices');
  static String device(String token) => _url('devices/$token');
}
