import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension NavigationExtension on BuildContext {
  /// Pushes a new route onto the navigation stack
  Future<T?> push<T>(
    String routeName, {
    Map<String, String>? params,
    Map<String, String>? queryParams,
    Object? extra,
  }) {
    final fullRoute = _buildRoute(routeName, params, queryParams);
    return GoRouter.of(this).push<T>(fullRoute, extra: extra);
  }

  /// Replaces current route with a new one
  void pushReplacement(
    String routeName, {
    Map<String, String>? params,
    Map<String, String>? queryParams,
    Object? extra,
  }) {
    final fullRoute = _buildRoute(routeName, params, queryParams);
    GoRouter.of(this).replace(fullRoute, extra: extra);
  }

  /// Removes all previous routes and pushes new route
  void pushAndRemoveUntil(
    String routeName, {
    Map<String, String>? params,
    Map<String, String>? queryParams,
    Object? extra,
  }) {
    final fullRoute = _buildRoute(routeName, params, queryParams);
    GoRouter.of(this).go(fullRoute, extra: extra);
  }

  /// Pops current route with optional result
  void pop<T extends Object?>([T? result]) {
    GoRouter.of(this).pop(result);
  }

  /// Pops the current route and navigates to a new route
  void popAndNavigateTo(
    String routeName, {
    Map<String, String>? params,
    Map<String, String>? queryParams,
    Object? extra,
  }) {
    // First pop the current route
    GoRouter.of(this).pop();
    // Then navigate to the new route
    final fullRoute = _buildRoute(routeName, params, queryParams);
    GoRouter.of(this).go(fullRoute, extra: extra);
  }

  /// Navigate to nested route within a specific tab
  void pushNested(
    String parentRoute,
    String childRoute, {
    Map<String, String>? params,
    Map<String, String>? queryParams,
    Object? extra,
  }) {
    final nestedRoute = '$parentRoute$childRoute';
    final fullRoute = _buildRoute(nestedRoute, params, queryParams);
    GoRouter.of(this).push(fullRoute, extra: extra);
  }

  /// Replace current route with a nested route within a specific tab
  void pushReplacementNested(
    String parentRoute,
    String childRoute, {
    Map<String, String>? params,
    Map<String, String>? queryParams,
    Object? extra,
  }) {
    final nestedRoute = '$parentRoute$childRoute';
    final fullRoute = _buildRoute(nestedRoute, params, queryParams);
    GoRouter.of(this).replace(fullRoute, extra: extra);
  }

  /// Switch to a specific tab
  void switchTab(String tabRoute) {
    GoRouter.of(this).go(tabRoute);
  }

  /// Open a modal route
  void pushModal(
    String routeName, {
    Map<String, String>? params,
    Map<String, String>? queryParams,
    Object? extra,
  }) {
    final fullRoute = _buildRoute(routeName, params, queryParams);
    GoRouter.of(this).push(fullRoute, extra: extra);
  }

  /// Builds full route path with parameters
  String _buildRoute(
    String routeName,
    Map<String, String>? params,
    Map<String, String>? queryParams,
  ) {
    String fullRoute = routeName;

    // Add path parameters if provided and not empty
    if (params != null && params.isNotEmpty) {
      final pathSegments = params.values
          .where((param) => param.isNotEmpty)
          .map(Uri.encodeComponent)
          .join('/');
      if (pathSegments.isNotEmpty) {
        fullRoute = '$fullRoute/$pathSegments';
      }
    }

    // Add query parameters if provided and not empty
    if (queryParams != null && queryParams.isNotEmpty) {
      final uri = Uri(queryParameters: queryParams);
      fullRoute = '$fullRoute?${uri.query}';
    }

    return fullRoute;
  }
}
