/// Every bundled asset path, in one place.
///
/// The Baytouti design draws no bundled imagery — a missing photo is a
/// neutral tile with an image glyph (`PhotoPlaceholder`), and the brand mark
/// is drawn from its SVG paths (`BrandMark`). This is where a path goes when
/// one is added.
class AppAssets {
  AppAssets._();

  static const String translations = 'assets/translations';
}
