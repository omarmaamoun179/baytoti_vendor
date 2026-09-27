import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/vendor_application.dart';

/// The approval path as a vertical timeline: a dot per step, filled once
/// done, joined by a line that turns green as the next step is reached.
///
/// Labels are the server's; the line under each is the app's, for the steps
/// it knows.
class ApprovalTimeline extends StatelessWidget {
  final List<ApplicationStep> steps;

  const ApprovalTimeline({super.key, required this.steps});

  static const Map<String, String> _detailKeys = {
    'account_created': 'step_account_created',
    'documents_review': 'step_documents_review',
    'approved': 'step_approved',
    'first_product': 'step_first_product',
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 4.h),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _buildStep(
              context,
              steps[i],
              isLast: i == steps.length - 1,
              nextDone: i + 1 < steps.length && steps[i + 1].done,
            ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    ApplicationStep step, {
    required bool isLast,
    required bool nextDone,
  }) {
    final p = context.palette;
    final detailKey = _detailKeys[step.key];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 16.r,
                height: 16.r,
                decoration: BoxDecoration(
                  color: step.done ? p.accent : p.bg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: step.done ? p.accent : p.line2,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    constraints: BoxConstraints(minHeight: 24.h),
                    color: nextDone ? p.accent : p.muted,
                  ),
                ),
            ],
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: AppStrings.text13w800.c(step.done ? p.fg : p.fg3),
                  ),
                  if (detailKey != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      detailKey.tr(),
                      style: AppStrings.text11w400Loose.c(p.fg3),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
