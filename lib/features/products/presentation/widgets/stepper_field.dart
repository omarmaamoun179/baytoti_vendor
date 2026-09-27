import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/caps_label.dart';

/// The design's − value + control, for price and stock. The value in the
/// middle is a field too, so a price far from the start is typed rather
/// than stepped to.
class StepperField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final ValueChanged<String>? onChanged;

  /// Re-reads the typed value once the field loses focus — to clamp it or
  /// put back a number that did not parse.
  final VoidCallback? onEditingDone;

  const StepperField({
    super.key,
    required this.label,
    required this.controller,
    required this.onDecrement,
    required this.onIncrement,
    required this.keyboardType,
    required this.inputFormatters,
    this.onChanged,
    this.onEditingDone,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CapsLabel(label),
        SizedBox(height: 8.h),
        Container(
          height: 46.h,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: p.line),
          ),
          child: Directionality(
            // −/+ read left to right in both languages, like the number.
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                _buildStep(context, '−', onDecrement),
                Expanded(
                  child: Focus(
                    onFocusChange: (focused) {
                      if (!focused) onEditingDone?.call();
                    },
                    child: TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      inputFormatters: inputFormatters,
                      textAlign: TextAlign.center,
                      onChanged: onChanged,
                      onSubmitted: (_) => onEditingDone?.call(),
                      style: AppStrings.text14w800.c(p.fg),
                      cursorColor: p.accent,
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                _buildStep(context, '+', onIncrement),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context, String sign, VoidCallback onTap) {
    final p = context.palette;

    return SizedBox(
      width: 38.w,
      height: double.infinity,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(sign, style: AppStrings.text17w800Flat.c(p.accent)),
        ),
      ),
    );
  }
}
