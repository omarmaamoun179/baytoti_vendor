import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';

/// The design's phone input, built on `intl_phone_number_input`.
///
/// The package keeps everything it is good at — libphonenumber validation,
/// as-you-type grouping, the country list and its search sheet — and this
/// widget only dresses it: the same 52px rounded row, palette colors and
/// label/error placement as `CustomTextFormField`, so a phone field sitting
/// in a form next to the other inputs is indistinguishable from them.
///
/// The country selector is the field's `prefixIcon`, given an exact width so
/// the divider drawn beside it lands on the prefix's inner edge — measured
/// from the dial code rather than guessed, because the package's selector
/// lays its flag and code out in a `Row` that overflows the moment the type
/// scales past the reserved box. Tapping it opens the package's search sheet;
/// a [countries] list with a single entry renders the same dial code as a
/// plain, untappable label instead.
///
/// Validation is the package's, not the app's: libphonenumber knows what a
/// valid number looks like in each country the selector offers, and a rule
/// written here ("eight digits") would only hold for one of them. The caller
/// supplies the messages and, if it needs one, an extra [validator]. The
/// length rule ([nationalLengths]) runs first only so the message can name
/// the count the country expects instead of a flat "invalid".
///
/// Pass a [focusNode] the form owns: leaving the field reformats what was
/// typed into the country's grouping, which is also the moment the form moves
/// focus on.
class PhoneTextFormField extends StatefulWidget {
  /// Small label drawn above the field. Omit for a bare input.
  final String? label;

  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Shown when the field is left empty. Null accepts an empty field.
  final String? requiredMessage;

  /// Shown when libphonenumber rejects what was typed for the country the
  /// selector is on. Null skips that check — presence only.
  final String? invalidMessage;

  /// Shown when the number has the wrong number of digits for its country,
  /// given the count [nationalLengths] expects. Null falls through to
  /// [invalidMessage], which says the same thing less precisely.
  final String Function(int digits)? lengthMessage;

  /// Digits in a national number, per ISO code — Kuwait 8, Egypt 10, both
  /// counted without the dial code and without Egypt's trunk `0`.
  ///
  /// Only what [lengthMessage] quotes: a country missing from the map skips
  /// the length rule, and libphonenumber still has the final say on every
  /// number that passes it.
  final Map<String, int> nationalLengths;

  /// An extra rule on the *typed* text — the national number, grouped as the
  /// user sees it (`5512 3456`), not the E.164 form. Runs after
  /// [requiredMessage] and [invalidMessage] have both passed.
  ///
  /// The package's own validator is never used: its message would be drawn by
  /// the decorator, and the decorator's message is collapsed here so the error
  /// can take real space in the column instead of overlapping what follows.
  final String? Function(String?)? validator;

  /// Fires on every keystroke with the number in E.164 form plus the country
  /// that produced it. The [controller] is the simpler source when all the
  /// caller needs is the digits.
  final ValueChanged<PhoneNumber>? onInputChanged;

  final ValueChanged<String>? onSubmitted;

  /// ISO codes offered by the selector. One entry locks the field to that
  /// country; more than one turns the dial code into a picker.
  final List<String> countries;

  /// Which of [countries] starts selected.
  final String initialIsoCode;

  /// A number to start from, as the API stores one: digits with the country
  /// code, with or without the `+`.
  ///
  /// Its country is read from the number itself — nothing is assumed — and
  /// the field then reports it through [onInputChanged] as if it had been
  /// typed. A number libphonenumber cannot place, or one from outside
  /// [countries], leaves the field empty on [initialIsoCode].
  final String? initialNumber;

  final bool enabled;
  final TextInputAction textInputAction;

  /// When the field checks itself. The default reports a wrong length or a
  /// rejected number as it is typed, without waiting for the submit button.
  final AutovalidateMode autovalidateMode;

  final double height;
  final double radius;

  /// Width reserved for the flag and dial code. Measured from
  /// [dialCodeSample] when left null, which is what keeps the divider on the
  /// prefix's edge at any text scale.
  final double? selectorWidth;

  /// The widest dial code the selector can show, used to size it — the
  /// divider then stays put whichever country is picked. Widen it (`+1-684`
  /// is the longest the package renders) when [countries] grows past what
  /// `+965` covers.
  final String dialCodeSample;

  const PhoneTextFormField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.requiredMessage,
    this.invalidMessage,
    this.lengthMessage,
    this.nationalLengths = const {'KW': 8, 'EG': 10},
    this.validator,
    this.onInputChanged,
    this.onSubmitted,
    this.countries = const ['KW', 'EG'],
    this.initialIsoCode = 'KW',
    this.initialNumber,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.height = 52,
    this.radius = 13,
    this.selectorWidth,
    this.dialCodeSample = '+965',
  });

  @override
  State<PhoneTextFormField> createState() => _PhoneTextFormFieldState();
}

class _PhoneTextFormFieldState extends State<PhoneTextFormField> {
  /// The package's own layout inside the selector button: a leading gap, the
  /// 32px flag asset, a fixed gap, the dial code, then the button's trailing
  /// padding. Mirrored here only to size the box the selector is given.
  static const double _flagWidth = 32;
  static const double _flagGap = 12;
  static const double _buttonTrailing = 8;

  /// A hair more than the measurement, so rounding between [TextPainter] and
  /// the laid-out [Text] cannot overflow the selector's row by a fraction of
  /// a pixel.
  static const double _measureSlack = 2;

  /// Matches the 15px inset the other fields give their text and affixes.
  static const double _leadingPadding = 15;

  /// The current validation message, mirrored out of the decorator — see
  /// [PhoneTextFormField.validator].
  String? _errorText;

  /// libphonenumber's verdict on what has been typed so far, for the country
  /// the selector is on. The package hands it over on every keystroke.
  bool _isValidNumber = false;

  /// The last number the package reported: E.164 when it parses, the dial
  /// code in front of the raw digits while it does not. Either way it is
  /// where the selected country and the national digit count come from — the
  /// controller holds neither.
  PhoneNumber? _number;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChanged);
    _placeInitialNumber();
  }

  /// Finds [PhoneTextFormField.initialNumber]'s country and hands the package
  /// both: it validates the pair, fills the field in the country's grouping
  /// and reports the number back.
  ///
  /// The digits carry a dial code but do not say where it ends, so
  /// libphonenumber is asked rather than the prefix guessed.
  Future<void> _placeInitialNumber() async {
    final digits = (widget.initialNumber ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    try {
      final number = await PhoneNumber.getRegionInfoFromPhoneNumber('+$digits');
      if (!mounted || !widget.countries.contains(number.isoCode)) return;

      setState(() {
        _initialValue = PhoneNumber(
          phoneNumber: number.phoneNumber,
          isoCode: number.isoCode,
        );
      });
    } on Exception {
      // libphonenumber could not place it — the field starts empty.
    }
  }

  @override
  void didUpdateWidget(PhoneTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      widget.focusNode?.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    // Removed, never disposed: the node belongs to the form that passed it.
    widget.focusNode?.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (widget.focusNode?.hasFocus ?? true) return;
    _reformat();
  }

  /// Rewrites what was typed in the country's own grouping once the field is
  /// left — `55123456` becomes `551 23456`, and an Egyptian number keeps the
  /// `0` it was typed with out of the wire.
  ///
  /// Needs the caller's [PhoneTextFormField.controller]: without one the text
  /// lives in a controller the package keeps to itself.
  Future<void> _reformat() async {
    final controller = widget.controller;
    final number = _number;

    if (controller == null ||
        !_isValidNumber ||
        number?.phoneNumber == null ||
        number?.isoCode == null) {
      return;
    }

    try {
      final formatted = await PhoneNumber.getParsableNumber(number!);
      if (!mounted || formatted.isEmpty || formatted == controller.text) return;
      controller.text = formatted;
    } on Exception {
      // libphonenumber could not parse it after all — what was typed stands.
    }
  }

  bool get _isEmpty => widget.controller?.text.trim().isEmpty ?? true;

  bool get _hasFocus => widget.focusNode?.hasFocus ?? false;

  /// Digits in the number without its dial code, as libphonenumber counts
  /// them: Egypt's trunk `0` is gone by the time the package reports back.
  int? get _nationalLength {
    final number = _number?.phoneNumber;
    if (number == null) return null;

    final digits = number.replaceAll(RegExp(r'\D'), '');
    final dialCode = (_number?.dialCode ?? '').replaceAll(RegExp(r'\D'), '');

    if (dialCode.isEmpty || !digits.startsWith(dialCode)) return digits.length;
    return digits.length - dialCode.length;
  }

  /// Built once, and replaced at most once more, when an
  /// [PhoneTextFormField.initialNumber] has been placed: the package stamps
  /// every [PhoneNumber] with a random hash and re-runs its initialisation
  /// whenever that hash changes, so a fresh instance per build would have it
  /// re-initialise on every rebuild.
  late PhoneNumber _initialValue = PhoneNumber(
    isoCode: widget.initialIsoCode,
  );

  /// How wide the flag and dial code actually come out, at this text scale.
  double _measureSelector(BuildContext context, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: widget.dialCodeSample, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    return _leadingPadding +
        _flagWidth +
        _flagGap +
        painter.width.ceilToDouble() +
        _buttonTrailing +
        _measureSlack;
  }

  String? _check(String? value) {
    if ((value ?? '').trim().isEmpty) return widget.requiredMessage;

    final expected = widget.nationalLengths[_number?.isoCode];
    final actual = _nationalLength;

    if (widget.lengthMessage != null &&
        expected != null &&
        actual != null &&
        actual != expected) {
      return widget.lengthMessage!(expected);
    }

    if (widget.invalidMessage != null && !_isValidNumber) {
      return widget.invalidMessage;
    }

    return widget.validator?.call(value);
  }

  /// Runs during the form's layout pass, where `setState` is illegal — hence
  /// the deferral to the end of the frame.
  String? _validate(String? value) {
    final error = _check(value);

    if (error != _errorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _errorText = error);
      });
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppStrings.text12w500.c(p.fg2)),
          const SizedBox(height: 8),
        ],
        _buildField(context),
        if (_errorText != null) ...[
          const SizedBox(height: 6),
          Text(_errorText!, style: AppStrings.text11w400Loose.c(p.bad)),
        ],
      ],
    );
  }

  Widget _buildField(BuildContext context) {
    final p = context.palette;
    final selectorWidth =
        widget.selectorWidth ??
        _measureSelector(context, _selectorTextStyle(context));

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          _buildInput(context, selectorWidth),
          // Splits the selector from the number without touching the
          // package's own layout: the prefix is a fixed [selectorWidth] box,
          // so the line sits on its inner edge in both directions. Inset top
          // and bottom so it reads as a divider rather than a second border.
          PositionedDirectional(
            start: selectorWidth,
            top: 10,
            bottom: 10,
            child: Container(width: 1, color: p.line),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context, double selectorWidth) {
    final p = context.palette;

    return InternationalPhoneNumberInput(
      countries: widget.countries,
      initialValue: _initialValue,
      textFieldController: widget.controller,
      focusNode: widget.focusNode,
      isEnabled: widget.enabled,
      keyboardAction: widget.textInputAction,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      autoValidateMode: AutovalidateMode.onUserInteraction,
      validator: _validate,
      onInputChanged: (number) {
        _number = number;
        widget.onInputChanged?.call(number);
      },
      onInputValidated: (isValid) => _isValidNumber = isValid,
      onFieldSubmitted: widget.onSubmitted,

      locale: Localizations.localeOf(context).languageCode,
      cursorColor: p.gold,

      textAlign: Directionality.of(context) == TextDirection.rtl
          ? TextAlign.end
          : TextAlign.start,
      textStyle: AppStrings.text13w500.c(widget.enabled ? p.fg : p.fg3),
      selectorTextStyle: _selectorTextStyle(context),
      errorMessage: _isEmpty && !_hasFocus
          ? widget.requiredMessage
          : widget.invalidMessage,
      selectorConfig: const SelectorConfig(
        // A sheet, like every other picker in the app. Opening it trips a
        // debug-only framework assert — the package colours the sheet with a
        // `DecoratedBox` above its `ListTile`s, so their ink splash has
        // nowhere to paint. Nothing is lost but the ripple, and the only way
        // out is the DIALOG selector.
        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
        setSelectorButtonAsPrefixIcon: true,
        useBottomSheetSafeArea: true,
        // Aligns the flag with the 15px text inset the other fields use.
        leadingPadding: _leadingPadding,
        // The padding that would follow a short dial code is what
        // [selectorWidth] and the divider already provide.
        trailingSpace: false,
      ),
      searchBoxDecoration: _searchDecoration(context),
      inputDecoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppStrings.text13w400Notif.c(p.fg3),
        filled: true,
        fillColor: p.surf,
        counterText: '',

        contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 0, 15, 0),

        prefixIconConstraints: BoxConstraints.tightFor(
          width: selectorWidth,
          height: widget.height,
        ),
        border: _border(p.line),
        enabledBorder: _border(p.line),
        focusedBorder: _border(p.gold),
        disabledBorder: _border(p.line),
        errorBorder: _border(p.bad),
        focusedErrorBorder: _border(p.bad),

        errorStyle: const TextStyle(fontSize: 0, height: 0),
      ),
    );
  }

  TextStyle _selectorTextStyle(BuildContext context) {
    final p = context.palette;
    return AppStrings.text13w600.c(widget.enabled ? p.fg : p.fg3);
  }

  /// The search box inside the country sheet — the one part of the package's
  /// own UI a caller can restyle.
  InputDecoration _searchDecoration(BuildContext context) {
    final p = context.palette;

    return InputDecoration(
      hintText: 'search_by_country'.tr(),
      hintStyle: AppStrings.text13w400Notif.c(p.fg3),
      filled: true,
      fillColor: p.surf,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.fg3),
      border: _border(p.line),
      enabledBorder: _border(p.line),
      focusedBorder: _border(p.gold),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(widget.radius),
    borderSide: BorderSide(
      color: color,
      width: color == context.palette.gold ? 1.5 : 1,
    ),
  );
}
