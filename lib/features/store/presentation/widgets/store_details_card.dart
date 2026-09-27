import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/validators/validator_messages.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../../../core/widgets/pill_chip.dart';
import '../../domain/entities/store_profile.dart';
import '../cubit/store_state.dart';

extension StoreCityLabel on StoreCity {
  String get labelKey => 'city_$wire';
}

/// What the customer reads on the family page: the store's name, the
/// family's story, and its city.
///
/// Holds its controllers; the page reaches it through a
/// `GlobalKey<StoreDetailsCardState>` and asks
/// [StoreDetailsCardState.submit] for the values when saving.
class StoreDetailsCard extends StatefulWidget {
  final StoreProfile store;

  /// Told on every edit, so "Saved" goes back to "Save changes".
  final VoidCallback onChanged;

  const StoreDetailsCard({
    super.key,
    required this.store,
    required this.onChanged,
  });

  @override
  State<StoreDetailsCard> createState() => StoreDetailsCardState();
}

class StoreDetailsCardState extends State<StoreDetailsCard> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.store.name);
  late final _story = TextEditingController(text: widget.store.story);
  late StoreCity? _city = widget.store.city;

  @override
  void dispose() {
    _name.dispose();
    _story.dispose();
    super.dispose();
  }

  /// The fields' values, or null when one needs fixing.
  StoreFormValues? submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return null;
    return StoreFormValues(
      name: _name.text.trim(),
      story: _story.text.trim(),
      city: _city,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Form(
      key: _formKey,
      onChanged: widget.onChanged,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'store_name'.tr(),
              controller: _name,
              style: AppStrings.text14w800,
              maxLength: StoreRules.nameMaxLength,
              validator: (value) => validateTextLength(
                value,
                minLength: StoreRules.nameMinLength,
                maxLength: StoreRules.nameMaxLength,
                isRequired: true,
              ),
            ),
            SizedBox(height: 16.h),
            AppTextField(
              label: 'store_story'.tr(),
              hintText: 'store_story_placeholder'.tr(),
              controller: _story,
              multiline: true,
              minLines: 4,
              maxLength: StoreRules.storyMaxLength,
              validator: (value) => validateTextLength(
                value,
                maxLength: StoreRules.storyMaxLength,
              ),
            ),
            SizedBox(height: 7.h),
            Text(
              'store_story_hint'.tr(),
              style: AppStrings.text105w400.c(p.fg3).copyWith(height: 1.5),
            ),
            SizedBox(height: 16.h),
            CapsLabel('store_city'.tr()),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 7.w,
              runSpacing: 7.h,
              children: [
                for (final city in StoreCity.values)
                  PillChip(
                    label: city.labelKey.tr(),
                    selected: city == _city,
                    onPressed: () {
                      setState(() => _city = city);
                      widget.onChanged();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
