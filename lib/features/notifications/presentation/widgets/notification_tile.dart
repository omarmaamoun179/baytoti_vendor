import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/vendor_notification.dart';

/// A notification: a tag tile naming its kind (ORD, PRD, RTG…), the title
/// and body, and when. An unread one sits on amber with an amber tag — what
/// the design gives the new orders.
class NotificationTile extends StatelessWidget {
  final VendorNotification notification;

  /// Null when it opens nothing.
  final VoidCallback? onTap;

  const NotificationTile({super.key, required this.notification, this.onTap});

  static String _tagKey(NotificationType type) => switch (type) {
        NotificationType.newOrder ||
        NotificationType.orderStatus =>
          'notification_tag_order',
        NotificationType.productApproved => 'notification_tag_product',
        NotificationType.rating => 'notification_tag_rating',
        NotificationType.lowStock => 'notification_tag_stock',
        NotificationType.exhibitionInvite => 'notification_tag_exhibition',
        NotificationType.other => 'notification_tag_other',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hot = !notification.isRead;
    final time = notification.createdAt == null
        ? ''
        : relativeTimeLabel(context, notification.createdAt!);

    return AppCard(
      color: hot ? p.amberBg : p.surf,
      padding: EdgeInsets.all(13.r),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hot ? p.amber : p.surf2,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              _tagKey(notification.type).tr(),
              maxLines: 1,
              style: AppStrings.text105w800.c(hot ? p.onAccent : p.ink),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppStrings.text125w800.c(p.fg),
                ),
                SizedBox(height: 4.h),
                Text(
                  notification.body,
                  style: AppStrings.text115w400.c(p.fg2),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(time, style: AppStrings.text10w400.c(p.fg3)),
        ],
      ),
    );
  }
}
