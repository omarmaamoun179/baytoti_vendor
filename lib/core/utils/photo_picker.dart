import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import '../widgets/app_toast.dart';
import 'app_logger.dart';

/// Photos chosen from the gallery, as paths on the device — empty when the
/// vendor chose nothing.
///
/// A platform call with no repository in front of it, so it is caught here,
/// in presentation: choosing nothing is an empty list, not an error, and a
/// refusal (photo access turned off) is a toast.
///
/// The photos are scaled to 1600px at quality 85 on the device: the server's
/// size limit is not known yet, and a phone photo runs to several megabytes.
///
/// No permission is asked for. On Android the system Photo Picker hands over
/// only the photos chosen, so the app declares no storage permission (Google
/// Play restricts `READ_MEDIA_IMAGES` to gallery apps). On iOS the picker
/// runs outside the app, and without `requestFullMetadata` it never asks for
/// the whole library — `NSPhotoLibraryUsageDescription` in `Info.plist` is
/// there because the App Store requires it.
Future<List<String>> pickGalleryPhotos(
  BuildContext context, {
  bool multiple = true,
}) async {
  final platform = ImagePickerPlatform.instance;
  if (platform is ImagePickerAndroid) platform.useAndroidPhotoPicker = true;

  final picker = ImagePicker();
  try {
    if (!multiple) {
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      return [?file?.path];
    }

    final files = await picker.pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    return [for (final file in files) file.path];
  } on PlatformException catch (e, s) {
    logError(e, s, reason: 'pickGalleryPhotos');
    if (context.mounted) {
      showAppToast(context, 'photo_pick_failed'.tr(), isError: true);
    }
    return const [];
  }
}
