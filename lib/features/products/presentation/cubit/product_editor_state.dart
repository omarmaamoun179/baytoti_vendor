import 'package:equatable/equatable.dart';

import '../../domain/entities/product_enums.dart';
import '../../domain/entities/vendor_product.dart';

enum ProductEditorStatus {
  /// Reading the categories, and the product when editing one.
  loading,

  ready,

  /// The first read failed; nothing to edit.
  error,
}

enum ProductSaveStatus { idle, savingDraft, submitting, saved, failed }

/// A photo in the editor's grid: already on the server ([uploadId] set), on
/// its way up, or refused.
class EditorPhoto extends Equatable {
  /// Stable while the photo is in the grid, uploaded or not.
  final String key;

  /// Where it is drawn from — the server's URL, or the file on the device.
  final String source;

  final String? uploadId;
  final bool failed;

  const EditorPhoto({
    required this.key,
    required this.source,
    this.uploadId,
    this.failed = false,
  });

  bool get isUploading => uploadId == null && !failed;

  @override
  List<Object?> get props => [key, source, uploadId, failed];
}

/// What the form's fields hold when it is submitted — everything the
/// draft needs except the photos, which the cubit keeps.
class ProductFormValues extends Equatable {
  final String name;
  final String categoryId;
  final int priceFils;
  final bool isAvailable;
  final PreparationTime preparationTime;
  final String description;

  const ProductFormValues({
    required this.name,
    required this.categoryId,
    required this.priceFils,
    required this.isAvailable,
    required this.preparationTime,
    required this.description,
  });

  @override
  List<Object?> get props =>
      [name, categoryId, priceFils, isAvailable, preparationTime, description];
}

class ProductEditorState extends Equatable {
  final ProductEditorStatus status;
  final List<ProductCategory> categories;

  /// The product being edited; null when making one.
  final VendorProduct? product;

  final List<EditorPhoto> photos;

  /// A photo was added, removed or moved since the editor opened.
  final bool photosChanged;

  final ProductSaveStatus saveStatus;
  final ProductSaveResult? saved;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  const ProductEditorState({
    this.status = ProductEditorStatus.loading,
    this.categories = const [],
    this.product,
    this.photos = const [],
    this.photosChanged = false,
    this.saveStatus = ProductSaveStatus.idle,
    this.saved,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  bool get isNew => product == null;

  bool get isSaving =>
      saveStatus == ProductSaveStatus.savingDraft ||
      saveStatus == ProductSaveStatus.submitting;

  bool get isUploading => photos.any((photo) => photo.isUploading);

  /// Every field error on its own line, or the message.
  String? get displayError {
    final messages = [
      for (final message in fieldErrors.values)
        if (message.trim().isNotEmpty) message,
    ];
    return messages.isNotEmpty ? messages.join('\n') : errorMessage;
  }

  /// [errorMessage], [fieldErrors] and [saveStatus] belong to one attempt
  /// and are cleared on every copy unless passed again.
  ProductEditorState copyWith({
    ProductEditorStatus? status,
    List<ProductCategory>? categories,
    VendorProduct? product,
    List<EditorPhoto>? photos,
    bool? photosChanged,
    ProductSaveStatus? saveStatus,
    ProductSaveResult? saved,
    String? errorMessage,
    Map<String, String>? fieldErrors,
  }) {
    return ProductEditorState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      product: product ?? this.product,
      photos: photos ?? this.photos,
      photosChanged: photosChanged ?? this.photosChanged,
      saveStatus: saveStatus ?? ProductSaveStatus.idle,
      saved: saved ?? this.saved,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? const {},
    );
  }

  @override
  List<Object?> get props => [
        status,
        categories,
        product,
        photos,
        photosChanged,
        saveStatus,
        saved,
        errorMessage,
        fieldErrors,
      ];
}
