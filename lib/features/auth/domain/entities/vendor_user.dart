import 'package:equatable/equatable.dart';

/// The signed-in account — the `user` of `/auth/verify-otp` and `/auth/me`
/// (the API's `UserResource`).
class VendorUser extends Equatable {
  /// The API's integer id, as text; the app never parses it.
  final String id;

  /// The account's `name` — for a family, the family's name.
  final String fullName;

  /// As the API stores it: digits, no `+` (`96551502244`).
  final String phone;

  final String? email;
  final String? avatarUrl;

  /// `customer` or `vendor`, when the server says. One login serves both
  /// apps; `UserResource` does not carry it, so it defaults to vendor.
  final String role;

  const VendorUser({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.role = 'vendor',
  });

  @override
  List<Object?> get props => [id, fullName, phone, email, avatarUrl, role];
}
