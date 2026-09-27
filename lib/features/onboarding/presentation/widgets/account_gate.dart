import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/load_state_views.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/application_cubit.dart';
import '../cubit/application_state.dart';
import '../pages/application_status_page.dart';

/// Shows [child] only to an approved family.
///
/// Wrapped around the tab shell and every screen pushed over it, so an
/// application still under review reaches no store screen by any route — a
/// deep link included — and sees [ApplicationStatusPage] instead. Hiding a
/// screen is not protection, though: the server refuses every vendor call
/// with `403 vendor_not_approved` until approval.
class AccountGate extends StatelessWidget {
  final Widget child;

  const AccountGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApplicationCubit, ApplicationState>(
      // Only the gate that is on screen says so — every pushed route has one.
      listenWhen: (previous, current) =>
          previous.application != null &&
          !previous.isApproved &&
          current.isApproved &&
          (ModalRoute.of(context)?.isCurrent ?? true),
      listener: (context, _) =>
          showAppToast(context, 'application_approved_toast'.tr()),
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.application != current.application,
      builder: (context, state) {
        if (state.isApproved) return child;

        final application = state.application;
        if (application != null) {
          return ApplicationStatusPage(application: application);
        }

        return Scaffold(
          body: switch (state.status) {
            ApplicationStatus.error => SafeArea(
                child: LoadErrorView(
                  message: state.errorMessage ?? 'application_failed'.tr(),
                  onRetry: context.read<ApplicationCubit>().load,
                  secondaryLabel: 'sign_out'.tr(),
                  onSecondary: context.read<AuthCubit>().logout,
                ),
              ),
            _ => const LoadingView(),
          },
        );
      },
    );
  }
}
