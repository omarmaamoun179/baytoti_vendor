import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/offers/presentation/pages/offers_page.dart';
import '../../features/orders/domain/entities/order_status.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/products/presentation/pages/product_editor_page.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/shell/presentation/pages/vendor_shell.dart';
import '../../features/store/presentation/pages/store_page.dart';
import '../common/go_router_observer.dart';
import '../di/di_exports.dart';
import 'routes.dart';

/// Root navigator key — routes registered against it cover the tab bar.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Routes a signed-out visitor may not reach.
///
/// Every vendor endpoint needs a bearer token, so everything past sign-in is
/// here. Matched on a segment boundary, so `/orders` also covers
/// `/orders/ord_2041`.
const Set<String> protectedRoutes = {
  AppRoutes.dashboard,
  AppRoutes.orders,
  AppRoutes.products,
  AppRoutes.offers,
  AppRoutes.store,
  AppRoutes.notifications,
};

/// Routes open to everyone.
///
/// Declared rather than inferred. The guard fails open — anything it does
/// not recognise is public — so an unclassified route is silently reachable.
/// Pairing this with [protectedRoutes] lets the test suite assert the two
/// together cover every registered route exactly, which turns a forgotten
/// classification into a failing test instead of a hole.
const Set<String> publicRoutes = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.otp,
};

/// Public routes a signed-in vendor has no business on, sent to the
/// dashboard instead.
const Set<String> guestOnlyRoutes = {AppRoutes.login, AppRoutes.otp};

/// True when [location] is one of [protectedRoutes] or sits beneath one.
///
/// Matched on a segment boundary, not a bare `startsWith`, so `/orders/12`
/// is protected while a future `/ordersomething` would not be caught by
/// accident.
bool isProtectedRoute(String location) {
  // `matchedLocation` never carries a query, but this is also reachable with
  // a raw URI, and `/orders?tab=new` matching nothing would be a hole.
  final path = Uri.parse(location).path;

  return protectedRoutes.any(
    (route) => path == route || path.startsWith('$route/'),
  );
}

/// Sends a signed-out visitor away from a protected route.
///
/// Split from [_guard] on [location] rather than a [GoRouterState], which
/// cannot be constructed outside the router — this is the half the tests
/// exercise. Null means "no redirect".
String? redirectForGuest({
  required String location,
  required SessionNotifier session,
}) {
  // Nothing is decided until the stored session has been read. `bootstrap`
  // awaits `AuthCubit.restoreSession()`, which resolves the notifier on every
  // branch, before `runApp`; this is kept so that moving the restore off the
  // startup path cannot silently sign everyone out for one navigation.
  if (!session.isResolved) return null;

  if (session.isAuthenticated) return null;
  if (!isProtectedRoute(location)) return null;

  return AppRoutes.login;
}

/// Sends a signed-in vendor away from sign-in and the code screen.
///
/// This is how a confirmed code leaves the form: the session flips, the
/// router re-runs its guard through `refreshListenable`, and this answers.
String? redirectForMember({
  required String location,
  required SessionNotifier session,
}) {
  if (!session.isResolved || !session.isAuthenticated) return null;
  return guestOnlyRoutes.contains(Uri.parse(location).path)
      ? AppRoutes.dashboard
      : null;
}

String? _guard(BuildContext context, GoRouterState state) {
  final session = sl<SessionNotifier>();
  return redirectForGuest(location: state.matchedLocation, session: session) ??
      redirectForMember(location: state.matchedLocation, session: session);
}

String _idOf(GoRouterState state) => state.pathParameters['id'] ?? '';

/// A screen pushed over the tab bar.
GoRoute _fullScreen(
  String path,
  String name,
  Widget Function(GoRouterState state) build,
) =>
    GoRoute(
      path: path,
      name: name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => build(state),
    );

/// The app's single [GoRouter].
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  observers: [CustomNavigatorObserver(navigatorName: 'root')],
  // Re-runs [_guard] the moment a session starts or ends, rather than on the
  // next navigation.
  refreshListenable: sl<SessionNotifier>(),
  redirect: _guard,
  routes: [
    // ── Entry ────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      name: 'otp',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const OtpPage(),
    ),

    // ── Tabs ─────────────────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      // No approval gate: a signed-in family goes straight to the dashboard
      // whatever its review says, and the server stays the authority on
      // every vendor call.
      builder: (context, state, navigationShell) =>
          VendorShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              name: 'dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.orders,
              name: 'orders',
              builder: (context, state) => OrdersPage(
                initialTab: OrderTab.fromQuery(
                  state.uri.queryParameters[AppRoutes.tabQuery],
                ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.products,
              name: 'products',
              builder: (context, state) => const ProductsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.offers,
              name: 'offers',
              builder: (context, state) => const OffersPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.store,
              name: 'store',
              builder: (context, state) => const StorePage(),
            ),
          ],
        ),
      ],
    ),

    // ── Full screen ──────────────────────────────────────────────────
    // Top-level rather than nested under their tab: a nested route would
    // switch the shell to that tab underneath, so opening an order from the
    // dashboard would come back to the orders tab.
    _fullScreen(
      '${AppRoutes.orders}/${AppRoutes.orderPattern}',
      'order',
      (state) => OrderDetailsPage(orderId: _idOf(state)),
    ),
    // First: go_router takes the first route that matches, and `:id` would
    // match "new".
    _fullScreen(
      AppRoutes.newProduct,
      'newProduct',
      (state) => const ProductEditorPage(),
    ),
    _fullScreen(
      '${AppRoutes.products}/${AppRoutes.productPattern}',
      'product',
      (state) => ProductEditorPage(productId: _idOf(state)),
    ),
    _fullScreen(
      AppRoutes.notifications,
      'notifications',
      (state) => const NotificationsPage(),
    ),
  ],
);
