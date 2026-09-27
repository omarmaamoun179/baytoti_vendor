import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/brand_mark.dart';

/// The brand while the app settles, then on to the dashboard or sign-in.
///
/// Not in the vendor design, which starts at onboarding; drawn from the
/// sign-in screen's mark and the design canvas's "Vendor" badge. The session
/// was resolved in `bootstrap` before the first frame, so this only holds
/// for the fade. A tap skips it.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const Duration _hold = Duration(milliseconds: 1300);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  Timer? _timer;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_hold, _leave);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    _timer?.cancel();

    final signedIn = sl<SessionNotifier>().isAuthenticated;
    context.go(signedIn ? AppRoutes.dashboard : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    return Scaffold(
      backgroundColor: p.accent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _leave,
        child: Center(
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: .92, end: 1).animate(fade),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrandMark(size: 92.r),
                  SizedBox(height: 18.h),
                  Text(
                    'brand_wordmark'.tr(),
                    style: AppStrings.text30w800.c(p.onAccent).tracked(-.02),
                  ),
                  SizedBox(height: 12.h),
                  _buildBadge(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The design canvas's "VENDOR" badge, inverted onto the accent.
  Widget _buildBadge(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: p.onAccent,
        borderRadius: BorderRadius.circular(7.r),
      ),
      child: Text(
        'VENDOR',
        style: AppStrings.text12w800.c(p.accent).tracked(.16),
      ),
    );
  }
}
