import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../../../core/widgets/dashed_box.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../domain/entities/product_enums.dart';
import '../cubit/product_editor_state.dart';

/// Photos first, as the design puts it: four to a row, the cover ringed in
/// the accent, dashed tiles to add more. Tapping a photo makes it the
/// cover; its corner button takes it off. A photo still going up shows a
/// spinner, a refused one a retry.
class ProductPhotosCard extends StatelessWidget {
  final List<EditorPhoto> photos;
  final VoidCallback onAdd;
  final ValueChanged<String> onMakeCover;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onRetry;

  const ProductPhotosCard({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onMakeCover,
    required this.onRemove,
    required this.onRetry,
  });

  static const int _perRow = 4;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final canAdd = photos.length < ProductRules.maxPhotos;
    // Fill the row the photos end on, and always offer at least one tile.
    final addTiles = !canAdd
        ? 0
        : (_perRow - photos.length % _perRow).clamp(1, _perRow);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsLabel('product_photos'.tr()),
          SizedBox(height: 11.h),
          GridView.count(
            // Without it the grid takes the status bar's inset as padding.
            padding: EdgeInsets.zero,
            crossAxisCount: _perRow,
            mainAxisSpacing: 8.r,
            crossAxisSpacing: 8.r,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < photos.length; i++)
                _buildPhoto(context, photos[i], isCover: i == 0),
              for (var i = 0; i < addTiles; i++) _buildAdd(context),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'product_photos_hint'.tr(),
            style: AppStrings.text105w400Loose.c(p.fg3),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(
    BuildContext context,
    EditorPhoto photo, {
    required bool isCover,
  }) {
    final p = context.palette;
    final radius = BorderRadius.circular(12.r);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: photo.failed
              ? () => onRetry(photo.key)
              : () => onMakeCover(photo.key),
          child: Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
              border: isCover ? Border.all(color: p.accent, width: 2) : null,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkPhoto(source: photo.source, iconSize: 18.r),
                  if (photo.isUploading || photo.failed)
                    ColoredBox(
                      color: p.fg.withValues(alpha: .35),
                      child: Center(
                        child: photo.failed
                            ? AppIcon(AppIcons.refresh, size: 18.r, color: p.surf)
                            : SizedBox.square(
                                dimension: 18.r,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: p.surf,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: -6.r,
          end: -6.r,
          child: _buildRemove(context, photo.key),
        ),
      ],
    );
  }

  Widget _buildRemove(BuildContext context, String key) {
    final p = context.palette;

    return Semantics(
      button: true,
      label: 'product_photo_remove'.tr(),
      child: GestureDetector(
        onTap: () => onRemove(key),
        child: Container(
          width: 22.r,
          height: 22.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.surf,
            shape: BoxShape.circle,
            border: Border.all(color: p.line),
            boxShadow: p.cardShadow,
          ),
          child: AppIcon(AppIcons.close, size: 10.r, color: p.fg2),
        ),
      ),
    );
  }

  Widget _buildAdd(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      label: 'product_photo_add'.tr(),
      child: GestureDetector(
        onTap: onAdd,
        child: DashedBox(
          color: p.disabled,
          radius: 12.r,
          child: Center(
            child: Text('+', style: AppStrings.text18w800.c(p.fg3)),
          ),
        ),
      ),
    );
  }
}
