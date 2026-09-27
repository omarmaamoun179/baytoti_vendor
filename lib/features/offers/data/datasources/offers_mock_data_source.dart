import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/mock/mock_locale.dart';
import '../../../../core/network/guarded_request.dart';
import '../../domain/entities/offer.dart';
import '../models/offer_models.dart';
import 'offers_data_source.dart';

class _OfferRecord {
  final String id;
  final int percent;
  final OfferScope scope;
  final Localized scopeLabel;
  final DateTime startsAt;
  final DateTime endsAt;
  final int redemptionCount;

  const _OfferRecord(
    this.id,
    this.percent,
    this.scope,
    this.scopeLabel,
    this.startsAt,
    this.endsAt,
    this.redemptionCount,
  );
}

/// The design's two running offers, and the contract's limits: 5–70% in
/// steps of 5, three at a time. It refuses what the server would — a
/// percentage outside the limits, a fourth offer, an end in the past.
class OffersMockDataSource implements OffersDataSource {
  static const Map<String, int> _limits = {
    'min_percent': 5,
    'max_percent': 70,
    'step': 5,
    'max_active': 3,
  };

  static const Localized _allProducts = Localized('كل المنتجات', 'All products');

  final MockLocale _locale;
  final DateTime _now = DateTime.now();
  int _sequence = 3;

  late final List<_OfferRecord> _offers = [
    _OfferRecord(
      'off_3',
      15,
      OfferScope.all,
      _allProducts,
      _now.subtract(const Duration(days: 7)),
      _now.add(const Duration(days: 3)),
      42,
    ),
    _OfferRecord(
      'off_2',
      25,
      OfferScope.category,
      const Localized('الحلويات فقط', 'Sweets only'),
      _now.subtract(const Duration(days: 2)),
      _now.add(const Duration(days: 3)),
      8,
    ),
  ];

  OffersMockDataSource(this._locale);

  @override
  Future<Either<Failure, OffersOverviewModel>> getOffers() => guardedRequest(
        'OffersMockDataSource.getOffers',
        () async {
          await Future<void>.delayed(mockLatency);
          final ar = await _locale.isArabic();

          return OffersOverviewModel.fromJson({
            'limits': _limits,
            'items': [for (final offer in _offers) _json(offer, ar)],
          });
        },
        fallbackMessage: 'offers_failed',
      );

  @override
  Future<Either<Failure, OfferModel>> createOffer(CreateOfferParams params) =>
      guardedRequest(
        'OffersMockDataSource.createOffer',
        () async {
          await Future<void>.delayed(mockLatency);

          final percent = params.percent;
          final inLimits = percent >= _limits['min_percent']! &&
              percent <= _limits['max_percent']! &&
              percent % _limits['step']! == 0;
          if (!inLimits) {
            throw const RequestException(
              'offer_percent_invalid',
              statusCode: 422,
            );
          }
          if (_offers.length >= _limits['max_active']!) {
            throw const RequestException(
              'offer_limit_reached',
              statusCode: 422,
            );
          }
          if (!params.endsAt.isAfter(DateTime.now())) {
            throw const RequestException('offer_end_past', statusCode: 422);
          }

          final offer = _OfferRecord(
            'off_${++_sequence}',
            percent,
            params.scope,
            _allProducts,
            DateTime.now(),
            params.endsAt,
            0,
          );
          _offers.insert(0, offer);
          return OfferModel.fromJson(_json(offer, await _locale.isArabic()));
        },
        fallbackMessage: 'offer_create_failed',
      );

  @override
  Future<Either<Failure, Unit>> deleteOffer(String id) => guardedRequest(
        'OffersMockDataSource.deleteOffer',
        () async {
          await Future<void>.delayed(mockLatency);

          final before = _offers.length;
          _offers.removeWhere((offer) => offer.id == id);
          if (_offers.length == before) {
            throw const RequestException('offer_not_found', statusCode: 404);
          }
          return unit;
        },
        fallbackMessage: 'offer_delete_failed',
      );

  Map<String, dynamic> _json(_OfferRecord offer, bool ar) => {
        'id': offer.id,
        'percent': offer.percent,
        'scope': offer.scope.wire,
        'scope_label': offer.scopeLabel.pick(ar),
        'starts_at': offer.startsAt.toIso8601String(),
        'ends_at': offer.endsAt.toIso8601String(),
        'redemption_count': offer.redemptionCount,
      };
}
