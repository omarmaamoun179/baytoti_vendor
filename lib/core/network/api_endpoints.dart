import '../utils/constants.dart';

/// Every server path the vendor app calls, mirroring the Betouti OpenAPI spec
/// at `https://betouti.alqudiry-solutions.com/docs/api.json` (the
/// authoritative reference, per the backend's Mobile API Integration Guide).
///
/// Paths are relative to [baseUrl] — which already carries the `/api/v1`
/// prefix and a trailing slash — and built through [_url] so the join is
/// done once. Path parameters are typed `String` because they are URL
/// segments; the API's ids are integers rendered as text.
///
/// The backend calls the family a *vendor* and its shop a *store*: one
/// account owns its stores, and products live under a store.
class ApiEndPoint {
  ApiEndPoint._();

  static String _url(String path) => '$baseUrl$path';

  // ── Auth (public) ──────────────────────────────────────────────────
  /// `{phone}` — digits only (`^[0-9]{8,15}$`). Answers `data: null`; while
  /// SMS is stubbed the code rides at the end of `message`
  /// (`"OTP sent successfully. demo otp :561228"`).
  static String get requestOtp => _url('auth/request-otp');

  /// `{phone, otp}` → the session. A wrong code is `422` on `otp`.
  static String get verifyOtp => _url('auth/verify-otp');

  /// The whole `VendorRegisterRequest`: account, business and first store.
  /// Answers with no token — the code issues it.
  static String get vendorRegister => _url('auth/vendor/register');

  // ── Auth (authenticated) ───────────────────────────────────────────
  static String get me => _url('auth/me');
  static String get logout => _url('auth/logout');

  // ── Vendor profile ─────────────────────────────────────────────────
  /// `VendorProfileResource`: `{id, account, business, status}`. Its
  /// `status` is where the platform's review of the family stands.
  static String get vendorProfile => _url('vendor/profile');

  // ── Dashboard ──────────────────────────────────────────────────────
  static String get vendorHome => _url('vendor/home');

  // ── Stores ─────────────────────────────────────────────────────────
  static String get vendorStores => _url('vendor/stores');

  /// Updated with `PUT`, not `PATCH`.
  static String vendorStore(String store) => _url('vendor/stores/$store');

  static String vendorStoreStatus(String store) =>
      _url('vendor/stores/$store/status');

  // ── Products (scoped to a store) ───────────────────────────────────
  static String vendorStoreProducts(String store) =>
      _url('vendor/stores/$store/products');

  /// Updated with `PUT` — or a `POST` carrying `_method=PUT` when the body
  /// is multipart, since PHP parses multipart only on `POST`.
  static String vendorStoreProduct(String store, String product) =>
      _url('vendor/stores/$store/products/$product');

  /// Moves a draft or rejected product to `pending_review`.
  static String submitProductReview(String store, String product) =>
      _url('vendor/stores/$store/products/$product/submit-review');

  static String restoreProduct(String store, String product) =>
      _url('vendor/stores/$store/products/$product/restore');

  // ── Catalogue (public) ─────────────────────────────────────────────
  /// Root categories with their `children`.
  static String get activeCategories => _url('categories/active');

  // ── Orders ─────────────────────────────────────────────────────────
  /// `OrderResource` rows, paged by `meta`. The spec documents no filter.
  static String get vendorOrders => _url('vendor/orders');
  static String vendorOrder(String order) => _url('vendor/orders/$order');

  /// `{status}` — one of `pending · confirmed · processing · shipped ·
  /// delivered · cancelled`.
  static String vendorOrderStatus(String order) =>
      _url('vendor/orders/$order/status');

  // ── Location (public) ──────────────────────────────────────────────
  static String get countries => _url('countries');
  static String governorates(String country) =>
      _url('countries/$country/governorates');

  // ── Notifications ──────────────────────────────────────────────────
  /// `NotificationResource` rows, paged by `meta`. Shared by both apps: the
  /// signed-in account's own.
  static String get notifications => _url('notifications');
  static String get markNotificationsRead => _url('notifications/read-all');
  static String get unreadNotificationCount =>
      _url('notifications/unread-count');
}
