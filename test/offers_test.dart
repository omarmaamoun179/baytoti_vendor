import 'package:baytoti_vendor/core/mock/mock_locale.dart';
import 'package:baytoti_vendor/features/offers/data/datasources/offers_mock_data_source.dart';
import 'package:baytoti_vendor/features/offers/data/repositories/offers_repository_impl.dart';
import 'package:baytoti_vendor/features/offers/domain/entities/offer.dart';
import 'package:baytoti_vendor/features/offers/domain/usecases/offers_usecases.dart';
import 'package:baytoti_vendor/features/offers/presentation/cubit/offers_cubit.dart';
import 'package:baytoti_vendor/features/offers/presentation/cubit/offers_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  test('a discount steps within the limits', () {
    const limits = OfferLimits(minPercent: 5, maxPercent: 70, step: 5);

    expect(limits.stepped(20, 1), 25);
    expect(limits.stepped(5, -1), 5);
    expect(limits.stepped(70, 1), 70);
  });

  group('OffersCubit', () {
    late OffersCubit cubit;

    setUp(() {
      final repository = OffersRepositoryImpl(
        OffersMockDataSource(MockLocale(FakeCacheService())),
      );
      cubit = OffersCubit(
        GetOffersUseCase(repository),
        CreateOfferUseCase(repository),
        DeleteOfferUseCase(repository),
      );
    });

    tearDown(() => cubit.close());

    test('opens on the running offers and a 20% draft', () async {
      await cubit.load();

      expect(cubit.state.overview?.offers, hasLength(2));
      expect(cubit.state.percent, OffersState.initialPercent);
    });

    test('publishing puts the new offer first', () async {
      await cubit.load();
      cubit.stepPercent(1);
      await cubit.publish();

      expect(cubit.state.actionStatus, OfferActionStatus.created);
      expect(cubit.state.overview?.offers.first.percent, 25);
      expect(cubit.state.overview?.atLimit, isTrue);
    });

    test('a fourth offer is refused', () async {
      await cubit.load();
      await cubit.publish();
      await cubit.publish();

      expect(cubit.state.actionStatus, OfferActionStatus.failed);
      expect(cubit.state.errorMessage, 'offer_limit_reached');
      expect(cubit.state.overview?.offers, hasLength(3));
    });

    test('ending an offer takes it off the list', () async {
      await cubit.load();
      final offer = cubit.state.overview!.offers.first;

      await cubit.delete(offer);

      expect(cubit.state.overview?.offers, isNot(contains(offer)));
      expect(cubit.state.deletingIds, isEmpty);
    });
  });
}
