import 'package:baytoti_vendor/core/mock/mock_session_token.dart';
import 'package:baytoti_vendor/core/network/token_store.dart';
import 'package:baytoti_vendor/core/services/cache_service.dart';
import 'package:baytoti_vendor/core/services/secure_storage_service.dart';

/// The token store, in memory.
class MemoryTokenStore implements TokenStore {
  TokenPair? tokens;

  MemoryTokenStore([this.tokens]);

  /// Signed in as a fixture account.
  factory MemoryTokenStore.signedIn({
    bool isNewFamily = false,
    String phoneDigits = '96551502244',
    String? familyName,
  }) =>
      MemoryTokenStore(TokenPair(
        accessToken: MockSessionToken(
          isNewFamily: isNewFamily,
          phoneDigits: phoneDigits,
          familyName: familyName,
        ).encode(),
      ));

  @override
  Future<TokenPair?> read() async => tokens;

  @override
  Future<void> save(TokenPair tokens) async => this.tokens = tokens;

  @override
  Future<void> clear() async => tokens = null;
}

/// Secure storage, in memory.
class MemorySecureStorage implements SecureStorageService {
  final Map<String, String> values = {};

  @override
  Future<void> write({required String key, required String value}) async =>
      values[key] = value;

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> delete({required String key}) async => values.remove(key);

  @override
  Future<void> deleteAll() async => values.clear();

  @override
  Future<Map<String, String>> readAll() async => {...values};

  @override
  Future<void> clearOnReinstall() async {}
}

/// Just the language code; everything else is unused by the fixtures.
class FakeCacheService implements CacheService {
  String? languageCode;

  FakeCacheService({this.languageCode = 'en'});

  @override
  Future<String?> getLanguageCode() async => languageCode;

  @override
  Future<void> setLanguageCode(String languageCode) async =>
      this.languageCode = languageCode;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
