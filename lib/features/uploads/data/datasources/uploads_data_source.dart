import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../models/uploaded_image_model.dart';

/// `POST /uploads` — multipart. A remote source builds the body with
/// `core/network/multipart_body.dart` (the file as a `FileUpload`).
abstract class UploadsDataSource {
  Future<Either<Failure, UploadedImageModel>> uploadImage(String localPath);
}
