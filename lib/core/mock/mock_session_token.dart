import 'dart:convert';

/// The token the fixtures hand out at sign-in.
///
/// A real token is how the server knows who is asking, and a few fixtures
/// need to know it too — a family that has just signed up is still under
/// review, one that signed in is approved. So the fixture token carries the
/// account itself, and those fixtures read it back from `TokenStore` the way
/// the server reads the `Authorization` header.
///
/// No live endpoint accepts it. A device that kept one when the app is
/// switched to the live API is refused on its first call, and the 401
/// handling ends the session.
class MockSessionToken {
  static const String _prefix = 'mock';

  /// True for an account created by this sign-in (the sign-up tab).
  final bool isNewFamily;

  /// The eight local digits, without the dial code.
  final String phoneDigits;

  /// The family name given at sign-up; null for a sign-in.
  final String? familyName;

  const MockSessionToken({
    required this.isNewFamily,
    required this.phoneDigits,
    this.familyName,
  });

  String encode() {
    final name = base64Url.encode(utf8.encode(familyName ?? ''));
    return '$_prefix.${isNewFamily ? 'new' : 'existing'}.$phoneDigits.$name';
  }

  /// The account behind [token], or null for anything the fixtures did not
  /// issue.
  static MockSessionToken? decode(String? token) {
    final parts = token?.split('.');
    if (parts == null || parts.length != 4 || parts.first != _prefix) {
      return null;
    }

    final name = utf8.decode(base64Url.decode(parts[3]));
    return MockSessionToken(
      isNewFamily: parts[1] == 'new',
      phoneDigits: parts[2],
      familyName: name.isEmpty ? null : name,
    );
  }
}
