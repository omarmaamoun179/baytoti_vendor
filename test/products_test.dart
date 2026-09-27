import 'package:baytoti_vendor/core/domain/failure.dart';
import 'package:baytoti_vendor/core/mock/mock_locale.dart';
import 'package:baytoti_vendor/features/products/data/datasources/product_fixtures.dart';
import 'package:baytoti_vendor/features/products/data/datasources/products_mock_data_source.dart';
import 'package:baytoti_vendor/features/products/data/repositories/products_repository_impl.dart';
import 'package:baytoti_vendor/features/products/domain/entities/product_enums.dart';
import 'package:baytoti_vendor/features/products/domain/usecases/products_usecases.dart';
import 'package:baytoti_vendor/features/products/presentation/cubit/product_editor_cubit.dart';
import 'package:baytoti_vendor/features/products/presentation/cubit/product_editor_state.dart';
import 'package:baytoti_vendor/features/products/presentation/cubit/products_cubit.dart';
import 'package:baytoti_vendor/features/uploads/domain/entities/uploaded_image.dart';
import 'package:baytoti_vendor/features/uploads/domain/repositories/uploads_repository.dart';
import 'package:baytoti_vendor/features/uploads/domain/usecases/upload_image_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// Uploads that answer at once, or refuse.
class _Uploads implements UploadsRepository {
  final bool refuse;
  int _sequence = 0;

  _Uploads({this.refuse = false});

  @override
  Future<Either<Failure, UploadedImage>> uploadImage(String localPath) async =>
      refuse
          ? const Left(ServerFailure(message: 'upload_failed'))
          : Right(UploadedImage(uploadId: 'upl_${++_sequence}', url: localPath));
}

void main() {
  late ProductFixtures fixtures;
  late ProductsMockDataSource source;
  late ProductsRepositoryImpl repository;

  setUp(() {
    fixtures = ProductFixtures();
    source = ProductsMockDataSource(fixtures, MockLocale(FakeCacheService()));
    repository = ProductsRepositoryImpl(source);
  });

  String? refusal(Either<Failure, Object?> result) =>
      result.fold((f) => f.message, (_) => null);

  group('the catalogue fixtures', () {
    test('nothing goes on sale before review', () async {
      expect(
        refusal(await source.setVisibility('prd_5', published: true)),
        'product_pending_review',
        reason: 'a draft',
      );
      expect(
        refusal(await source.setVisibility('prd_9', published: true)),
        'product_pending_review',
        reason: 'in review',
      );
    });

    test('an empty product stays hidden', () async {
      expect(
        refusal(await source.setVisibility('prd_3', published: true)),
        'product_out_of_stock_publish',
      );
    });

    test('a published product hides and shows again', () async {
      final hidden = (await source.setVisibility('prd_1', published: false))
          .getOrElse(() => throw 'failed');
      expect(hidden.state, ProductState.hidden);
      expect(hidden.isLive, isFalse);

      final shown = (await source.setVisibility('prd_1', published: true))
          .getOrElse(() => throw 'failed');
      expect(shown.isLive, isTrue);
    });

    test('search matches either language', () async {
      final ar = (await source.getProducts(search: 'كيك'))
          .getOrElse(() => throw 'failed');
      final en = (await source.getProducts(search: 'cake'))
          .getOrElse(() => throw 'failed');

      expect(ar.items.map((p) => p.id), ['prd_1']);
      expect(en.items.map((p) => p.id), ['prd_1']);
    });
  });

  group('ProductsCubit', () {
    test('a refused switch keeps the row and says why', () async {
      final cubit = ProductsCubit(
        GetProductsUseCase(repository),
        SetProductVisibilityUseCase(repository),
      );
      addTearDown(cubit.close);
      await cubit.load();

      final draft = cubit.state.products.firstWhere((p) => p.id == 'prd_5');
      await cubit.toggleVisibility(draft);

      final after = cubit.state.products.firstWhere((p) => p.id == 'prd_5');
      expect(after.state, ProductState.draft);
      expect(cubit.state.errorMessage, 'product_pending_review');
      expect(cubit.state.togglingIds, isEmpty);
    });
  });

  group('ProductEditorCubit', () {
    ProductEditorCubit build({bool refuseUploads = false}) =>
        ProductEditorCubit(
          GetCategoriesUseCase(repository),
          GetProductUseCase(repository),
          UploadImageUseCase(_Uploads(refuse: refuseUploads)),
          SaveProductUseCase(repository),
        );

    const values = ProductFormValues(
      name: 'غريبة بالهيل',
      categoryId: 'cat_sweets',
      priceFils: 4500,
      stock: 10,
      preparationTime: PreparationTime.oneDay,
      description: 'تذوب في الفم.',
    );

    test('opens a new product with the categories to choose from', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load(null);

      expect(cubit.state.status, ProductEditorStatus.ready);
      expect(cubit.state.isNew, isTrue);
      expect(cubit.state.categories, hasLength(6));
    });

    test('review wants a photo; a draft does not', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load(null);

      await cubit.save(values, submitForReview: true);
      expect(cubit.state.saveStatus, ProductSaveStatus.failed);
      expect(cubit.state.errorMessage, 'product_photo_required');

      await cubit.save(values, submitForReview: false);
      expect(cubit.state.saveStatus, ProductSaveStatus.saved);
      expect(cubit.state.saved?.state, ProductState.draft);
    });

    test('a photo refused on the way up blocks the save', () async {
      final cubit = build(refuseUploads: true);
      addTearDown(cubit.close);
      await cubit.load(null);

      await cubit.addPhotos(['/tmp/a.jpg']);
      expect(cubit.state.photos.single.failed, isTrue);

      await cubit.save(values, submitForReview: false);
      expect(cubit.state.errorMessage, 'product_photos_failed');
    });

    test('sent for review with photos, the product joins the list', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load(null);

      await cubit.addPhotos(['/tmp/a.jpg', '/tmp/b.jpg']);
      cubit.makeCover(cubit.state.photos.last.key);
      expect(cubit.state.photos.first.source, '/tmp/b.jpg');

      await cubit.save(values, submitForReview: true);
      expect(cubit.state.saved?.state, ProductState.pendingReview);

      final created = fixtures.products.first;
      expect(created.name.ar, 'غريبة بالهيل');
      expect(created.photos.first.url, '/tmp/b.jpg');
    });

    test('editing starts from the product as saved', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load('prd_1');

      expect(cubit.state.isNew, isFalse);
      expect(cubit.state.product?.priceFils, 4250);
      expect(cubit.state.product?.categoryId, 'cat_sweets');
    });
  });
}
