import 'package:equatable/equatable.dart';

/// The signed-in account — the `user` of `/auth/verify-otp` and `/me`.
class VendorUser extends Equatable {
  /// Opaque (`usr_18`); the app never parses it.
  final String id;

  final String fullName;

  /// E.164, as the API stores it (`+96551502244`).
  final String phone;

  final String? avatarUrl;

  /// `customer` or `vendor`. One login serves both apps, so the vendor app
  /// reads it rather than assuming it.
  final String role;

  const VendorUser({
    required this.id,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
    this.role = 'vendor',
  });

  @override
  List<Object?> get props => [id, fullName, phone, avatarUrl, role];
}
