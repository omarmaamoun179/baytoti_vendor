import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/header_icon_button.dart';
import '../../../../core/widgets/info_note.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../domain/entities/vendor_application.dart';
import '../cubit/application_state.dart';
import '../widgets/approval_timeline.dart';
import '../widgets/welcome_card.dart';

/// V01 — sign-up and approval. A family whose application is not approved
/// sees where it stands instead of a silent waiting screen: the greeting,
/// the review banner, and the path from account to first product.
///
/// Shown by [AccountGate] in place of any store screen, so it has no back
/// and no tab bar; the header offers sign-out instead.
class ApplicationStatusPage extends StatelessWidget {
  final VendorApplication application;

  const ApplicationStatusPage({super.key, required this.application});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showConfirmSheet(
      context,
      icon: AppIcons.logout,
      title: 'sign_out_title'.tr(),
      body: 'sign_out_body'.tr(),
      confirmLabel: 'sign_out'.tr(),
    );
    if (confirmed && context.mounted) context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ApplicationCubit, ApplicationState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          previous.errorMessage != current.errorMessage,
      listener: (context, state) =>
          showAppToast(context, state.errorMessage!, isError: true),
      child: Scaffold(
        body: Column(
          children: [
            ScreenHeader(
              kicker: 'kicker_onboarding'.tr(),
              title: 'title_onboarding'.tr(),
              actions: [
                HeaderIconButton(
                  icon: AppIcons.logout,
                  iconSize: 16.r,
                  semanticLabel: 'sign_out'.tr(),
                  onPressed: () => _signOut(context),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final p = context.palette;
    final user = context.select((AuthCubit cubit) => cubit.state.user);
    final name = application.familyName ?? user?.fullName ?? '';
    final rejected = application.status == ReviewStatus.rejected;
    final advancing = context.select(
      (ApplicationCubit cubit) => cubit.state.advancing,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WelcomeCard(
          title: 'onboarding_welcome'.tr(args: [name]),
          message: 'onboarding_welcome_body'.tr(),
        ),
        SizedBox(height: 14.h),
        InfoNote(
          icon: AppIcons.clock,
          title: rejected
              ? 'application_rejected'.tr()
              : 'application_under_review'.tr(),
          message: rejected
              ? 'application_rejected_body'.tr()
              : 'application_review_sla'.tr(
                  args: [application.reviewSla ?? 'review_sla_default'.tr()],
                ),
        ),
        SizedBox(height: 20.h),
        ApprovalTimeline(steps: application.steps),
        SizedBox(height: 18.h),
        PrimaryButton(
          // On fixtures the button plays the back office, as in the design;
          // against the API approval is the server's, and it checks again.
          label: (useMockData ? 'simulate_approval' : 'check_status').tr(),
          loading: advancing,
          onPressed: context.read<ApplicationCubit>().advance,
        ),
        SizedBox(height: 10.h),
        Text(
          'approval_note'.tr(),
          style: AppStrings.text11w400Loose.c(p.fg3),
        ),
      ],
    );
  }
}
