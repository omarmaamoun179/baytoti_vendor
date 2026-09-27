/// Every route path in the app.
///
/// A screen pushed over a tab shell goes on the root navigator
/// (`parentNavigatorKey: rootNavigatorKey`) so it covers the tab bar.
class AppRoutes {
  AppRoutes._();

  // ── Entry ──────────────────────────────────────────────────────────
  static const String splash = '/splash';

  /// Sign-in and sign-up, one screen under a segmented control.
  static const String login = '/login';

  /// The code sent to the phone, pushed over [login].
  static const String otp = '/otp';

  // ── Tabs ───────────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';
  static const String orders = '/orders';
  static const String products = '/products';
  static const String offers = '/offers';
  static const String store = '/store';

  // ── Full screen ────────────────────────────────────────────────────
  /// Beneath [orders], so the guard's prefix match protects it; the id is
  /// the order's opaque id (`ord_2041`).
  static const String orderPattern = ':id';
  static String order(String id) => '$orders/$id';

  /// Making a product. Registered before [productPattern], which would
  /// otherwise read "new" as a product id.
  static const String newProduct = '$products/new';

  /// Editing one, in the same form.
  static const String productPattern = ':id';
  static String product(String id) => '$products/$id';

  static const String notifications = '/notifications';

  // ── Query keys ─────────────────────────────────────────────────────
  /// `/orders?tab=new` — the dashboard's "see all" and its new-orders
  /// figure open a filtered tab.
  static const String tabQuery = 'tab';
}

    