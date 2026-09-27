import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/utils/photo_picker.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/load_state_views.dart';
import '../../../../core/widgets/locale_change_listener.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../domain/entities/store_profile.dart';
import '../cubit/store_cubit.dart';
import '../cubit/store_state.dart';
import '../widgets/account_card.dart';
import '../widgets/store_cover.dart';
import '../widgets/store_details_card.dart';
import '../widgets/verification_card.dart';

/// V08 — the store profile: the cover, name, story and city the customer
/// sees on the family page, and where verification stands.
class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StoreCubit>()..load(),
      child: const _StoreView(),
    );
  }
}

class _StoreView extends StatefulWidget {
  const _StoreView();

  @override
  State<_StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<_StoreView> {
  /// A new key for each store read afresh — another language, a save — so
  /// the fields start over from it.
  GlobalKey<StoreDetailsCardState> _details = GlobalKey();
  StoreProfile? _detailsFor;

  /// Shows "Saved ✓" on the button until the next edit, as the design does.
  bool _showSaved = false;

  void _edited() {
    if (_showSaved) setState(() => _showSaved = false);
  }

  Future<void> _changeCover() async {
    final paths = await pickGalleryPhotos(context, multiple: false);
    if (!mounted || paths.isEmpty) return;
    _edited();
    context.read<StoreCubit>().changeCover(paths.first);
  }

  void _save() {
    final values = _details.currentState?.submit();
    if (values != null) context.read<StoreCubit>().save(values);
  }

  Future<void> _signOut() async {
    final confirmed = await showConfirmSheet(
      context,
      icon: AppIcons.logout,
      title: 'sign_out_title'.tr(),
      body: 'sign_out_body'.tr(),
      confirmLabel: 'sign_out'.tr(),
    );
    if (confirmed && mounted) context.read<AuthCubit>().logout();
  }

  void _onState(BuildContext context, StoreState state) {
    if (state.saveStatus == StoreSaveStatus.saved) {
      setState(() => _showSaved = true);
      showAppToast(context, 'store_saved_toast'.tr());
      return;
    }
    final message = state.errorMessage;
    if (message != null && state.store != null) {
      showAppToast(context, message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LocaleChangeListener(
      onChanged: context.read<StoreCubit>().load,
      child: BlocConsumer<StoreCubit, StoreState>(
        listenWhen: (previous, current) =>
            previous.saveStatus != current.saveStatus ||
            (current.errorMessage != null &&
                current.errorMessage != previous.errorMessage),
        listener: _onState,
        builder: (context, state) {
          final store = state.store;

          return Scaffold(
            body: Column(
              children: [
                ScreenHeader(
                  kicker: 'kicker_store'.tr(),
                  title: 'title_store'.tr(),
                ),
                Expanded(child: _buildBody(context, state, store)),
              ],
            ),
            bottomNavigationBar: store == null
                ? null
                : BottomActionBar(
                    child: PrimaryButton(
                      label: (_showSaved ? 'store_saved' : 'store_save').tr(),
                      loading: state.isSaving,
                      onPressed: _save,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    StoreState state,
    StoreProfile? store,
  ) {
    if (store == null) {
      return state.status == StoreStatus.error
          ? LoadErrorView(
              message: state.errorMessage ?? 'store_failed'.tr(),
              onRetry: context.read<StoreCubit>().load,
            )
          : const LoadingView();
    }

    if (!identical(store, _detailsFor)) {
      _detailsFor = store;
      _details = GlobalKey();
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        StoreCover(
          source: state.coverSource,
          uploading: state.cover?.isUploading ?? false,
          onChange: store.coverEditable ? _changeCover : null,
        ),
        SizedBox(height: 14.h),
        StoreDetailsCard(
          key: _details,
          store: store,
          onChanged: _edited,
        ),
        SizedBox(height: 14.h),
        if (store.documents.isNotEmpty) ...[
          VerificationCard(documents: store.documents),
          SizedBox(height: 14.h),
        ],
        AccountCard(onSignOut: _signOut),
      ],
    );
  }
}
