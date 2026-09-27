import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';

/// The design's small tracked label — a field name ("PRODUCT NAME"), a card
/// heading ("CUSTOMER"), the header kicker.
///
/// The design writes these `text-transform: uppercase; letter-spacing:
/// 0.14em`, and applies it to both languages. Arabic has no case, and
/// spacing its letters pulls the joined script apart, so both are applied
/// only when the text has no Arabic in it.
class CapsLabel extends StatelessWidget {
  final String text;

  /// Defaults to `800 10px`.
  final TextStyle? style;

  /// Defaults to `neutral-700`.
  final Color? color;

  /// In `em`; defaults to the field labels' 0.14.
  final double tracking;

  final TextAlign? textAlign;

  const CapsLabel(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.tracking = .14,
    this.textAlign,
  });

  static final RegExp _arabic = RegExp(r'[؀-ۿݐ-ݿ]');

  /// Whether [text] reads as Latin — no Arabic letters in it.
  static bool isLatin(String text) => !_arabic.hasMatch(text);

  @override
  Widget build(BuildContext context) {
    final latin = isLatin(text);
    final base = (style ?? AppStrings.text10w800)
        .c(color ?? context.palette.fg2);

    return Text(
      latin ? text.toUpperCase() : text,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: latin ? base.tracked(tracking) : base,
    );
  }
}
