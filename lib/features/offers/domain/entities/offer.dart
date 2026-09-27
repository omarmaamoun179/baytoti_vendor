import 'package:equatable/equatable.dart';

/// What an offer applies to — the contract's `scope`.
enum OfferScope {
  all('all'),
  category('category'),
  products('products');

  const OfferScope(this.wire);

  final String wire;

  static OfferScope fromWire(String? value) => values.firstWhere(
        (scope) => scope.wire == value,
        orElse: () => all,
      );
}

class Offer extends Equatable {
  final String id;
  final int percent;
  final OfferScope scope;

  /// "All products", "Sweets only" — the server's, in the app's language.
  final String scopeLabel;

  final DateTime? startsAt;
  final DateTime? endsAt;

  /// How many times it has been used.
  final int redemptionCount;

  const Offer({
    required this.id,
    required this.percent,
    required this.scope,
    required this.scopeLabel,
    this.startsAt,
    this.endsAt,
    this.redemptionCount = 0,
  });

  @override
  List<Object?> get props =>
      [id, percent, scope, scopeLabel, startsAt, endsAt, redemptionCount];
}

/// The platform's bounds on a family's discounts — `limits`.
class OfferLimits extends Equatable {
  final int minPercent;
  final int maxPercent;
  final int step;

  /// How many offers may run at once.
  final int maxActive;

  const OfferLimits({
    this.minPercent = 5,
    this.maxPercent = 70,
    this.step = 5,
    this.maxActive = 3,
  });

  /// [percent] moved one step, kept inside the bounds.
  int stepped(int percent, int direction) =>
      (percent + direction * step).clamp(minPercent, maxPercent);

  @override
  List<Object?> get props => [minPercent, maxPercent, step, maxActive];
}

/// `GET /vendor/offers`.
class OffersOverview extends Equatable {
  final OfferLimits limits;
  final List<Offer> offers;

  const OffersOverview({required this.limits, this.offers = const []});

  bool get atLimit => offers.length >= limits.maxActive;

  @override
  List<Object?> get props => [limits, offers];
}

/// `POST /vendor/offers` — `{percent, scope, product_ids, ends_at}`. The
/// design creates store-wide offers only.
class CreateOfferParams extends Equatable {
  final int percent;
  final DateTime endsAt;
  final OfferScope scope;
  final List<String> productIds;

  const CreateOfferParams({
    required this.percent,
    required this.endsAt,
    this.scope = OfferScope.all,
    this.productIds = const [],
  });

  @override
  List<Object?> get props => [percent, endsAt, scope, productIds];
}
