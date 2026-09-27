import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../domain/entities/store_profile.dart';

/// The family's documents and where each stands — green once verified,
/// amber while in review.
class VerificationCard extends StatelessWidget {
  final List<StoreDocument> documents;

  const VerificationCard({super.key, required this.documents});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsLabel('store_verification'.tr()),
          SizedBox(height: 6.h),
          for (var i = 0; i < documents.length; i++)
            _buildRow(context, documents[i], last: i == documents.length - 1),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    StoreDocument document, {
    required bool last,
  }) {
    final p = context.palette;
    final (dot, ink, key) = switch (document.state) {
      DocumentState.verified => (p.accent, p.accentInk, 'document_verified'),
      DocumentState.inReview => (p.amber, p.amberInk, 'document_in_review'),
      DocumentState.rejected => (p.bad, p.bad, 'document_rejected'),
      DocumentState.missing => (p.line2, p.fg3, 'document_missing'),
    };

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 20.r,
            height: 20.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            child: AppIcon(AppIcons.check, size: 11.r, color: p.onAccent),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(document.label, style: AppStrings.text12w600.c(p.fg)),
          ),
          Text(key.tr(), style: AppStrings.text105w800.c(ink)),
        ],
      ),
    );
  }
}
