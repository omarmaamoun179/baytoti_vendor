import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/uploaded_image.dart';

abstract class UploadsRepository {
  /// Sends the photo at [localPath] and answers with what to attach it by.
  Future<Either<Failure, UploadedImage>> uploadImage(String localPath);
}
