import 'package:equatable/equatable.dart';

/// A photo the server holds, ready to attach — the answer to
/// `POST /uploads`. Products, covers and documents name it by [uploadId],
/// never by URL.
class UploadedImage extends Equatable {
  final String uploadId;

  /// Where to show it from.
  final String url;

  final int? width;
  final int? height;

  const UploadedImage({
    required this.uploadId,
    required this.url,
    this.width,
    this.height,
  });

  @override
  List<Object?> get props => [uploadId, url, width, height];
}
