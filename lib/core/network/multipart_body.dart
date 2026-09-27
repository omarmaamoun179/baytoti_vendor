import 'package:dio/dio.dart';

/// A file on this device, sent as one part of a multipart body. A request
/// body holding one anywhere goes out through [multipartBodyFrom].
class FileUpload {
  final String path;

  const FileUpload(this.path);

  /// The file's name as the server receives it.
  String get filename => path.split(RegExp(r'[/\\]')).last;

  /// Read from the extension; an unknown one goes out as bytes, and Laravel's
  /// `image` rule reads the content itself either way.
  DioMediaType get mediaType {
    final extension = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    return DioMediaType.parse(switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      _ => 'application/octet-stream',
    });
  }

  @override
  String toString() => 'FileUpload($filename)';
}

/// Whether [value] holds a [FileUpload] at any depth.
bool containsFileUpload(Object? value) => switch (value) {
      FileUpload() => true,
      final Map<dynamic, dynamic> map => map.values.any(containsFileUpload),
      final List<dynamic> list => list.any(containsFileUpload),
      _ => false,
    };

/// [body] as a `multipart/form-data` body, in the bracket keys Laravel reads
/// back into arrays: `{colors: [{images: [{image: …}]}]}` becomes
/// `colors[0][images][0][image]`.
///
/// A form part is text, so values are spelled the way Laravel's rules accept
/// them: `true`/`false` as `1`/`0` (the `boolean` rule refuses the words), and
/// null as an empty part, which Laravel's `ConvertEmptyStringsToNull` reads as
/// null. Each [FileUpload] becomes a file part. An empty list sends nothing,
/// since a form has no way to spell one.
Future<FormData> multipartBodyFrom(Map<String, dynamic> body) async {
  final form = FormData();

  Future<void> add(String key, Object? value) async {
    switch (value) {
      case final Map<dynamic, dynamic> map:
        for (final entry in map.entries) {
          await add('$key[${entry.key}]', entry.value);
        }
      case final List<dynamic> list:
        for (final (index, item) in list.indexed) {
          await add('$key[$index]', item);
        }
      case final FileUpload file:
        form.files.add(MapEntry(
          key,
          await MultipartFile.fromFile(
            file.path,
            filename: file.filename,
            contentType: file.mediaType,
          ),
        ));
      case null:
        form.fields.add(MapEntry(key, ''));
      case final bool flag:
        form.fields.add(MapEntry(key, flag ? '1' : '0'));
      default:
        form.fields.add(MapEntry(key, '$value'));
    }
  }

  for (final entry in body.entries) {
    await add(entry.key, entry.value);
  }
  return form;
}
