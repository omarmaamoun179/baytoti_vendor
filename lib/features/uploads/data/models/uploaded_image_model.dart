import '../../../../core/utils/json_read.dart';
import '../../domain/entities/uploaded_image.dart';

/// `POST /uploads` → `{"upload_id": "upl_3", "url": "…", "width": 800,
/// "height": 800}`.
class UploadedImageModel extends UploadedImage {
  const UploadedImageModel({
    required super.uploadId,
    required super.url,
    super.width,
    super.height,
  });

  factory UploadedImageModel.fromJson(Map<String, dynamic> json) {
    return UploadedImageModel(
      uploadId: requireString(json['upload_id'], 'upload_id'),
      url: asString(json['url']) ?? '',
      width: asInt(json['width']),
      height: asInt(json['height']),
    );
  }
}
