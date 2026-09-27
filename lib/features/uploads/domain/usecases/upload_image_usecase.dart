import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/uploaded_image.dart';
import '../repositories/uploads_repository.dart';

/// Takes a path on the device.
class UploadImageUseCase
    implements UseCase<Either<Failure, UploadedImage>, String> {
  final UploadsRepository _repository;

  UploadImageUseCase(this._repository);

  @override
  Future<Either<Failure, UploadedImage>> call(String localPath) =>
      _repository.uploadImage(localPath);
}
