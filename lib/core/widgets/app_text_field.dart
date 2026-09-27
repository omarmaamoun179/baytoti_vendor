import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'caps_label.dart';

/// The design's input: a 46px field on the page background, hairline border,
/// 12px corners, `600 14px` text — with an optional tracked [label] above.
///
/// [multiline] turns it into the design's text area (`400 12.5px/1.6`,
/// `11px 13px` padding), which grows between [minLines] and [maxLines].
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;

  final bool multiline;
  final int minLines;
  final int maxLines;
  final int? maxLength;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;

  /// Defaults to the page background; sign-in's fields sit on white.
  final Color? fillColor;

  final bool enabled;

  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.multiline = false,
    this.minLines = 3,
    this.maxLines = 6,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.style,
    this.fillColor,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final textStyle = style ??
        (multiline ? AppStrings.text125w400 : AppStrings.text14w600);

    final field = TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      enabled: enabled,
      minLines: multiline ? minLines : 1,
      maxLines: multiline ? maxLines : 1,
      maxLength: maxLength,
      keyboardType: multiline ? TextInputType.multiline : keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: textStyle.c(p.fg),
      cursorColor: p.accent,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: textStyle.c(p.fg3),
        // The design's fields carry no counter; the limit still holds.
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: fillColor ?? p.bg,
        contentPadding: multiline
            ? EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h)
            : EdgeInsets.symmetric(horizontal: 13.w, vertical: 15.h),
        border: _border(p.line),
        enabledBorder: _border(p.line),
        disabledBorder: _border(p.line),
        focusedBorder: _border(p.accent),
        errorBorder: _border(p.bad),
        focusedErrorBorder: _border(p.bad),
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CapsLabel(label!),
        SizedBox(height: 8.h),
        field,
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: color),
      );
}
