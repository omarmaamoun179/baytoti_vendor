import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../domain/entities/auth_params.dart';
import '../../domain/entities/otp_challenge.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/otp_code_boxes.dart';
import '../widgets/otp_keypad.dart';
import '../widgets/resend_code_row.dart';

/// `/otp` — the code sent to the phone, typed on the design's own keypad.
/// A confirmed code opens the session and the router takes the vendor in;
/// a wrong one clears the boxes and says so.
class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  String _code = '';

  void _type(String digit, int length) {
    if (_code.length >= length) return;
    setState(() => _code += digit);
  }

  void _delete() {
    if (_code.isEmpty) return;
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  void _onState(BuildContext context, AuthState state) {
    if (state.status == AuthStatus.error) {
      setState(() => _code = '');
      final message = state.displayError;
      if (message != null) showAppToast(context, message, isError: true);
    } else if (state.status == AuthStatus.codeSent) {
      showAppToast(context, 'otp_resent'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          // The code that brought the vendor here is not news.
          previous.status != AuthStatus.initial &&
          (ModalRoute.of(context)?.isCurrent ?? true),
      listener: _onState,
      builder: (context, state) {
        final challenge = state.challenge;

        return Scaffold(
          body: Column(
            children: [
              ScreenHeader(
                kicker: 'kicker_otp'.tr(),
                title: 'title_otp'.tr(),
                showBack: true,
              ),
              Expanded(
                child: challenge == null
                    ? EmptyState(message: 'otp_no_request'.tr())
                    : _buildBody(context, state, challenge),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AuthState state,
    OtpChallenge challenge,
  ) {
    final p = context.palette;
    final cubit = context.read<AuthCubit>();
    final complete = _code.length == challenge.digits;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(18.w, 26.h, 18.w, 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'otp_heading'.tr(),
            style: AppStrings.text24w800.c(p.fg).tracked(-.02),
          ),
          SizedBox(height: 8.h),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '${'otp_sent_to'.tr()} '),
              TextSpan(
                // Isolated so the number keeps its order inside Arabic.
                text: '\u2066${KuwaitPhone.display(challenge.phone)}\u2069',
                style: AppStrings.text125w400Loose
                    .c(p.fg)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ]),
            style: AppStrings.text125w400Loose.c(p.fg2),
          ),
          SizedBox(height: 20.h),
          CapsLabel('otp_code_label'.tr()),
          SizedBox(height: 9.h),
          OtpCodeBoxes(code: _code, length: challenge.digits),
          if (challenge.demoCode != null) ...[
            SizedBox(height: 10.h),
            Text(
              'otp_demo_hint'.tr(args: [challenge.demoCode!]),
              style: AppStrings.text11w400Loose.c(p.amberInk),
            ),
          ],
          SizedBox(height: 20.h),
          OtpKeypad(
            onDigit: (digit) => _type(digit, challenge.digits),
            onDelete: _delete,
          ),
          SizedBox(height: 20.h),
          PrimaryButton(
            label: 'otp_verify'.tr(),
            height: 52.h,
            labelStyle: AppStrings.text14w800,
            enabled: complete,
            loading: state.isLoading && complete,
            onPressed: () => cubit.verifyOtp(_code),
          ),
          SizedBox(height: 20.h),
          ResendCodeRow(
            challenge: challenge,
            busy: state.isLoading,
            onResend: () {
              setState(() => _code = '');
              cubit.resendOtp();
            },
          ),
        ],
      ),
    );
  }
}
