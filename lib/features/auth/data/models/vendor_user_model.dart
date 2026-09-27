import '../../../../core/utils/json_read.dart';
import '../../domain/entities/vendor_user.dart';

/// The contract's `user`:
///
/// ```json
/// {"id": "usr_18", "full_name": "نورة العنزي", "phone": "+96551502244",
///  "avatar": null, "role": "customer"}
/// ```
///
/// Also how the account is kept on the device, through [toJson].
class VendorUserModel extends VendorUser {
  const VendorUserModel({
    required super.id,
    required super.fullName,
    required super.phone,
    super.avatarUrl,
    super.role,
  });

  factory VendorUserModel.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'];

    return VendorUserModel(
      id: requireString(json['id'], 'id'),
      fullName: asString(json['full_name']) ?? '',
      phone: asString(json['phone']) ?? '',
      // An image object (`{url, …}`) or a bare URL.
      avatarUrl: avatar is Map ? asString(avatar['url']) : asString(avatar),
      role: asString(json['role']) ?? 'vendor',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'avatar': avatarUrl,
        'role': role,
      };
}
