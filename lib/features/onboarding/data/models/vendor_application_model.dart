import '../../../../core/utils/json_read.dart';
import '../../domain/entities/vendor_application.dart';

/// `GET /vendor/application`:
///
/// ```json
/// {"state": "under_review",
///  "steps": [{"key": "account_created", "label": "إنشاء الحساب",
///             "done": true}, …],
///  "review_sla_display": "من يوم إلى ثلاثة أيام عمل"}
/// ```
///
/// `family_name` is not in the contract's example; it is read when sent.
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
}
