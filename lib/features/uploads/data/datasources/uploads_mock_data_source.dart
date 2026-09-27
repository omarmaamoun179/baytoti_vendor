import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/mock/mock_locale.dart';
import '../../../../core/network/guarded_request.dart';
import '../models/uploaded_image_model.dart';
import 'uploads_data_source.dart';

/// Uploads on fixtures: nothing leaves the device. The "uploaded" photo's
/// URL is its path on the device, which `NetworkPhoto` draws from the file,
/// so a picked photo shows wherever the server's URL would.
class UploadsMockDataSource implements UploadsDataSource {
  /// The contract gives no limit; the customer app's is 5 MB.
  static const int _maxBytes = 5 * 1024 * 1024;

  int _sequence = 0;

  @override
  Future<Either<Failure, UploadedImageModel>> uploadImage(String localPath) =>
      guardedRequest(
        'UploadsMockDataSource.uploadImage',
        () async {
          await Future<void>.delayed(mockLatency * 2);

          final file = File(localPath);
          if (await file.length() > _maxBytes) {
            throw const RequestException('image_too_large', statusCode: 413);
          }

          return UploadedImageModel.fromJson({
            'upload_id': 'upl_${++_sequence}',
            'url': localPath,
          });
        },
        fallbackMessage: 'upload_failed',
      );
}
