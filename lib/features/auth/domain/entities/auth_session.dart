import 'package:equatable/equatable.dart';

import 'vendor_user.dart';

/// What a confirmed code opens: the account, and whether it was created by
/// this very code (a family that just signed up, whose application is still
/// to be reviewed).
class AuthSession extends Equatable {
  final VendorUser user;
  final bool isNewUser;

  const AuthSession({required this.user, required this.isNewUser});

  @override
  List<Object?> get props => [user, isNewUser];
}
