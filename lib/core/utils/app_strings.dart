import 'package:flutter/material.dart';

import 'size_config.dart';

/// The type ramp, named after the design's own `font:` shorthand —
/// `text13w800` is `font: 800 13px 'Archivo','IBM Plex Sans Arabic'`. A
/// suffix tells apart two line heights at the same size and weight.
///
/// Every line is set in Archivo, and Arabic — which Archivo does not draw —
/// falls through to IBM Plex Sans Arabic, exactly as the design's font stack
/// does. Plex stops at 700, so an 800 line renders its Arabic in Bold.
///
/// Sizes go through [SizeConfig.sp] so they scale with the 402×874 frame the
/// design was drawn on. Color is never baked in: apply it at the call site
/// with `.c(palette.fg2)`.
class AppStrings {
  AppStrings._();

  static const String fontFamily = 'Archivo';
  static const List<String> fontFamilyFallback = ['IBMPlexSansArabic'];

  static TextStyle _s(double size, FontWeight weight, [double? height]) =>
      TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: SizeConfig.sp(size),
        fontWeight: weight,
        height: height,
      );

  // ── Display ────────────────────────────────────────────────────────
  /// The splash's name — `800 46px/1`.
  static TextStyle get text46w800 => _s(46, FontWeight.w800, 1);

  /// The discount being drafted — `800 44px/1`.
  static TextStyle get text44w800 => _s(44, FontWeight.w800, 1);

  /// Today's sales — `800 34px/1`.
  static TextStyle get text34w800 => _s(34, FontWeight.w800, 1);

  /// Sign-in wordmark — `800 30px/1`.
  static TextStyle get text30w800 => _s(30, FontWeight.w800, 1);

  /// Onboarding welcome — `800 26px/1.15`.
  static TextStyle get text26w800 => _s(26, FontWeight.w800, 1.15);

  /// OTP title — `800 24px/1.2`; an OTP digit — `800 24px/1`.
  static TextStyle get text24w800 => _s(24, FontWeight.w800, 1.2);
  static TextStyle get text24w800Flat => _s(24, FontWeight.w800, 1);

  /// Order reference, KPI value — `800 22px/1`.
  static TextStyle get text22w800 => _s(22, FontWeight.w800, 1);

  /// Keypad digit — `800 20px/1`.
  static TextStyle get text20w800 => _s(20, FontWeight.w800, 1);

  /// Screen title in the header — `800 19px/1.25`.
  static TextStyle get text19w800 => _s(19, FontWeight.w800, 1.25);

  /// Discount −/+ and the "add photo" plus — `800 18px/1`.
  static TextStyle get text18w800 => _s(18, FontWeight.w800, 1);

  /// Section heading — `800 17px/1.2`; a stepper's −/+ — `800 17px/1`.
  static TextStyle get text17w800 => _s(17, FontWeight.w800, 1.2);
  static TextStyle get text17w800Flat => _s(17, FontWeight.w800, 1);

  // ── Body ───────────────────────────────────────────────────────────
  /// Offer tile percentage — `800 15px/1`.
  static TextStyle get text15w800 => _s(15, FontWeight.w800, 1);

  /// Phone number input — `600 15px/1`.
  static TextStyle get text15w600 => _s(15, FontWeight.w600, 1);

  /// Order total, payout, primary CTA, stepper value — `800 14px/1`.
  static TextStyle get text14w800 => _s(14, FontWeight.w800, 1);

  /// Text input — `600 14px/1`.
  static TextStyle get text14w600 => _s(14, FontWeight.w600, 1);

  /// Onboarding step, customer name — `800 13px/1.2`; a button label —
  /// `800 13px/1`.
  static TextStyle get text13w800 => _s(13, FontWeight.w800, 1.2);
  static TextStyle get text13w800Flat => _s(13, FontWeight.w800, 1);

  /// Empty-state line — `600 13px/1.5`; the splash's tagline — `/1.6`.
  static TextStyle get text13w600 => _s(13, FontWeight.w600, 1.5);
  static TextStyle get text13w600Loose => _s(13, FontWeight.w600, 1.6);

  /// The phone field's typed number — `500 13px/1.4`; its hint —
  /// `400 13px/1.4`. From the Cloak ramp `PhoneTextFormField` was built on.
  static TextStyle get text13w500 => _s(13, FontWeight.w500, 1.4);
  static TextStyle get text13w400Notif => _s(13, FontWeight.w400, 1.4);

  /// Onboarding welcome body — `400 13px/1.7`.
  static TextStyle get text13w400 => _s(13, FontWeight.w400, 1.7);

  /// Order card customer — `600 13.5px/1.3`.
  static TextStyle get text135w600 => _s(13.5, FontWeight.w600, 1.3);

  // ── Small ──────────────────────────────────────────────────────────
  /// Notification title — `800 12.5px/1.35`; auth tabs, a product price —
  /// `800 12.5px/1`.
  static TextStyle get text125w800 => _s(12.5, FontWeight.w800, 1.35);
  static TextStyle get text125w800Flat => _s(12.5, FontWeight.w800, 1);

  /// List row name — `600 12.5px/1.3`; a link — `600 12.5px/1`.
  static TextStyle get text125w600 => _s(12.5, FontWeight.w600, 1.3);
  static TextStyle get text125w600Flat => _s(12.5, FontWeight.w600, 1);

  /// Text area, sign-in intro — `400 12.5px/1.65`; OTP subtitle —
  /// `400 12.5px/1.7`.
  static TextStyle get text125w400 => _s(12.5, FontWeight.w400, 1.65);
  static TextStyle get text125w400Loose => _s(12.5, FontWeight.w400, 1.7);

  /// Card title, small button — `800 12px/1`.
  static TextStyle get text12w800 => _s(12, FontWeight.w800, 1);

  /// Document row label — `600 12px/1.3`.
  static TextStyle get text12w600 => _s(12, FontWeight.w600, 1.3);

  /// The phone field's own label — `500 12px/1` (Cloak's ramp).
  static TextStyle get text12w500 => _s(12, FontWeight.w500, 1);

  /// Sales change line — `400 12px/1.5`; search placeholder — `400 12px/1`.
  static TextStyle get text12w400 => _s(12, FontWeight.w400, 1.5);
  static TextStyle get text12w400Flat => _s(12, FontWeight.w400, 1);

  /// Order reference on a card, "resend" — `800 11.5px/1`.
  static TextStyle get text115w800 => _s(11.5, FontWeight.w800, 1);

  /// Chip label — `600 11.5px/1`.
  static TextStyle get text115w600 => _s(11.5, FontWeight.w600, 1);

  /// Notification body, terms — `400 11.5px/1.6`; review rule —
  /// `400 11.5px/1.65`; detail meta — `400 11.5px/1.5`; "no code?" —
  /// `400 11.5px/1`.
  static TextStyle get text115w400 => _s(11.5, FontWeight.w400, 1.6);
  static TextStyle get text115w400Loose => _s(11.5, FontWeight.w400, 1.65);
  static TextStyle get text115w400Meta => _s(11.5, FontWeight.w400, 1.5);
  static TextStyle get text115w400Flat => _s(11.5, FontWeight.w400, 1);

  /// "See all", a large status pill — `800 11px/1`.
  static TextStyle get text11w800 => _s(11, FontWeight.w800, 1);

  /// Summary, address — `400 11px/1.5`; step detail, hints —
  /// `400 11px/1.6`; week total — `400 11px/1`.
  static TextStyle get text11w400 => _s(11, FontWeight.w400, 1.5);
  static TextStyle get text11w400Loose => _s(11, FontWeight.w400, 1.6);
  static TextStyle get text11w400Flat => _s(11, FontWeight.w400, 1);

  /// Notification tag, document state — `800 10.5px/1`.
  static TextStyle get text105w800 => _s(10.5, FontWeight.w800, 1);

  /// Row meta, stock line — `400 10.5px/1.4`; photo hint, commission note
  /// — `400 10.5px/1.6`.
  static TextStyle get text105w400 => _s(10.5, FontWeight.w400, 1.4);
  static TextStyle get text105w400Loose => _s(10.5, FontWeight.w400, 1.6);

  /// Status pill, field label, "change cover" — `800 10px/1`.
  static TextStyle get text10w800 => _s(10, FontWeight.w800, 1);

  /// Timestamp, fulfilment method — `400 10px/1`.
  static TextStyle get text10w400 => _s(10, FontWeight.w400, 1);

  /// Tab-bar label — `600 9.5px/1`.
  static TextStyle get text95w600 => _s(9.5, FontWeight.w600, 1);

  /// Header kicker, tab badge — `800 9px/1`.
  static TextStyle get text9w800 => _s(9, FontWeight.w800, 1);

  /// Chart day label — `600 9px/1`.
  static TextStyle get text9w600 => _s(9, FontWeight.w600, 1);
}

extension TextStyleColor on TextStyle {
  /// `AppStrings.text13w800.c(palette.fg2)` — the design applies color at
  /// the point of use, never as part of the ramp.
  TextStyle c(Color color) => copyWith(color: color);

  /// Letter spacing in `em`, as the design writes it (`letter-spacing:
  /// 0.14em`). Only for Latin text: spacing Arabic pulls its joined letters
  /// apart — see `CapsLabel`.
  TextStyle tracked(double em) =>
      copyWith(letterSpacing: (fontSize ?? 14) * em);
}
