import 'package:flutter/material.dart';

/// Raw color values from the Baytouti design, one constant per design token.
///
/// Nothing in the UI reads these directly — they are composed into
/// [AppPalette](../theme/app_palette.dart), which widgets reach through
/// `context.palette`. Keeping the literals here means a rebrand touches this
/// file only. The names in the comments are the design's CSS variables.
class AppColors {
  AppColors._();

  // ── Grounds ────────────────────────────────────────────────────────
  static const Color bg = Color(0xFFFAF6EF); // --color-bg
  static const Color surface = Color(0xFFFFFFFF); // --color-surface
  static const Color neutral200 = Color(0xFFF3EDE3);
  static const Color neutral300 = Color(0xFFEFE7DA);
  static const Color divider = Color(0xFFEAE1D3); // --color-divider
  static const Color neutral400 = Color(0xFFDFD5C5);
  static const Color neutral500 = Color(0xFFBCB1A0);

  // ── Ink ────────────────────────────────────────────────────────────
  static const Color text = Color(0xFF1F2A24); // --color-text
  static const Color neutral800 = Color(0xFF3C4741);
  static const Color neutral700 = Color(0xFF6E675C);
  static const Color neutral600 = Color(0xFF8B8377);

  // ── Accent (the family green) ──────────────────────────────────────
  static const Color accent = Color(0xFF1F5A42);
  static const Color accent100 = Color(0xFFEAF2ED);
  static const Color accent200 = Color(0xFFD8E8DF);
  static const Color accent600 = Color(0xFF18523B);
  static const Color accent700 = Color(0xFF134130);
  static const Color onAccent = Color(0xFFFFFFFF);

  // ── Amber (attention: new orders, review, low stock) ───────────────
  static const Color amber = Color(0xFFE08A2E); // --bt-amber
  static const Color amberBg = Color(0xFFFBEEDC); // --bt-amber-bg
  static const Color amberInk = Color(0xFFA9651A); // --bt-amber-ink

  /// The amber the vendor app itself sits on — its splash and its icon — to
  /// tell it from the customer app's green. Not a CSS variable: the design
  /// writes it into the splash and the icon sheet.
  static const Color vendorGround = Color(0xFFD9822A);

  // ── Refusal ────────────────────────────────────────────────────────
  /// The design draws no error state of its own. This is the brick the API
  /// contract uses for `DELETE`, so a failure sits in the same family.
  static const Color bad = Color(0xFF8B3A2E);
  static const Color badBg = Color(0xFFF6E6E2);

  /// `--bt-card: 0 1px 3px rgba(31,42,36,.07)` — the one elevation.
  static const Color cardShadow = Color(0x121F2A24);

  /// The toast's backdrop scrim and sheet barrier.
  static const Color scrim = Color(0x801F2A24);
}
