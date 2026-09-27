import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/json_read.dart';
import '../../domain/entities/vendor_application.dart';

/// Where a family's review stands. The fixtures answer in the design
/// contract's `GET /vendor/application` shape, read by [fromJson]:
///
/// ```json
/// {"state": "under_review",
///  "steps": [{"key": "account_created", "label": "إنشاء الحساب",
///             "done": true}, …],
///  "review_sla_display": "من يوم إلى ثلاثة أيام عمل"}
/// ```
///
/// `family_name` is not in the contract's example; it is read when sent.
/// The live API is read by [VendorApplicationModel.fromProfile].
class VendorApplicationModel extends VendorApplication {
  const VendorApplicationModel({
    required super.status,
    super.familyName,
    super.steps,
    super.reviewSla,
  });

  factory VendorApplicationModel.fromJson(Map<String, dynamic> json) {
    return VendorApplicationModel(
      status: ReviewStatus.fromWire(asString(json['state'])),
      familyName: asString(json['family_name']),
      steps: [
        for (final step in asMapList(json['steps']))
          if (asString(step['key']) case final key?)
            ApplicationStep(
              key: key,
              label: asString(step['label']) ?? key,
              done: asBool(step['done']) ?? false,
            ),
      ],
      reviewSla: asString(json['review_sla_display']),
    );
  }

  /// The live API has no application endpoint: where the review stands is
  /// the `status` of `GET /vendor/profile` (`VendorProfileResource`):
  ///
  /// ```json
  /// {"id": "7", "account": {"id": "23", "name": "…", "email": "…",
  ///                         "phone": "96551502244", "avatar": null},
  ///  "business": {"name": "أسرة أم عبدالله", "phone": null, "email": null,
  ///               "address": null},
  ///  "status": "pending"}
  /// ```
  ///
  /// The spec types `status` only as a nullable string, so the words a
  /// Laravel review column uses are read ([_reviewFrom]). The timeline is
  /// the app's own, drawn from that one status; the server sends no steps.
  factory VendorApplicationModel.fromProfile(Map<String, dynamic> json) {
    final business = asMap(json['business']);
    final account = asMap(json['account']);
    final status = _reviewFrom(asString(json['status']));
    final approved = status == ReviewStatus.approved;

    return VendorApplicationModel(
      status: status,
      familyName: asString(business['name']) ?? asString(account['name']),
      steps: [
        ApplicationStep(
          key: 'account_created',
          label: 'application_step_account_created'.tr(),
          done: true,
        ),
        ApplicationStep(
          key: 'documents_review',
          label: 'application_step_documents_review'.tr(),
          done: status != ReviewStatus.draft,
        ),
        ApplicationStep(
          key: 'approved',
          label: 'application_step_approved'.tr(),
          done: approved,
        ),
        ApplicationStep(
          key: 'first_product',
          label: 'application_step_first_product'.tr(),
          done: false,
        ),
      ],
    );
  }

  /// `active` and `approved` open the store. An absent or unknown value
  /// holds the family at the gate, as [ReviewStatus.fromWire] does: letting
  /// an unreviewed family sell is the mistake that cannot be taken back, and
  /// the server stays the authority on every vendor call either way.
  static ReviewStatus _reviewFrom(String? value) =>
      switch (value?.trim().toLowerCase()) {
        'approved' || 'active' || 'verified' => ReviewStatus.approved,
        'rejected' ||
        'declined' ||
        'suspended' ||
        'blocked' ||
        'banned' =>
          ReviewStatus.rejected,
        'draft' || 'incomplete' => ReviewStatus.draft,
        _ => ReviewStatus.underReview,
      };
}
