import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../../../core/widgets/load_state_views.dart';
import '../../../../core/widgets/pill_chip.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../cubit/location_setup_cubit.dart';
import '../cubit/location_setup_state.dart';

/// `/location` — the account's country and governorate, chosen by hand and
/// saved with `POST /location/context`. Not in the vendor design; built in
/// its style from the store tab's area chips. Pops with the saved
/// [LocationContext] so the row that opened it shows it at once.
class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LocationSetupCubit>()..load(),
      child: const _LocationView(),
    );
  }
}

class _LocationView extends StatelessWidget {
  const _LocationView();

  void _onState(BuildContext context, LocationSetupState state) {
    final saved = state.saved;
    if (state.status == LocationSetupStatus.saved && saved != null) {
      context.pop(saved);
      return;
    }
    final message = state.errorMessage;
    if (message != null && state.countries.isNotEmpty) {
      showAppToast(context, message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocationSetupCubit, LocationSetupState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          (current.errorMessage != null &&
              current.errorMessage != previous.errorMessage),
      listener: _onState,
      builder: (context, state) {
        final cubit = context.read<LocationSetupCubit>();
        final ready = state.countries.isNotEmpty;

        return Scaffold(
          body: Column(
            children: [
              ScreenHeader(
                kicker: 'kicker_location'.tr(),
                title: 'title_location'.tr(),
                showBack: true,
              ),
              Expanded(
                child: switch (state.status) {
                  LocationSetupStatus.loading => const LoadingView(),
                  LocationSetupStatus.failed => LoadErrorView(
                      message: state.errorMessage ?? 'location_failed'.tr(),
                      onRetry: cubit.load,
                    ),
                  _ => _buildForm(context, state),
                },
              ),
            ],
          ),
          bottomNavigationBar: !ready
              ? null
              : BottomActionBar(
                  child: PrimaryButton(
                    label: 'location_save'.tr(),
                    loading: state.isSaving,
                    enabled: state.canSave,
                    onPressed: cubit.save,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context, LocationSetupState state) {
    final p = context.palette;
    final cubit = context.read<LocationSetupCubit>();

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'location_intro'.tr(),
                style: AppStrings.text125w400Loose.c(p.fg2),
              ),
              SizedBox(height: 16.h),
              CapsLabel('location_country'.tr()),
              SizedBox(height: 8.h),
              _buildChips([
                for (final country in state.countries)
                  PillChip(
                    label: country.name,
                    selected: country == state.country,
                    onPressed: () => cubit.selectCountry(country),
                  ),
              ]),
              if (state.country != null) ...[
                SizedBox(height: 16.h),
                CapsLabel('location_governorate'.tr()),
                SizedBox(height: 8.h),
                if (state.loadingGovernorates)
                  const LoadingView()
                else
                  _buildChips([
                    for (final governorate in state.governorates)
                      PillChip(
                        label: governorate.name,
                        selected: governorate == state.governorate,
                        onPressed: () => cubit.selectGovernorate(governorate),
                      ),
                  ]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChips(List<Widget> chips) => Wrap(
        spacing: 7.w,
        runSpacing: 7.h,
        children: chips,
      );
}
