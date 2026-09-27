import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/network/guarded_request.dart';
import '../models/uploaded_image_model.dart';
import 'uploads_data_source.dart';

const String _devicePrefix = 'device:';

/// The file behind an upload id this source made, or null for an id the
/// server gave — how a save tells a photo still to send as a file from one
/// the server already holds.
String? devicePathOf(String uploadId) => uploadId.startsWith(_devicePrefix)
    ? uploadId.substring(_devicePrefix.length)
    : null;

/// Uploads on the live API, which has no upload endpoint: a product's
/// photos travel inside its own multipart save. So nothing leaves the device
/// here — the picked file is checked against the API's size limit and
/// handed back under an id that names its path ([devicePathOf]), and the
/// save that uses it sends the file.
class DeviceUploadsDataSource implements UploadsDataSource {
  /// The API's `max:5120` (kilobytes) on a product image.
  static const int _maxBytes = 5120 * 1024;

  @override
  Future<Either<Failure, UploadedImageModel>> uploadImage(String localPath) =>
      guardedRequest(
        'DeviceUploadsDataSource.uploadImage',
        () async {
          if (await File(localPath).length() > _maxBytes) {
            throw const RequestException('image_too_large', statusCode: 413);
          }

          return UploadedImageModel.fromJson({
            'upload_id': '$_devicePrefix$localPath',
            // Drawn from the file, as `NetworkPhoto` does a local path.
            'url': localPath,
          });
        },
        fallbackMessage: 'upload_failed',
      );
}
