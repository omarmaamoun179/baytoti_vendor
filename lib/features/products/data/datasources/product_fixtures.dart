import '../../../../core/mock/mock_locale.dart';
import '../../domain/entities/product_enums.dart';
import '../../domain/entities/vendor_product.dart';

/// A fixture product as the fake backend holds it.
class ProductRecord {
  final String id;
  Localized name;
  String categoryId;
  int priceFils;
  bool isAvailable;
  PreparationTime preparationTime;
  Localized description;
  List<ProductPhoto> photos;
  ProductState state;

  /// The family's switch — the API's `status` — kept apart from [state]'s
  /// review, as the server keeps it. On for a published product unless
  /// said otherwise.
  bool switchedOn;

  ProductRecord({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.priceFils,
    this.isAvailable = true,
    required this.state,
    bool? switchedOn,
    this.preparationTime = PreparationTime.oneDay,
    this.description = const Localized('', ''),
    this.photos = const [],
  }) : switchedOn = switchedOn ?? state == ProductState.published;
}

/// The fixture catalogue — the design's five products and five more, one
/// in each review state — and the categories they are filed under.
///
/// Held for the run, and shared by the products and dashboard fixtures so
/// the dashboard's "not available" counts the same products the list shows.
class ProductFixtures {
  static const List<(String, Localized)> categories = [
    ('cat_sweets', Localized('حلويات', 'Sweets')),
    ('cat_bakery', Localized('مخبوزات', 'Bakery')),
    ('cat_spices', Localized('بهارات', 'Spices')),
    ('cat_crafts', Localized('حرف يدوية', 'Crafts')),
    ('cat_perfume', Localized('عطور', 'Perfume')),
    ('cat_savoury', Localized('مأكولات', 'Savoury')),
  ];

  int _sequence = 10;

  String nextId() => 'prd_${++_sequence}';

  late final List<ProductRecord> products = [
    ProductRecord(
      id: 'prd_1',
      name: const Localized('كيك التمر بالهيل', 'Cardamom date cake'),
      categoryId: 'cat_sweets',
      priceFils: 4250,
      state: ProductState.published,
      description: const Localized(
        'كيك تمر طري بالهيل والزعفران، يكفي ستة أشخاص. يحفظ في الثلاجة ثلاثة أيام.',
        'Soft date cake with cardamom and saffron, serves six. Keeps three '
            'days in the fridge.',
      ),
    ),
    ProductRecord(
      id: 'prd_2',
      name: const Localized('درابيل محشية', 'Filled darabeel'),
      categoryId: 'cat_sweets',
      priceFils: 2750,
      state: ProductState.published,
      preparationTime: PreparationTime.sameDay,
    ),
    ProductRecord(
      id: 'prd_3',
      name: const Localized('كنافة بالقشطة', 'Cream kunafa'),
      categoryId: 'cat_sweets',
      priceFils: 5500,
      isAvailable: false,
      // Hidden by the family while it cannot be ordered.
      state: ProductState.hidden,
    ),
    ProductRecord(
      id: 'prd_4',
      name: const Localized('معمول بالتمر', 'Date maamoul'),
      categoryId: 'cat_sweets',
      priceFils: 3900,
      state: ProductState.published,
    ),
    ProductRecord(
      id: 'prd_5',
      name: const Localized('صندوق ضيافة', 'Hospitality box'),
      categoryId: 'cat_sweets',
      priceFils: 12000,
      state: ProductState.draft,
      preparationTime: PreparationTime.twoToThreeDays,
    ),
    ProductRecord(
      id: 'prd_6',
      name: const Localized('زعفران معبأ يدوياً', 'Hand-packed saffron'),
      categoryId: 'cat_spices',
      priceFils: 6750,
      state: ProductState.published,
      preparationTime: PreparationTime.sameDay,
    ),
    ProductRecord(
      id: 'prd_7',
      name: const Localized('وسادة سدو مطرزة', 'Embroidered Sadu cushion'),
      categoryId: 'cat_crafts',
      priceFils: 9500,
      state: ProductState.published,
      preparationTime: PreparationTime.twoToThreeDays,
    ),
    ProductRecord(
      id: 'prd_8',
      name: const Localized('خبز التنور الطازج', 'Fresh tanoor bread'),
      categoryId: 'cat_bakery',
      priceFils: 1500,
      state: ProductState.published,
      preparationTime: PreparationTime.sameDay,
    ),
    ProductRecord(
      id: 'prd_9',
      name: const Localized('بهار الكبسة المنزلي', 'House kabsa spice'),
      categoryId: 'cat_spices',
      priceFils: 1900,
      state: ProductState.pendingReview,
    ),
    ProductRecord(
      id: 'prd_10',
      name: const Localized('دهن ورد طائفي', 'Taif rose oil'),
      categoryId: 'cat_perfume',
      priceFils: 8000,
      state: ProductState.rejected,
    ),
  ];

  ProductRecord? find(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }
}
