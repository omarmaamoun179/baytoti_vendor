import 'package:easy_localization/easy_localization.dart';

/// Kuwaiti dinar formatting.
///
/// The API carries money as integer **fils** in `*_fils` fields (1 KWD =
/// 1000 fils) — never a float — and KWD prints with three decimals:
/// `38.750`. The `en` locale is pinned on purpose: `intl`'s Arabic locale
/// emits Arabic-Indic digits (٣٨٫٧٥٠), while the design renders Western
/// digits inside otherwise-RTL text.
class Money {
  Money._();

  static final NumberFormat _format = NumberFormat('0.000', 'en');

  /// `38.750` — the amount alone, for places that style the currency
  /// separately or leave it to a label ("Price (KWD)").
  static String amount(int fils) => _format.format(fils / 1000);

  /// `38.750 د.ك` / `38.750 KWD` — amount and currency in the app's
  /// language.
  static String display(int fils) => '${amount(fils)} ${'currency_kwd'.tr()}';

  /// Fils from a typed amount (`"4.5"` → 4500), or null when it does not
  /// read as a non-negative number of dinars.
  static int? parseFils(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    if (value == null || value < 0 || value.isNaN || value.isInfinite) {
      return null;
    }
    return (value * 1000).round();
  }
}
