import '../../../../core/utils/json_read.dart';
import '../../domain/entities/offer.dart';

/// An offer as the contract has it:
///
/// ```json
/// {"id": "off_3", "percent": 15, "scope": "all",
///  "scope_label": "كل المنتجات", "starts_at": "2026-09-20",
///  "ends_at": "2026-09-30", "window_display": "حتى ٣٠ سبتمبر",
///  "redemption_count": 42}
/// ```
///
/// `window_display` is not read: the app words the window from `ends_at`.
class OfferModel extends Offer {
  const OfferModel({
    required super.id,
    required super.percent,
    required super.scope,
    required super.scopeLabel,
    super.startsAt,
    super.endsAt,
    super.redemptionCount,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: requireString(json['id'], 'id'),
      percent: asInt(json['percent']) ?? 0,
      scope: OfferScope.fromWire(asString(json['scope'])),
      scopeLabel: asString(json['scope_label']) ?? '',
      startsAt: asDate(json['starts_at']),
      endsAt: asDate(json['ends_at']),
      redemptionCount: asInt(json['redemption_count']) ?? 0,
    );
  }
}

/// `GET /vendor/offers` — `{"limits": {…}, "items": [ … ]}`.
class OffersOverviewModel extends OffersOverview {
  const OffersOverviewModel({required super.limits, super.offers});

  factory OffersOverviewModel.fromJson(Map<String, dynamic> json) {
    final limits = asMap(json['limits']);
    const defaults = OfferLimits();

    return OffersOverviewModel(
      limits: OfferLimits(
        minPercent: asInt(limits['min_percent']) ?? defaults.minPercent,
        maxPercent: asInt(limits['max_percent']) ?? defaults.maxPercent,
        step: asInt(limits['step']) ?? defaults.step,
        maxActive: asInt(limits['max_active']) ?? defaults.maxActive,
      ),
      offers: [
        for (final row in asMapList(json['items'])) OfferModel.fromJson(row),
      ],
    );
  }
}

/// The body of `POST /vendor/offers`; `ends_at` is a date, as the contract
/// writes it.
Map<String, dynamic> createOfferBody(CreateOfferParams params) => {
      'percent': params.percent,
      'scope': params.scope.wire,
      'product_ids': params.productIds,
      'ends_at': params.endsAt.toIso8601String().substring(0, 10),
    };
