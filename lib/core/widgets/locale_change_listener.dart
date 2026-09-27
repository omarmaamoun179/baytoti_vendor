import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Calls [onChanged] when the app's language changes — not when it is
/// first built.
///
/// The server words its content in the language it is asked in (category
/// names, statuses it labels, the family's own copy in the other language),
/// so a screen that stays alive across a language switch — a tab — reads
/// its data again rather than showing the old language under new labels.
class LocaleChangeListener extends StatefulWidget {
  final VoidCallback onChanged;
  final Widget child;

  const LocaleChangeListener({
    super.key,
    required this.onChanged,
    required this.child,
  });

  @override
  State<LocaleChangeListener> createState() => _LocaleChangeListenerState();
}

class _LocaleChangeListenerState extends State<LocaleChangeListener> {
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.locale;
    if (_locale != null && _locale != locale) {
      // After this frame: the language code the data layer reads is written
      // as the app rebuilds, and a read started mid-build could beat it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged();
      });
    }
    _locale = locale;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
