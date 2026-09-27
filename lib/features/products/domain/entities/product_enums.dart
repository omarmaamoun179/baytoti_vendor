/// Where a product stands: `draft · pending_review · published · rejected ·
/// hidden`. On the live API it is read from two fields — the moderation
/// `approval_status` (`draft · pending_review · approved · rejected`) and
/// the vendor's own `status` — an approved product being [published] while
/// its status is on and [hidden] while it is off.
enum ProductState {
  draft('draft'),
  pendingReview('pending_review'),
  published('published'),
  rejected('rejected'),
  hidden('hidden');

  const ProductState(this.wire);

  final String wire;

  /// Unknown reads as [hidden]: a product the app cannot place is not
  /// claimed to be on sale.
  static ProductState fromWire(String? value) => values.firstWhere(
        (state) => state.wire == value,
        orElse: () => hidden,
      );
}

/// How long a family needs before an order is ready — the design's three
/// chips. The live API counts `preparation_time_minutes`: each chip sends
/// [minutes], and a count the app did not send falls to the chip it fits.
enum PreparationTime {
  sameDay('same_day', minutes: 6 * 60),
  oneDay('24h', minutes: 24 * 60),
  twoToThreeDays('2_3_days', minutes: 3 * 24 * 60);

  const PreparationTime(this.wire, {required this.minutes});

  final String wire;
  final int minutes;

  static PreparationTime fromWire(String? value) => values.firstWhere(
        (time) => time.wire == value,
        orElse: () => oneDay,
      );

  /// Up to half a day is the same day; up to a day, a day; longer, two to
  /// three. Unknown reads as a day, the middle chip.
  static PreparationTime fromMinutes(int? minutes) => switch (minutes) {
        null => oneDay,
        <= 12 * 60 => sameDay,
        <= 24 * 60 => oneDay,
        _ => twoToThreeDays,
      };
}

/// The limits the product form enforces, kept here on the domain so the
/// form and the request cannot drift apart. Inside the API's own
/// (`StoreProductRequest`: a name of up to 255, a price of at least 0).
class ProductRules {
  ProductRules._();

  static const int nameMinLength = 2;
  static const int nameMaxLength = 80;
  static const int descriptionMaxLength = 600;

  /// The price stepper moves in quarter dinars, as the design's does.
  static const int priceStepFils = 250;
  static const int minPriceFils = 250;
  static const int maxPriceFils = 999750;

  /// Photos a product can carry; the grid stops offering "add" after this.
  static const int maxPhotos = 8;

  /// The API's limit on one photo: 5120 KB.
  static const int maxPhotoBytes = 5120 * 1024;
}
