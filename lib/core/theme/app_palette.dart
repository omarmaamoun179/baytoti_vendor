import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// The design's token set, carried on [ThemeData] as an extension.
///
/// Material's [ColorScheme] has no slot for most of the design's tokens —
/// the neutral ramp, the amber attention pair — so they live here and are
/// read as `context.palette.accent`. The design defines one light palette;
/// a dark one would be a second constant here and a second theme in
/// [AppTheme], with no widget needing to change.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// Page background — the warm off-white.
  final Color bg;

  /// Cards, the header, the tab bar and the action bars.
  final Color surf;

  /// Segmented-control track and neutral tag tiles (`neutral-200`).
  final Color surf2;

  /// Photo placeholders and the unreached steps of the order chain
  /// (`neutral-300`).
  final Color muted;

  /// Hairline borders (`divider`).
  final Color line;

  /// Stronger borders, the switch's off track, a step's empty ring
  /// (`neutral-400`).
  final Color line2;

  /// A button that cannot act yet, and the dashed "add photo" border
  /// (`neutral-500`).
  final Color disabled;

  /// Primary text.
  final Color fg;

  /// Body copy inside notes and neutral tags (`neutral-800`).
  final Color ink;

  /// Secondary text and field labels (`neutral-700`).
  final Color fg2;

  /// Tertiary text, hints, an inactive tab (`neutral-600`).
  final Color fg3;

  /// The family green.
  final Color accent;

  /// Pressed accent (`accent-600`).
  final Color accentHi;

  /// Text on the soft accent tints (`accent-700`).
  final Color accentInk;

  /// Soft accent tint behind "accepted"/"preparing" (`accent-100`).
  final Color accentSoft;

  /// Stronger tint — "ready", the weekly chart's bars (`accent-200`).
  final Color accentSoft2;

  /// Text and icons drawn on the accent.
  final Color onAccent;

  /// Attention: a new order, something under review, stock running out.
  final Color amber;
  final Color amberBg;
  final Color amberInk;

  /// A refusal — a failed request, a rejected product.
  final Color bad;
  final Color badBg;

  /// The single card elevation, `0 1px 3px`.
  final Color shadow;

  const AppPalette({
    required this.bg,
    required this.surf,
    required this.surf2,
    required this.muted,
    required this.line,
    required this.line2,
    required this.disabled,
    required this.fg,
    required this.ink,
    required this.fg2,
    required this.fg3,
    required this.accent,
    required this.accentHi,
    required this.accentInk,
    required this.accentSoft,
    required this.accentSoft2,
    required this.onAccent,
    required this.amber,
    required this.amberBg,
    required this.amberInk,
    required this.bad,
    required this.badBg,
    required this.shadow,
  });

  static const AppPalette light = AppPalette(
    bg: AppColors.bg,
    surf: AppColors.surface,
    surf2: AppColors.neutral200,
    muted: AppColors.neutral300,
    line: AppColors.divider,
    line2: AppColors.neutral400,
    disabled: AppColors.neutral500,
    fg: AppColors.text,
    ink: AppColors.neutral800,
    fg2: AppColors.neutral700,
    fg3: AppColors.neutral600,
    accent: AppColors.accent,
    accentHi: AppColors.accent600,
    accentInk: AppColors.accent700,
    accentSoft: AppColors.accent100,
    accentSoft2: AppColors.accent200,
    onAccent: AppColors.onAccent,
    amber: AppColors.amber,
    amberBg: AppColors.amberBg,
    amberInk: AppColors.amberInk,
    bad: AppColors.bad,
    badBg: AppColors.badBg,
    shadow: AppColors.cardShadow,
  );

  /// The accent under the name the Cloak widgets brought over with the core
  /// use (`PhoneTextFormField`): Cloak's accent was gold, Baytouti's is the
  /// family green. Write [accent] in new code.
  Color get gold => accent;

  /// `--bt-card`, the shadow under every card.
  List<BoxShadow> get cardShadow => [
        BoxShadow(color: shadow, blurRadius: 3, offset: const Offset(0, 1)),
      ];

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surf,
    Color? surf2,
    Color? muted,
    Color? line,
    Color? line2,
    Color? disabled,
    Color? fg,
    Color? ink,
    Color? fg2,
    Color? fg3,
    Color? accent,
    Color? accentHi,
    Color? accentInk,
    Color? accentSoft,
    Color? accentSoft2,
    Color? onAccent,
    Color? amber,
    Color? amberBg,
    Color? amberInk,
    Color? bad,
    Color? badBg,
    Color? shadow,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surf: surf ?? this.surf,
      surf2: surf2 ?? this.surf2,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      disabled: disabled ?? this.disabled,
      fg: fg ?? this.fg,
      ink: ink ?? this.ink,
      fg2: fg2 ?? this.fg2,
      fg3: fg3 ?? this.fg3,
      accent: accent ?? this.accent,
      accentHi: accentHi ?? this.accentHi,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      accentSoft2: accentSoft2 ?? this.accentSoft2,
      onAccent: onAccent ?? this.onAccent,
      amber: amber ?? this.amber,
      amberBg: amberBg ?? this.amberBg,
      amberInk: amberInk ?? this.amberInk,
      bad: bad ?? this.bad,
      badBg: badBg ?? this.badBg,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      bg: mix(bg, other.bg),
      surf: mix(surf, other.surf),
      surf2: mix(surf2, other.surf2),
      muted: mix(muted, other.muted),
      line: mix(line, other.line),
      line2: mix(line2, other.line2),
      disabled: mix(disabled, other.disabled),
      fg: mix(fg, other.fg),
      ink: mix(ink, other.ink),
      fg2: mix(fg2, other.fg2),
      fg3: mix(fg3, other.fg3),
      accent: mix(accent, other.accent),
      accentHi: mix(accentHi, other.accentHi),
      accentInk: mix(accentInk, other.accentInk),
      accentSoft: mix(accentSoft, other.accentSoft),
      accentSoft2: mix(accentSoft2, other.accentSoft2),
      onAccent: mix(onAccent, other.onAccent),
      amber: mix(amber, other.amber),
      amberBg: mix(amberBg, other.amberBg),
      amberInk: mix(amberInk, other.amberInk),
      bad: mix(bad, other.bad),
      badBg: mix(badBg, other.badBg),
      shadow: mix(shadow, other.shadow),
    );
  }
}

extension PaletteContext on BuildContext {
  /// The active token set. Falls back to [AppPalette.light] so a widget built
  /// outside the app theme (a test, a standalone preview) still renders.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
