import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_palette.dart';

/// One of the design's stroke icons, tinted to [color].
///
/// The design draws its icons as inline SVG — 24-unit viewBox, 1.4–2.4
/// strokes — and [AppIcons] carries those paths verbatim, so a glyph here is
/// the one in the design rather than the nearest Material icon.
///
/// [mirrorInRtl] flips a directional glyph (a chevron) the way the design
/// does with `transform: scaleX(-1)` under `dir="rtl"`.
class AppIcon extends StatelessWidget {
  final String svg;
  final double size;
  final Color? color;
  final bool mirrorInRtl;

  const AppIcon(
    this.svg, {
    super.key,
    required this.size,
    this.color,
    this.mirrorInRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? IconTheme.of(context).color ?? context.palette.fg,
        BlendMode.srcIn,
      ),
    );

    final rtl = Directionality.of(context) == TextDirection.rtl;
    return mirrorInRtl && rtl ? Transform.flip(flipX: true, child: icon) : icon;
  }
}

/// The design's icons, as SVG source. Stroke widths and joins are the
/// design's own; the stroke color is replaced by [AppIcon]'s tint.
class AppIcons {
  AppIcons._();

  static String _stroke(String body, double width, {bool round = false}) =>
      '<svg viewBox="0 0 24 24" fill="none" stroke="#000" '
      'stroke-width="$width"'
      '${round ? ' stroke-linecap="round" stroke-linejoin="round"' : ''}>'
      '$body</svg>';

  // ── Navigation ─────────────────────────────────────────────────────
  /// `<` — back in LTR; mirror it for RTL.
  static final String chevronBack =
      _stroke('<path d="M15 18l-6-6 6-6"/>', 2.4, round: true);

  /// `>` — forward in LTR; mirror it for RTL.
  static final String chevronForward =
      _stroke('<path d="M9 6l6 6-6 6"/>', 2.4, round: true);

  static final String navDashboard = _stroke(
    '<rect x="3" y="3" width="7" height="9" rx="1.5"/>'
    '<rect x="14" y="3" width="7" height="5" rx="1.5"/>'
    '<rect x="14" y="12" width="7" height="9" rx="1.5"/>'
    '<rect x="3" y="16" width="7" height="5" rx="1.5"/>',
    1.8,
  );

  static final String navOrders = _stroke(
    '<rect x="4" y="4" width="16" height="16" rx="2.5"/>'
    '<path d="M8 9.5h8M8 14h5"/>',
    1.8,
  );

  static final String navProducts = _stroke(
    '<path d="M3 7l9-4 9 4v10l-9 4-9-4z"/><path d="M3 7l9 4 9-4M12 11v10"/>',
    1.8,
  );

  static final String navOffers = _stroke(
    '<path d="M20.6 13.4L12 22l-9-9V3h10z"/>'
    '<circle cx="7.5" cy="7.5" r="1.4"/>',
    1.8,
  );

  static final String navStore = _stroke(
    '<path d="M4 9h16v11H4z"/><path d="M3 9l2-5h14l2 5"/>',
    1.8,
  );

  // ── Actions ────────────────────────────────────────────────────────
  static final String bell = _stroke(
    '<path d="M18 8a6 6 0 10-12 0c0 7-3 9-3 9h18s-3-2-3-9"/>'
    '<path d="M13.7 21a2 2 0 01-3.4 0"/>',
    1.8,
  );

  static final String search = _stroke(
    '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>',
    2,
  );

  static final String phone = _stroke(
    '<path d="M21 15v4a2 2 0 01-2 2A17 17 0 013 5a2 2 0 012-2h4l2 5-2.5 '
    '1.5a13 13 0 006 6L16 13z"/>',
    1.8,
  );

  static final String close = _stroke('<path d="M18 6L6 18M6 6l12 12"/>', 2);

  static final String check = _stroke('<path d="M5 12.5l5 5 9-10"/>', 3.4);

  static final String plus =
      _stroke('<path d="M12 5v14M5 12h14"/>', 2, round: true);

  static final String calendar = _stroke(
    '<rect x="3" y="5" width="18" height="16" rx="2"/>'
    '<path d="M16 3v4M8 3v4M3 10h18"/>',
    1.8,
  );

  static final String globe = _stroke(
    '<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/>'
    '<path d="M12 3a14 14 0 010 18a14 14 0 010-18z"/>',
    1.8,
  );

  /// A map pin, for the account's location. Not one of the design's own
  /// glyphs; drawn at the strokes of [globe] beside it.
  static final String pin = _stroke(
    '<path d="M12 21s-7-6.2-7-11.5a7 7 0 0114 0C19 14.8 12 21 12 21z"/>'
    '<circle cx="12" cy="9.5" r="2.5"/>',
    1.8,
    round: true,
  );

  static final String logout = _stroke(
    '<path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/>'
    '<path d="M16 17l5-5-5-5M21 12H9"/>',
    1.8,
    round: true,
  );

  static final String refresh = _stroke(
    '<path d="M21 12a9 9 0 11-3-6.7L21 8"/><path d="M21 3v5h-5"/>',
    2,
    round: true,
  );

  // ── Status ─────────────────────────────────────────────────────────
  static final String clock = _stroke(
    '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    2,
  );

  static final String info = _stroke(
    '<circle cx="12" cy="12" r="9"/><path d="M12 8v5M12 16.5v.01"/>',
    2,
  );

  /// A password field's switch: [eye] shows what is typed, [eyeOff] hides
  /// it again. Not in the design, which draws no password field; Feather's,
  /// like its other stroke icons.
  static final String eye = _stroke(
    '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>'
    '<circle cx="12" cy="12" r="3"/>',
    1.8,
    round: true,
  );

  static final String eyeOff = _stroke(
    '<path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 '
    '18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 '
    '18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24M1 1l22 22"/>',
    1.8,
    round: true,
  );

  /// The profile photo's placeholder: a head and shoulders.
  static final String user = _stroke(
    '<path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/>'
    '<circle cx="12" cy="7" r="4"/>',
    1.6,
    round: true,
  );

  /// The photo placeholder's picture glyph.
  static final String image = _stroke(
    '<rect x="3" y="3" width="18" height="18" rx="2"/>'
    '<circle cx="8.5" cy="8.5" r="1.6"/><path d="M21 15l-5-5L4 21"/>',
    1.4,
  );

  static const String heart =
      '<svg viewBox="0 0 24 24" fill="#000"><path d="M20.8 5.6a5 5 0 00-7.1 '
      '0L12 7.3l-1.7-1.7a5 5 0 10-7.1 7.1l8.8 8.8 8.8-8.8a5 5 0 000-7.1z"/>'
      '</svg>';

  /// The house in the sign-in tile — a 48-unit viewBox of its own.
  static const String house =
      '<svg viewBox="0 0 48 48" fill="none" stroke="#000" stroke-width="2.6" '
      'stroke-linecap="round" stroke-linejoin="round">'
      '<path d="M7 21L24 8l17 13"/><path d="M11 20v19h26V20"/>'
      '<path d="M19 39V28h10v11"/><path d="M18 15.5h12" stroke-width="2"/>'
      '</svg>';
}
