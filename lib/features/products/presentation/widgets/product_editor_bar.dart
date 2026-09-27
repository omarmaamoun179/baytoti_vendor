import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../cubit/product_editor_state.dart';

/// Keep it as a draft, or send it for review — the product form's two ways
/// out. Each shows its own spinner; both hold while either is saving.
class ProductEditorBar extends StatelessWidget {
  final ProductSaveStatus saveStatus;
  final VoidCallback onDraft;
  final VoidCallback onSubmit;

  const ProductEditorBar({
    super.key,
    required this.saveStatus,
    required this.onDraft,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final savingDraft = saveStatus == ProductSaveStatus.savingDraft;
    final submitting = saveStatus == ProductSaveStatus.submitting;
    final busy = savingDraft || submitting;

    return BottomActionBar(
      child: Row(
        children: [
          SecondaryButton(
            label: 'product_save_draft'.tr(),
            loading: savingDraft,
            onPressed: busy ? null : onDraft,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: PrimaryButton(
              label: 'product_submit_review'.tr(),
              loading: submitting,
              enabled: !savingDraft,
              onPressed: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
