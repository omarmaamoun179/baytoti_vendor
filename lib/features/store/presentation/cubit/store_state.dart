import 'package:equatable/equatable.dart';

import '../../domain/entities/store_profile.dart';

enum StoreStatus { initial, loading, loaded, error }

enum StoreSaveStatus { idle, saving, saved, failed }

/// A new cover picked on this visit: on its way up, up, or refused.
class PendingCover extends Equatable {
  /// The file on the device, drawn until the save lands.
  final String source;

  final String? uploadId;
  final bool failed;

  const PendingCover({required this.source, this.uploadId, this.failed = false});

  bool get isUploading => uploadId == null && !failed;

  @override
  List<Object?> get props => [source, uploadId, failed];
}

/// What the details form holds when it is saved.
class StoreFormValues extends Equatable {
  final String name;
  final String story;
  final StoreCity? city;

  const StoreFormValues({required this.name, required this.story, this.city});

  @override
  List<Object?> get props => [name, story, city];
}

class StoreState extends Equatable {
  final StoreStatus status;
  final StoreProfile? store;
  final PendingCover? cover;
  final StoreSaveStatus saveStatus;
  final String? errorMessage;

  const StoreState({
    this.status = StoreStatus.initial,
    this.store,
    this.cover,
    this.saveStatus = StoreSaveStatus.idle,
    this.errorMessage,
  });

  bool get isSaving => saveStatus == StoreSaveStatus.saving;

  /// The cover to draw: the one just picked, else the store's.
  String? get coverSource => cover?.source ?? store?.coverUrl;

  /// [errorMessage] and [saveStatus] belong to one attempt and are cleared
  /// on every copy unless passed again. [clearCover] drops a cover that has
  /// been saved.
  StoreState copyWith({
    StoreStatus? status,
    StoreProfile? store,
    PendingCover? cover,
    bool clearCover = false,
    StoreSaveStatus? saveStatus,
    String? errorMessage,
  }) {
    return StoreState(
      status: status ?? this.status,
      store: store ?? this.store,
      cover: clearCover ? null : cover ?? this.cover,
      saveStatus: saveStatus ?? StoreSaveStatus.idle,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, store, cover, saveStatus, errorMessage];
}
