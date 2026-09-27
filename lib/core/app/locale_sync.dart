import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../services/cache_service.dart';

/// Keeps the stored language code in step with the app's language.
///
/// `easy_localization` keeps its own copy of the chosen locale, but the
/// data layer reads [CacheService.getLanguageCode] — the network layer for
/// the language header it sends, the fixtures for the language they answer
/// in. Nothing else wrote it, so the server would have been asked in Arabic
/// whatever the family chose. This writes it on the first build and on
/// every change after.
class LocaleSync extends StatefulWidget {
  final CacheService cacheService;
  final Widget child;

  const LocaleSync({super.key, required this.cacheService, required this.child});

  @override
  State<LocaleSync> createState() => _LocaleSyncState();
}

class _LocaleSyncState extends State<LocaleSync> {
  String? _written;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = context.locale.languageCode;
    if (code == _written) return;

    _written = code;
    // SharedPreferences updates its in-memory copy before this returns, so
    // a read started later in this frame already sees the new code.
    widget.cacheService.setLanguageCode(code);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Rebuilds everything beneath it once a new language has loaded.
///
/// `'key'.tr()` reads the loaded translations without depending on the
/// locale, so a widget that does not rebuild for another reason keeps the
/// old language — the header of a tab kept alive in the shell, most
/// visibly. Placed inside [MaterialApp] (through its `builder`), below
/// [Localizations], so it fires only after the new translations are in.
/// State is kept: this rebuilds, it does not recreate.
class LocaleRefresh extends StatefulWidget {
  final Widget child;

  const LocaleRefresh({super.key, required this.child});

  @override
  State<LocaleRefresh> createState() => _LocaleRefreshState();
}

class _LocaleRefreshState extends State<LocaleRefresh> {
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_locale != null && _locale != locale) {
      // After the frame: marking other elements dirty mid-build is illegal.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) (context as Element).visitChildren(_markDirty);
      });
    }
    _locale = locale;
  }

  void _markDirty(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_markDirty);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
