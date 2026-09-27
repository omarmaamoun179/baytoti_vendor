import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/entities/offer.dart';
import '../../domain/usecases/offers_usecases.dart';
import 'offers_state.dart';

/// The offers tab: the running offers, and the discount being drafted —
/// kept inside the platform's limits as it is stepped.
class OffersCubit extends BaseCubit<OffersState> {
  final GetOffersUseCase _getOffers;
  final CreateOfferUseCase _createOffer;
  final DeleteOfferUseCase _deleteOffer;

  OffersCubit(this._getOffers, this._createOffer, this._deleteOffer)
      : super(OffersState(
          endsAt: DateTime.now().add(OffersState.defaultRun),
        ));

  Future<void> load() async {
    if (state.overview == null) {
      emit(state.copyWith(status: OffersStatus.loading));
    }

    final result = await _getOffers(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: state.overview == null
            ? OffersStatus.error
            : OffersStatus.loaded,
        errorMessage: failure.message,
      )),
      (overview) => emit(state.copyWith(
        status: OffersStatus.loaded,
        overview: overview,
        percent: overview.limits.stepped(state.percent, 0),
      )),
    );
  }

  /// One step down (−1) or up (+1).
  void stepPercent(int direction) {
    final limits = state.overview?.limits ?? const OfferLimits();
    emit(state.copyWith(percent: limits.stepped(state.percent, direction)));
  }

  void setEndsAt(DateTime endsAt) => emit(state.copyWith(endsAt: endsAt));

  Future<void> publish() async {
    final overview = state.overview;
    if (overview == null || state.isCreating) return;

    emit(state.copyWith(actionStatus: OfferActionStatus.creating));

    final result = await _createOffer(CreateOfferParams(
      percent: state.percent,
      endsAt: state.endsAt,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: OfferActionStatus.failed,
        errorMessage: failure.message,
      )),
      (offer) => emit(state.copyWith(
        actionStatus: OfferActionStatus.created,
        overview: OffersOverview(
          limits: overview.limits,
          offers: [offer, ...overview.offers],
        ),
      )),
    );
  }

  /// Ends [offer]. The confirmation has already been asked for.
  Future<void> delete(Offer offer) async {
    final overview = state.overview;
    if (overview == null || state.deletingIds.contains(offer.id)) return;

    emit(state.copyWith(deletingIds: {...state.deletingIds, offer.id}));

    final result = await _deleteOffer(offer.id);
    final waiting = {...state.deletingIds}..remove(offer.id);

    result.fold(
      (failure) => emit(state.copyWith(
        deletingIds: waiting,
        actionStatus: OfferActionStatus.failed,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        deletingIds: waiting,
        actionStatus: OfferActionStatus.deleted,
        overview: OffersOverview(
          limits: state.overview!.limits,
          offers: [
            for (final other in state.overview!.offers)
              if (other.id != offer.id) other,
          ],
        ),
      )),
    );
  }
}
