import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/screen_header.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_form.dart';
import '../widgets/auth_hero.dart';

/// `/login` — sign in, or sign a new family up, with a code sent to the
/// phone. Not in the vendor design: built from the customer design's sign-in
/// screen, which the two apps share.
///
/// A code that goes out moves the vendor on to [AppRoutes.otp]; the router
/// takes them in once it is confirmed. A refusal's field messages are drawn
/// under the fields by [AuthForm]; only the rest is a toast.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  /// Only the page on top reacts: the code screen, pushed over this one,
  /// handles its own resends and wrong codes.
  bool _isOnTop(BuildContext context) =>
      ModalRoute.of(context)?.isCurrent ?? true;

  /// What no field shows: the refusal itself when it names no field, or
  /// the messages for fields the form does not draw.
  String? _toastFor(AuthState state) {
    if (state.fieldErrors.isEmpty) return state.errorMessage;
    final rest = [
      for (final MapEntry(:key, :value) in state.fieldErrors.entries)
        if (!AuthForm.showsField(key) && value.trim().isNotEmpty) value,
    ];
    return rest.isEmpty ? null : rest.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (!_isOnTop(context)) return;

        if (state.status == AuthStatus.codeSent) {
          context.push(AppRoutes.otp);
        } else if (state.status == AuthStatus.error) {
          final message = _toastFor(state);
          if (message != null) showAppToast(context, message, isError: true);
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            ScreenHeader(
              kicker: 'kicker_auth'.tr(),
              title: 'title_auth'.tr(),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    const AuthHero(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 28.h),
                      child: BlocBuilder<AuthCubit, AuthState>(
                        buildWhen: (previous, current) =>
                            previous.isLoading != current.isLoading ||
                            previous.fieldErrors != current.fieldErrors,
                        builder: (context, state) => AuthForm(
                          loading: state.isLoading,
                          fieldErrors: state.fieldErrors,
                          onSubmit: context.read<AuthCubit>().requestOtp,
                          onModeChanged: context.read<AuthCubit>().reset,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
