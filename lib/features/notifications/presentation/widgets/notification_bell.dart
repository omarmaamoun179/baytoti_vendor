import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/header_icon_button.dart';
import '../cubit/notification_badge_cubit.dart';

/// The header's bell, with the amber dot while anything is unread. Opens
/// the notifications over the tab bar.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.select(
      (NotificationBadgeCubit cubit) => cubit.state.count,
    );

    return HeaderIconButton(
      icon: AppIcons.bell,
      iconSize: 16.r,
      dot: unread > 0,
      semanticLabel: 'title_notifications'.tr(),
      onPressed: () => context.push(AppRoutes.notifications),
    );
  }
}
