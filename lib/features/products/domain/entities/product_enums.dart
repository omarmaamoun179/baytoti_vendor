/// Where a product stands — the contract's `state`: `draft ·
/// pending_review · published · rejected · hidden`. Stock 0 forces
/// [hidden] on the server.
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

/// How long a family needs before an order is ready — the contract's
/// `preparation_time`.
enum PreparationTime {
  sameDay('same_day'),
  oneDay('24h'),
  twoToThreeDays('2_3_days');

  const PreparationTime(this.wire);

  final String wire;

  static PreparationTime fromWire(String? value) => values.firstWhere(
        (time) => time.wire == value,
        orElse: () => oneDay,
      );
}

/// The limits the product form enforces. The contract states none, so
/// these are the app's own until the API publishes its rules — kept here,
/// on the domain, so the form and the request cannot drift apart.
class ProductRules {
  ProductRules._();

  static const int nameMinLength = 2;
  static const int nameMaxLength = 80;
  static const int descriptionMaxLength = 600;

  /// The price stepper moves in quarter dinars, as the design's does.
  static const int priceStepFils = 250;
  static const int minPriceFils = 250;
  static const int maxPriceFils = 999750;

  static const int maxStock = 999;

  /// Photos a product can carry; the grid stops offering "add" after this.
  static const int maxPhotos = 8;
}
