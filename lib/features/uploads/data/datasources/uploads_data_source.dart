import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../models/uploaded_image_model.dart';

/// Readies a picked photo for a save. [UploadsMockDataSource] plays the
/// design contract's `POST /uploads`; [DeviceUploadsDataSource] serves the
/// live API, which takes photos inside the product's own save.
abstract class UploadsDataSource {
  Future<Either<Failure, UploadedImageModel>> uploadImage(String localPath);
}
