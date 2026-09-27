import 'package:equatable/equatable.dart';

import '../../domain/entities/offer.dart';

enum OffersStatus { initial, loading, loaded, error }

/// Creating or ending an offer, apart from the screen's own loading.
enum OfferActionStatus { idle, creating, created, deleted, failed }

class OffersState extends Equatable {
  /// The design's starting discount.
  static const int initialPercent = 20;

  /// How long a new offer runs unless the family picks another end.
  static const Duration defaultRun = Duration(days: 7);

  final OffersStatus status;
  final OffersOverview? overview;

  /// The discount being drafted.
  final int percent;

  /// When it ends.
  final DateTime endsAt;

  final OfferActionStatus actionStatus;

  /// Offers whose removal is on its way.
  final Set<String> deletingIds;

  final String? errorMessage;

  const OffersState({
    this.status = OffersStatus.initial,
    this.overview,
    this.percent = initialPercent,
    required this.endsAt,
    this.actionStatus = OfferActionStatus.idle,
    this.deletingIds = const {},
    this.errorMessage,
  });

  bool get isCreating => actionStatus == OfferActionStatus.creating;

  /// [errorMessage] and [actionStatus] belong to one attempt and are cleared
  /// on every copy unless passed again.
  OffersState copyWith({
    OffersStatus? status,
    OffersOverview? overview,
    int? percent,
    DateTime? endsAt,
    OfferActionStatus? actionStatus,
    Set<String>? deletingIds,
    String? errorMessage,
  }) {
    return OffersState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      percent: percent ?? this.percent,
      endsAt: endsAt ?? this.endsAt,
      actionStatus: actionStatus ?? OfferActionStatus.idle,
      deletingIds: deletingIds ?? this.deletingIds,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        overview,
        percent,
        endsAt,
        actionStatus,
        deletingIds,
        errorMessage,
      ];
}
