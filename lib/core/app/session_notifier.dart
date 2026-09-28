import 'package:flutter/foundation.dart';

/// The one piece of auth state the router is allowed to know about.
///
/// `GoRouter.redirect` runs on every navigation and must answer "is there a
/// session?" synchronously — but core cannot import `features/auth` to ask
/// its cubit. So the auth feature pushes the answer down here, and the router
/// reads it. It also serves as the router's `refreshListenable`, so a login
/// or logout re-evaluates the guard immediately instead of on next navigation.
///
/// The auth feature owns the writes:
/// ```dart
/// // after a successful login / on app start with a stored token
/// sl<SessionNotifier>().signedIn();
/// // after the code that finishes a sign-up
/// sl<SessionNotifier>().signedIn(newAccount: true);
/// // on logout or an unrecoverable 401
/// sl<SessionNotifier>().signedOut();
/// ```
class SessionNotifier extends ChangeNotifier {
  bool _isAuthenticated = false;

  /// False until the stored session has been checked — the splash screen
  /// holds navigation until [markResolved] flips it.
  bool _isResolved = false;

  bool _isNewAccount = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isResolved => _isResolved;

  /// True when the session was opened by the code that finishes a sign-up,
  /// not by a sign-in or a restored token. The router sends a family that
  /// has just signed up to choose its location before the dashboard.
  bool get isNewAccount => _isNewAccount;

  void signedIn({bool newAccount = false}) =>
      _set(authenticated: true, resolved: true, newAccount: newAccount);

  void signedOut() => _set(authenticated: false, resolved: true);

  /// Marks the startup session check as finished without changing the
  /// authenticated flag (e.g. no stored token was found).
  void markResolved() => _set(
        authenticated: _isAuthenticated,
        resolved: true,
        newAccount: _isNewAccount,
      );

  void _set({
    required bool authenticated,
    required bool resolved,
    bool newAccount = false,
  }) {
    if (_isAuthenticated == authenticated &&
        _isResolved == resolved &&
        _isNewAccount == newAccount) {
      return;
    }
    _isAuthenticated = authenticated;
    _isResolved = resolved;
    _isNewAccount = newAccount;
    notifyListeners();
  }
}
