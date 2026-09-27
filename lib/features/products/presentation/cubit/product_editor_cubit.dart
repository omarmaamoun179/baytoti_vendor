import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../../../uploads/domain/usecases/upload_image_usecase.dart';
import '../../domain/entities/product_enums.dart';
import '../../domain/entities/vendor_product.dart';
import '../../domain/usecases/products_usecases.dart';
import 'product_editor_state.dart';

/// The product form's server side: what it is filled from, the photos and
/// their uploads, and the save.
///
/// The text fields, steppers and chips live in the form itself; the cubit
/// holds what talks to the server. A photo uploads the moment it is picked
/// — the contract attaches photos by `upload_id` — so a save only waits on
/// the ones still going up.
class ProductEditorCubit extends BaseCubit<ProductEditorState> {
  final GetCategoriesUseCase _getCategories;
  final GetProductUseCase _getProduct;
  final UploadImageUseCase _uploadImage;
  final SaveProductUseCase _saveProduct;

  int _photoSequence = 0;

  ProductEditorCubit(
    this._getCategories,
    this._getProduct,
    this._uploadImage,
    this._saveProduct,
  ) : super(const ProductEditorState());

  /// Reads the categories, and [productId] when editing, together.
  Future<void> load(String? productId) async {
    emit(state.copyWith(status: ProductEditorStatus.loading));

    final categories = _getCategories(NoParams());
    final Future<Either<Failure, VendorProduct?>> product = productId == null
        ? Future.value(const Right(null))
        : _getProduct(productId);

    final categoriesResult = await categories;
    final productResult = await product;

    final failure = categoriesResult.fold((f) => f, (_) => null) ??
        productResult.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(state.copyWith(
        status: ProductEditorStatus.error,
        errorMessage: failure.message,
      ));
      return;
    }

    // `fold`, not `getOrElse`: the right side is a model at runtime, and a
    // default typed as the entity does not fit its slot.
    final loaded = productResult.fold((_) => null, (product) => product);
    emit(state.copyWith(
      status: ProductEditorStatus.ready,
      categories: categoriesResult.fold(
        (_) => const <ProductCategory>[],
        (categories) => categories,
      ),
      product: loaded,
      photos: [
        for (final photo in loaded?.photos ?? const <ProductPhoto>[])
          EditorPhoto(
            key: photo.uploadId,
            source: photo.url,
            uploadId: photo.uploadId,
          ),
      ],
    ));
  }

  /// Adds photos picked from the gallery, up to [ProductRules.maxPhotos],
  /// and uploads each.
  Future<void> addPhotos(List<String> paths) async {
    final room = ProductRules.maxPhotos - state.photos.length;
    final added = [
      for (final path in paths.take(room))
        EditorPhoto(key: 'local_${++_photoSequence}', source: path),
    ];
    if (added.isEmpty) return;

    emit(state.copyWith(
      photos: [...state.photos, ...added],
      photosChanged: true,
    ));
    await Future.wait(added.map(_upload));
  }

  /// Tries a refused photo again.
  Future<void> retryPhoto(String key) async {
    final photo = _photo(key);
    if (photo == null || !photo.failed) return;

    final pending = EditorPhoto(key: key, source: photo.source);
    emit(state.copyWith(photos: _with(pending)));
    await _upload(pending);
  }

  void removePhoto(String key) => emit(state.copyWith(
        photos: [for (final p in state.photos) if (p.key != key) p],
        photosChanged: true,
      ));

  /// The first photo is the cover.
  void makeCover(String key) {
    final photo = _photo(key);
    if (photo == null || state.photos.first.key == key) return;

    emit(state.copyWith(
      photos: [photo, for (final p in state.photos) if (p.key != key) p],
      photosChanged: true,
    ));
  }

  /// Saves [values] with the photos as a draft, or sends it all to review.
  /// Review wants at least one photo; a draft does not.
  Future<void> save(
    ProductFormValues values, {
    required bool submitForReview,
  }) async {
    if (state.isSaving) return;

    final problem = state.isUploading
        ? 'product_photos_uploading'
        : state.photos.any((photo) => photo.failed)
            ? 'product_photos_failed'
            : submitForReview && state.photos.isEmpty
                ? 'product_photo_required'
                : null;
    if (problem != null) {
      emit(state.copyWith(
        saveStatus: ProductSaveStatus.failed,
        errorMessage: problem.tr(),
      ));
      return;
    }

    emit(state.copyWith(
      saveStatus: submitForReview
          ? ProductSaveStatus.submitting
          : ProductSaveStatus.savingDraft,
    ));

    final result = await _saveProduct(SaveProductParams(
      productId: state.product?.id,
      draft: ProductDraft(
        name: values.name,
        categoryId: values.categoryId,
        priceFils: values.priceFils,
        isAvailable: values.isAvailable,
        preparationTime: values.preparationTime,
        description: values.description,
        photos: [
          for (final photo in state.photos)
            ProductPhoto(uploadId: photo.uploadId!, url: photo.source),
        ],
        submitForReview: submitForReview,
      ),
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        saveStatus: ProductSaveStatus.failed,
        errorMessage: failure.message,
        fieldErrors:
            failure is ValidationFailure ? failure.fieldErrors : const {},
      )),
      (saved) => emit(state.copyWith(
        saveStatus: ProductSaveStatus.saved,
        saved: saved,
      )),
    );
  }

  Future<void> _upload(EditorPhoto photo) async {
    final result = await _uploadImage(photo.source);

    // Removed while it was going up.
    if (_photo(photo.key) == null) return;

    result.fold(
      (failure) => emit(state.copyWith(
        photos: _with(EditorPhoto(
          key: photo.key,
          source: photo.source,
          failed: true,
        )),
        errorMessage: failure.message,
      )),
      (uploaded) => emit(state.copyWith(
        photos: _with(EditorPhoto(
          key: photo.key,
          // A local file keeps drawing from the device; the URL is the
          // server's copy of the same picture.
          source: photo.source,
          uploadId: uploaded.uploadId,
        )),
      )),
    );
  }

  EditorPhoto? _photo(String key) {
    for (final photo in state.photos) {
      if (photo.key == key) return photo;
    }
    return null;
  }

  List<EditorPhoto> _with(EditorPhoto updated) => [
        for (final photo in state.photos)
          photo.key == updated.key ? updated : photo,
      ];
}
