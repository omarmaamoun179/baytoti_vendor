import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'app_icon.dart';

/// The design's missing-photo tile: `neutral-300` with the picture glyph.
///
/// Every product thumbnail, order line and store cover in the design is this
/// placeholder, and the API allows an empty `images` array — so it is the
/// ordinary case, not an error.
class PhotoPlaceholder extends StatelessWidget {
  final double iconSize;
  final Color? color;

  const PhotoPlaceholder({super.key, required this.iconSize, this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ColoredBox(
      color: color ?? p.muted,
      child: Center(
        child: AppIcon(AppIcons.image, size: iconSize, color: p.fg3),
      ),
    );
  }
}

/// A photo that may be remote (`https://…`), on the device (a file just
/// picked from the gallery), or missing — the last two before anything has
/// been uploaded, or when the API sends no image.
class NetworkPhoto extends StatelessWidget {
  final String? source;

  /// The placeholder glyph's size, for when there is no photo.
  final double iconSize;

  final BoxFit fit;

  const NetworkPhoto({
    super.key,
    required this.source,
    required this.iconSize,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final path = source?.trim() ?? '';
    final fallback = PhotoPlaceholder(iconSize: iconSize);
    if (path.isEmpty) return fallback;

    if (!path.startsWith('http')) {
      return Image.file(
        File(path),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return CachedNetworkImage(
      imageUrl: path,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => ColoredBox(color: context.palette.muted),
      errorWidget: (_, _, _) => fallback,
    );
  }
}
