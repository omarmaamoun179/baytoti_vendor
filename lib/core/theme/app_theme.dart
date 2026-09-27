import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_strings.dart';
import 'app_palette.dart';

/// Builds [ThemeData] from [AppPalette].
///
/// The design is light only. The theme reads every color from the palette,
/// so a dark palette, when the design grows one, is a second call to [_build]
/// rather than a second theme to keep in step.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppPalette.light, Brightness.light);

  /// Status-bar icons for the warm off-white — dark glyphs.
  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.amber,
      onSecondary: p.onAccent,
      error: p.bad,
      onError: p.onAccent,
      surface: p.surf,
      onSurface: p.fg,
      surfaceContainerHighest: p.surf2,
      outline: p.line,
      outlineVariant: p.line2,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: AppStrings.fontFamily,
      fontFamilyFallback: AppStrings.fontFamilyFallback,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      splashFactory: InkRipple.splashFactory,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.surf,
        foregroundColor: p.fg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: overlayStyle,
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.fg),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accentSoft2,
        selectionHandleColor: p.accent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surf,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: const Color(0x801F2A24),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surf,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.accent,
        headerForegroundColor: p.onAccent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.bg,
        hintStyle: AppStrings.text14w600.c(p.fg3),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        border: _border(p.line),
        enabledBorder: _border(p.line),
        focusedBorder: _border(p.accent),
        errorBorder: _border(p.bad),
        focusedErrorBorder: _border(p.bad),
        errorStyle: AppStrings.text105w400.c(p.bad),
      ),
      textTheme: _textTheme(p),
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  /// Maps the design ramp onto Material's slots, so widgets that read
  /// `Theme.of(context).textTheme` (the date picker, dialogs) stay on-brand.
  static TextTheme _textTheme(AppPalette p) => TextTheme(
        displayLarge: AppStrings.text34w800.c(p.fg),
        headlineLarge: AppStrings.text26w800.c(p.fg),
        headlineMedium: AppStrings.text24w800.c(p.fg),
        titleLarge: AppStrings.text19w800.c(p.fg),
        titleMedium: AppStrings.text17w800.c(p.fg),
        titleSmall: AppStrings.text14w800.c(p.fg),
        bodyLarge: AppStrings.text14w600.c(p.fg),
        bodyMedium: AppStrings.text125w400.c(p.fg),
        bodySmall: AppStrings.text11w400.c(p.fg2),
        labelLarge: AppStrings.text13w800Flat.c(p.fg),
        labelMedium: AppStrings.text115w600.c(p.fg2),
        labelSmall: AppStrings.text10w400.c(p.fg3),
      );
}
