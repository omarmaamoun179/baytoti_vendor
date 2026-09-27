import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/utils/photo_picker.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/info_note.dart';
import '../../../../core/widgets/load_state_views.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../domain/entities/product_enums.dart';
import '../cubit/product_editor_cubit.dart';
import '../cubit/product_editor_state.dart';
import '../widgets/product_editor_bar.dart';
import '../widgets/product_form.dart';
import '../widgets/product_photos_card.dart';

/// V06 — a new product (`/products/new`), or one being edited
/// (`/products/:id`), in the same form: photos first, then price, stock and
/// preparation time. Nothing is on sale before review, and the note says so.
///
/// Pops with `true` once saved, so the list reads itself again. Leaving
/// with unsaved edits asks first.
class ProductEditorPage extends StatelessWidget {
  final String? productId;

  const ProductEditorPage({super.key, this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductEditorCubit>()..load(productId),
      child: _ProductEditorView(productId: productId),
    );
  }
}

class _ProductEditorView extends StatefulWidget {
  final String? productId;

  const _ProductEditorView({this.productId});

  @override
  State<_ProductEditorView> createState() => _ProductEditorViewState();
}

class _ProductEditorViewState extends State<_ProductEditorView> {
  final _form = GlobalKey<ProductFormState>();
  bool _edited = false;
  bool _leaving = false;

  void _markEdited() {
    if (!_edited) setState(() => _edited = true);
  }

  Future<void> _addPhotos() async {
    final paths = await pickGalleryPhotos(context);
    if (!mounted || paths.isEmpty) return;
    context.read<ProductEditorCubit>().addPhotos(paths);
  }

  void _save({required bool submitForReview}) {
    final values = _form.currentState?.submit();
    if (values == null) return;
    context
        .read<ProductEditorCubit>()
        .save(values, submitForReview: submitForReview);
  }

  Future<void> _confirmLeave() async {
    final discard = await showConfirmSheet(
      context,
      icon: AppIcons.info,
      title: 'discard_changes_title'.tr(),
      body: 'discard_changes_body'.tr(),
      confirmLabel: 'discard_changes'.tr(),
      destructive: true,
    );
    if (!discard || !mounted) return;
    setState(() => _leaving = true);
    Navigator.of(context).pop(false);
  }

  void _onState(BuildContext context, ProductEditorState state) {
    if (state.saveStatus == ProductSaveStatus.saved) {
      final submitted = state.saved?.state == ProductState.pendingReview;
      showAppToast(
        context,
        (submitted ? 'product_submitted' : 'product_draft_saved').tr(),
      );
      setState(() => _leaving = true);
      Navigator.of(context).pop(true);
      return;
    }
    final message = state.displayError;
    if (message != null) showAppToast(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.productId == null;

    return BlocConsumer<ProductEditorCubit, ProductEditorState>(
      listenWhen: (previous, current) =>
          current.saveStatus == ProductSaveStatus.saved ||
          (current.displayError != null &&
              current.displayError != previous.displayError),
      listener: _onState,
      builder: (context, state) {
        final dirty = _edited || state.photosChanged;

        return PopScope(
          canPop: _leaving || !dirty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmLeave();
          },
          child: Scaffold(
            body: Column(
              children: [
                ScreenHeader(
                  kicker: (isNew ? 'kicker_new_product' : 'kicker_edit_product')
                      .tr(),
                  title: (isNew ? 'title_new_product' : 'title_edit_product')
                      .tr(),
                  showBack: true,
                ),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
            bottomNavigationBar: state.status == ProductEditorStatus.ready
                ? ProductEditorBar(
                    saveStatus: state.saveStatus,
                    onDraft: () => _save(submitForReview: false),
                    onSubmit: () => _save(submitForReview: true),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProductEditorState state) {
    final cubit = context.read<ProductEditorCubit>();

    return switch (state.status) {
      ProductEditorStatus.loading => const LoadingView(),
      ProductEditorStatus.error => LoadErrorView(
          message: state.errorMessage ?? 'product_failed'.tr(),
          onRetry: () => cubit.load(widget.productId),
        ),
      ProductEditorStatus.ready => ListView(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            ProductPhotosCard(
              photos: state.photos,
              onAdd: _addPhotos,
              onMakeCover: cubit.makeCover,
              onRemove: cubit.removePhoto,
              onRetry: cubit.retryPhoto,
            ),
            SizedBox(height: 14.h),
            ProductForm(
              key: _form,
              categories: state.categories,
              product: state.product,
              onChanged: _markEdited,
            ),
            SizedBox(height: 14.h),
            InfoNote(
              message: state.product?.reviewNote ?? 'product_review_rule'.tr(),
            ),
          ],
        ),
    };
  }
}
