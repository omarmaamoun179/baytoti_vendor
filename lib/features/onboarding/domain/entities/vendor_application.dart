import 'package:equatable/equatable.dart';

/// Where a family's application stands — the contract's `state`.
enum ReviewStatus {
  draft('draft'),
  underReview('under_review'),
  approved('approved'),
  rejected('rejected');

  const ReviewStatus(this.wire);

  final String wire;

  /// An unknown value reads as [underReview]: holding a family at the gate
  /// is recoverable, letting an unreviewed one sell is not.
  static ReviewStatus fromWire(String? value) => values.firstWhere(
        (state) => state.wire == value,
        orElse: () => underReview,
      );
}

/// One step of the approval path, as the server lists it.
class ApplicationStep extends Equatable {
  /// `account_created`, `documents_review`, `approved`, `first_product`.
  final String key;

  /// Already in the app's language.
  final String label;

  final bool done;

  const ApplicationStep({
    required this.key,
    required this.label,
    required this.done,
  });

  @override
  List<Object?> get props => [key, label, done];
}

/// `GET /vendor/application`. Every other vendor endpoint answers
/// `403 vendor_not_approved` until [status] is [ReviewStatus.approved].
class VendorApplication extends Equatable {
  final ReviewStatus status;

  /// The family the application is for, when the server names it.
  final String? familyName;

  final List<ApplicationStep> steps;

  /// "one to three working days", in the app's language.
  final String? reviewSla;

  const VendorApplication({
    required this.status,
    this.familyName,
    this.steps = const [],
    this.reviewSla,
  });

  bool get isApproved => status == ReviewStatus.approved;

  @override
  List<Object?> get props => [status, familyName, steps, reviewSla];
}
