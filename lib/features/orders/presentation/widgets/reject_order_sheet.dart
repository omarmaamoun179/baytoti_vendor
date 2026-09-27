import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../../../core/widgets/pill_chip.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_handle.dart';
import '../../domain/entities/order_status.dart';

/// What a rejection is sent with.
typedef OrderRejection = ({RejectReason reason, String? note});

/// Asks why before an order is turned down — the reject call takes a
/// `reason` — and what the customer should be told. Resolves null when the
/// family backs out.
///
/// The sheet only collects; the request goes out from the details screen,
/// whose toast can then report on it.
Future<OrderRejection?> showRejectOrderSheet(BuildContext context) =>
    showModalBottomSheet<OrderRejection>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => const _RejectOrderSheet(),
    );

class _RejectOrderSheet extends StatefulWidget {
  const _RejectOrderSheet();

  @override
  State<_RejectOrderSheet> createState() => _RejectOrderSheetState();
}

class _RejectOrderSheetState extends State<_RejectOrderSheet> {
  static const int _noteMaxLength = 200;

  final _note = TextEditingController();
  RejectReason? _reason;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  static String _reasonKey(RejectReason reason) => switch (reason) {
        RejectReason.outOfStock => 'reject_reason_out_of_stock',
        RejectReason.tooBusy => 'reject_reason_too_busy',
        RejectReason.cannotDeliver => 'reject_reason_cannot_deliver',
        RejectReason.other => 'reject_reason_other',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reason = _reason;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: SheetHandle()),
              Text(
                'reject_title'.tr(),
                style: AppStrings.text17w800.c(p.fg),
              ),
              SizedBox(height: 6.h),
              Text(
                'reject_body'.tr(),
                style: AppStrings.text125w400.c(p.fg2),
              ),
              SizedBox(height: 16.h),
              CapsLabel('reject_reason_label'.tr()),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 7.w,
                runSpacing: 7.h,
                children: [
                  for (final option in RejectReason.values)
                    PillChip(
                      label: _reasonKey(option).tr(),
                      selected: option == reason,
                      onPressed: () => setState(() => _reason = option),
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: 'reject_note_label'.tr(),
                hintText: 'reject_note_hint'.tr(),
                controller: _note,
                multiline: true,
                minLines: 2,
                maxLines: 4,
                maxLength: _noteMaxLength,
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'go_back'.tr(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: PrimaryButton(
                      label: 'order_reject'.tr(),
                      color: p.bad,
                      enabled: reason != null,
                      onPressed: () => Navigator.of(context).pop((
                        reason: reason!,
                        note: _note.text.trim().isEmpty
                            ? null
                            : _note.text.trim(),
                      )),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
