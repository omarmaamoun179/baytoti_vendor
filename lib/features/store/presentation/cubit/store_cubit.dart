import 'package:easy_localization/easy_localization.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../../uploads/domain/usecases/upload_image_usecase.dart';
import '../../domain/entities/store_profile.dart';
import '../../domain/usecases/store_usecases.dart';
import 'store_state.dart';

/// The store tab: the profile the customer sees, a new cover, and the save.
/// The details themselves are edited in the form; this holds what talks to
/// the server.
class StoreCubit extends BaseCubit<StoreState> {
  final GetStoreUseCase _getStore;
  final UpdateStoreUseCase _updateStore;
  final UploadImageUseCase _uploadImage;

  StoreCubit(this._getStore, this._updateStore, this._uploadImage)
      : super(const StoreState());

  Future<void> load() async {
    if (state.store == null) emit(state.copyWith(status: StoreStatus.loading));

    final result = await _getStore(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: state.store == null ? StoreStatus.error : StoreStatus.loaded,
        errorMessage: failure.message,
      )),
      (store) => emit(state.copyWith(status: StoreStatus.loaded, store: store)),
    );
  }

  /// Uploads the photo at [path] as the new cover. It replaces the old one
  /// with the next save.
  Future<void> changeCover(String path) async {
    emit(state.copyWith(cover: PendingCover(source: path)));

    final result = await _uploadImage(path);

    // Another cover was picked while this one was going up.
    if (state.cover?.source != path) return;

    result.fold(
      (failure) => emit(state.copyWith(
        cover: PendingCover(source: path, failed: true),
        errorMessage: failure.message,
      )),
      (uploaded) => emit(state.copyWith(
        cover: PendingCover(source: path, uploadId: uploaded.uploadId),
      )),
    );
  }

  Future<void> save(StoreFormValues values) async {
    if (state.isSaving) return;

    final cover = state.cover;
    if (cover != null && (cover.isUploading || cover.failed)) {
      emit(state.copyWith(
        saveStatus: StoreSaveStatus.failed,
        errorMessage: (cover.failed
                ? 'store_cover_failed'
                : 'store_cover_uploading')
            .tr(),
      ));
      return;
    }

    emit(state.copyWith(saveStatus: StoreSaveStatus.saving));

    final result = await _updateStore(UpdateStoreParams(
      name: values.name,
      story: values.story,
      city: values.city,
      coverUploadId: cover?.uploadId,
      coverUrl: cover?.source,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        saveStatus: StoreSaveStatus.failed,
        errorMessage: failure.message,
      )),
      (store) => emit(state.copyWith(
        store: store,
        clearCover: true,
        saveStatus: StoreSaveStatus.saved,
      )),
    );
  }
}
