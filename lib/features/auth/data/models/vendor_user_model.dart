import '../../../../core/utils/json_read.dart';
import '../../domain/entities/vendor_user.dart';

/// The OpenAPI `UserResource`:
///
/// ```json
/// {"id": 23, "name": "أسرة أم عبدالله", "email": "family@example.com",
///  "phone": "96551502244", "avatar": null, "status": 1,
///  "created_at": "2026-09-16T23:06:03.000000Z"}
/// ```
///
/// The fixtures send `full_name` and a `role`; both spellings are read.
/// Also how the account is kept on the device, through [toJson].
class VendorUserModel extends VendorUser {
  const VendorUserModel({
    required super.id,
    required super.fullName,
    required super.phone,
    super.email,
    super.avatarUrl,
    super.role,
  });

  factory VendorUserModel.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'];

    return VendorUserModel(
      id: requireString(json['id'], 'id'),
      fullName: asString(json['full_name']) ?? asString(json['name']) ?? '',
      phone: asString(json['phone']) ?? '',
      email: asString(json['email']),
      // An image object (`{url, …}`) or a bare URL.
      avatarUrl: avatar is Map ? asString(avatar['url']) : asString(avatar),
      role: asString(json['role']) ?? 'vendor',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'avatar': avatarUrl,
        'role': role,
      };
}
