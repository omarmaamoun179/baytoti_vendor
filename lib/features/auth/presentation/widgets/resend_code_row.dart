import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/otp_challenge.dart';

/// "Didn't get it? Resend" — held back for the challenge's `resend_after`
/// with a countdown, and restarted by every fresh code.
class ResendCodeRow extends StatefulWidget {
  final OtpChallenge challenge;
  final bool busy;
  final VoidCallback onResend;

  const ResendCodeRow({
    super.key,
    required this.challenge,
    required this.busy,
    required this.onResend,
  });

  @override
  State<ResendCodeRow> createState() => _ResendCodeRowState();
}

class _ResendCodeRowState extends State<ResendCodeRow> {
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(ResendCodeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A resend answers with a fresh challenge object even for the same
    // request id, and each one starts the wait over.
    if (!identical(oldWidget.challenge, widget.challenge)) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _secondsLeft = widget.challenge.resendAfter.inSeconds;
    if (_secondsLeft <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final waiting = _secondsLeft > 0;
    final minutes = _secondsLeft ~/ 60;
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('otp_no_code'.tr(), style: AppStrings.text115w400Flat.c(p.fg3)),
        SizedBox(width: 6.w),
        InkWell(
          onTap: waiting || widget.busy ? null : widget.onResend,
          borderRadius: BorderRadius.circular(6.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 6.h),
            child: Text(
              waiting
                  ? 'otp_resend_in'.tr(args: ['$minutes:$seconds'])
                  : 'otp_resend'.tr(),
              style: AppStrings.text115w800.c(waiting ? p.fg3 : p.accent),
            ),
          ),
        ),
      ],
    );
  }
}
