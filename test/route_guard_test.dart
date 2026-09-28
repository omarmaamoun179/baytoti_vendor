import 'package:baytoti_vendor/core/di/di_exports.dart';
import 'package:baytoti_vendor/core/routing/app_router.dart';
import 'package:baytoti_vendor/core/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A notifier already past the startup check, signed in or out.
SessionNotifier _session({required bool authenticated}) {
  final notifier = SessionNotifier();
  authenticated ? notifier.signedIn() : notifier.signedOut();
  return notifier;
}

String? _redirect(String location, {required bool authenticated}) =>
    redirectForGuest(
      location: location,
      session: _session(authenticated: authenticated),
    );

/// Walks the router's registered tree and returns every full path, shell
/// branches and nested routes included, so nothing registered can escape
/// the classification check below.
List<String> _registeredPaths(List<RouteBase> routes, [String prefix = '']) {
  final paths = <String>[];

  for (final route in routes) {
    switch (route) {
      case GoRoute(:final path, routes: final children):
        final full = path.startsWith('/')
            ? path
            : '$prefix/$path'.replaceAll('//', '/');
        paths
          ..add(full)
          ..addAll(_registeredPaths(children, full));
      case StatefulShellRoute(:final branches):
        for (final branch in branches) {
          paths.addAll(_registeredPaths(branch.routes, prefix));
        }
      case ShellRouteBase(routes: final children):
        paths.addAll(_registeredPaths(children, prefix));
      default:
        fail('Unhandled RouteBase subtype: ${route.runtimeType}');
    }
  }
  return paths;
}

void main() {
  // Reading `appRouter` builds it, and its `refreshListenable` resolves a
  // SessionNotifier from the locator. Only the classification group touches
  // the router itself; the guard tests are pure.
  setUpAll(() {
    if (!sl.isRegistered<SessionNotifier>()) {
      sl.registerSingleton<SessionNotifier>(SessionNotifier());
    }
  });

  tearDownAll(() => sl.reset());

  group('protected routes', () {
    for (final path in protectedRoutes) {
      test('$path redirects a guest', () {
        expect(_redirect(path, authenticated: false), AppRoutes.login);
      });

      test('$path lets a signed-in family through', () {
        expect(_redirect(path, authenticated: true), isNull);
      });
    }

    test('a route beneath a protected one is protected', () {
      expect(
        _redirect(AppRoutes.order('ord_2041'), authenticated: false),
        AppRoutes.login,
      );
      expect(
        _redirect(AppRoutes.newProduct, authenticated: false),
        AppRoutes.login,
      );
    });
  });

  group('public routes', () {
    for (final path in publicRoutes) {
      test('$path is not redirected', () {
        expect(_redirect(path, authenticated: false), isNull);
      });
    }

    test('sign-in and the code screen send a signed-in family home', () {
      for (final path in guestOnlyRoutes) {
        expect(
          redirectForMember(
            location: path,
            session: _session(authenticated: true),
          ),
          AppRoutes.dashboard,
        );
      }
    });

    test('a family that has just signed up chooses its location first', () {
      final session = SessionNotifier()..signedIn(newAccount: true);
      for (final path in guestOnlyRoutes) {
        expect(
          redirectForMember(location: path, session: session),
          AppRoutes.locationSetup,
        );
      }
      expect(
        redirectForMember(location: AppRoutes.locationSetup, session: session),
        isNull,
      );
    });
  });

  group('classification is exhaustive', () {
    test('every registered route is either protected or explicitly public',
        () {
      final registered = _registeredPaths(appRouter.configuration.routes);
      expect(registered, isNotEmpty);

      final unclassified = registered
          .where((path) =>
              !isProtectedRoute(path) && !publicRoutes.contains(path))
          .toList();

      expect(
        unclassified,
        isEmpty,
        reason: 'Add these to protectedRoutes or publicRoutes in '
            'app_router.dart: $unclassified',
      );
    });

    test('no route is classified both ways', () {
      final both = publicRoutes.where(isProtectedRoute).toList();
      expect(both, isEmpty, reason: 'Listed as public but matches a '
          'protected prefix: $both');
    });

    test('no classification entry is stale', () {
      final registered = _registeredPaths(appRouter.configuration.routes);

      expect(
        publicRoutes.where((p) => !registered.contains(p)).toList(),
        isEmpty,
        reason: 'publicRoutes names a route that no longer exists',
      );
      expect(
        protectedRoutes
            .where((p) => !registered.any((r) => r == p || r.startsWith('$p/')))
            .toList(),
        isEmpty,
        reason: 'protectedRoutes names a route that no longer exists',
      );
    });
  });

  test('an unresolved session never redirects', () {
    for (final path in protectedRoutes) {
      expect(
        redirectForGuest(location: path, session: SessionNotifier()),
        isNull,
      );
    }
  });

  test('a query string never creates a match', () {
    expect(isProtectedRoute('${AppRoutes.login}?next=/orders'), isFalse);
    expect(isProtectedRoute('${AppRoutes.orders}?tab=new'), isTrue);
  });

  // go_router takes the first route that matches, and `:id` matches "new".
  test('a new product is not read as a product id', () {
    String? routeFor(String location) => appRouter.configuration
        .findMatch(Uri.parse(location))
        .last
        .route
        .name;

    expect(routeFor(AppRoutes.newProduct), 'newProduct');
    expect(routeFor(AppRoutes.product('prd_1')), 'product');
  });
}
