import '../services/cache_service.dart';

/// How long a fixture takes to answer — enough for a spinner to show, so a
/// screen's loading state is exercised on fixtures too.
const Duration mockLatency = Duration(milliseconds: 350);

/// A fixture string in both of the app's languages.
class Localized {
  final String ar;
  final String en;

  const Localized(this.ar, this.en);

  String pick(bool isArabic) => isArabic ? ar : en;
}

/// The language a fixture answers in.
///
/// The API contract has the server localise every user-facing string from
/// the request's language header, which the network layer reads from the
/// stored language code (`NetworkServiceUtil.getLanguageCode`). Fixtures
/// read the same code, so switching the app's language changes what the
/// next read says — exactly as it will against the server, and just as
/// stale for anything already on screen until it is read again.
class MockLocale {
  final CacheService _cacheService;

  const MockLocale(this._cacheService);

  Future<bool> isArabic() async =>
      (await _cacheService.getLanguageCode()) != 'en';
}
