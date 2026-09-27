import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/money.dart';
import '../../../../core/utils/validators/validator_messages.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/caps_label.dart';
import '../../../../core/widgets/pill_chip.dart';
import '../../domain/entities/product_enums.dart';
import '../../domain/entities/vendor_product.dart';
import '../cubit/product_editor_state.dart';
import 'stepper_field.dart';

/// The product's own fields, in the design's order: name, category, price
/// and stock, preparation time, description.
///
/// Holds its controllers; the page reaches it through a
/// `GlobalKey<ProductFormState>` and asks [ProductFormState.submit] for the
/// values when a button in the bar is pressed.
class ProductForm extends StatefulWidget {
  final List<ProductCategory> categories;

  /// Fills the fields when editing.
  final VendorProduct? product;

  /// Told on the first edit, for the "discard changes?" guard.
  final VoidCallback onChanged;

  const ProductForm({
    super.key,
    required this.categories,
    this.product,
    required this.onChanged,
  });

  @override
  State<ProductForm> createState() => ProductFormState();
}

class ProductFormState extends State<ProductForm> {
  /// The design's starting values for a new product.
  static const int _defaultPriceFils = 4500;
  static const int _defaultStock = 10;

  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.product?.name);
  late final _description =
      TextEditingController(text: widget.product?.description);
  late final _price = TextEditingController(
    text: Money.amount(widget.product?.priceFils ?? _defaultPriceFils),
  );
  late final _stock = TextEditingController(
    text: '${widget.product?.stock ?? _defaultStock}',
  );

  late String? _categoryId =
      widget.product?.categoryId ?? widget.categories.firstOrNull?.id;
  late PreparationTime _preparation =
      widget.product?.preparationTime ?? PreparationTime.oneDay;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  /// The fields' values, or null when one needs fixing — the field says
  /// which.
  ProductFormValues? submit() {
    FocusScope.of(context).unfocus();
    _settlePrice();
    _settleStock();

    final valid = _formKey.currentState?.validate() ?? false;
    final categoryId = _categoryId;
    if (!valid || categoryId == null) return null;

    return ProductFormValues(
      name: _name.text.trim(),
      categoryId: categoryId,
      priceFils: _priceFils,
      stock: int.tryParse(_stock.text) ?? 0,
      preparationTime: _preparation,
      description: _description.text.trim(),
    );
  }

  int get _priceFils => Money.parseFils(_price.text) ?? ProductRules.minPriceFils;

  void _stepPrice(int direction) {
    final next = (_priceFils + direction * ProductRules.priceStepFils)
        .clamp(ProductRules.minPriceFils, ProductRules.maxPriceFils);
    _price.text = Money.amount(next);
    widget.onChanged();
  }

  void _stepStock(int direction) {
    final current = int.tryParse(_stock.text) ?? 0;
    _stock.text = '${(current + direction).clamp(0, ProductRules.maxStock)}';
    widget.onChanged();
  }

  /// Puts a typed price back inside the limits, in the three decimals KWD
  /// is written with.
  void _settlePrice() => _price.text = Money.amount(
        _priceFils.clamp(ProductRules.minPriceFils, ProductRules.maxPriceFils),
      );

  void _settleStock() => _stock.text =
      '${(int.tryParse(_stock.text) ?? 0).clamp(0, ProductRules.maxStock)}';

  void _choose(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      onChanged: widget.onChanged,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'product_name'.tr(),
              hintText: 'product_name_hint'.tr(),
              controller: _name,
              maxLength: ProductRules.nameMaxLength,
              textInputAction: TextInputAction.next,
              validator: (value) => validateTextLength(
                value,
                minLength: ProductRules.nameMinLength,
                maxLength: ProductRules.nameMaxLength,
                isRequired: true,
              ),
            ),
            SizedBox(height: 16.h),
            _buildCategories(),
            SizedBox(height: 16.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StepperField(
                    label: 'product_price'.tr(),
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,6}([.,]\d{0,3})?'),
                      ),
                    ],
                    onDecrement: () => _stepPrice(-1),
                    onIncrement: () => _stepPrice(1),
                    onEditingDone: _settlePrice,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: StepperField(
                    label: 'product_stock'.tr(),
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    onDecrement: () => _stepStock(-1),
                    onIncrement: () => _stepStock(1),
                    onEditingDone: _settleStock,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            CapsLabel('product_preparation'.tr()),
            SizedBox(height: 8.h),
            Row(
              children: [
                for (final time in PreparationTime.values) ...[
                  if (time != PreparationTime.values.first) SizedBox(width: 7.w),
                  PillChip(
                    label: _preparationKey(time).tr(),
                    selected: time == _preparation,
                    expand: true,
                    onPressed: () => _choose(() => _preparation = time),
                  ),
                ],
              ],
            ),
            SizedBox(height: 16.h),
            AppTextField(
              label: 'product_description'.tr(),
              hintText: 'product_description_hint'.tr(),
              controller: _description,
              multiline: true,
              maxLength: ProductRules.descriptionMaxLength,
              validator: (value) => validateTextLength(
                value,
                maxLength: ProductRules.descriptionMaxLength,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return FormField<String>(
      validator: (_) =>
          _categoryId == null ? 'product_category_required'.tr() : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CapsLabel('product_category'.tr()),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 7.w,
            runSpacing: 7.h,
            children: [
              for (final category in widget.categories)
                PillChip(
                  label: category.name,
                  selected: category.id == _categoryId,
                  onPressed: () => _choose(() => _categoryId = category.id),
                ),
            ],
          ),
          if (field.errorText != null) ...[
            SizedBox(height: 6.h),
            Text(
              field.errorText!,
              style: Theme.of(context).inputDecorationTheme.errorStyle,
            ),
          ],
        ],
      ),
    );
  }

  static String _preparationKey(PreparationTime time) => switch (time) {
        PreparationTime.sameDay => 'preparation_same_day',
        PreparationTime.oneDay => 'preparation_24h',
        PreparationTime.twoToThreeDays => 'preparation_2_3_days',
      };
}
