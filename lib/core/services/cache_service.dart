import 'secure_storage_service.dart';
import 'shared_pref_service.dart';

/// Named, typed access to everything the app persists between launches.
///
/// Sensitive values (the serialized user) go to secure storage; preferences
/// (language, last known location) go to SharedPreferences. Features depend
/// on this rather than on either storage service directly, so a key is
/// defined in exactly one place.
///
/// Session tokens are deliberately *not* here — they live behind
/// [TokenStore](../network/token_store.dart), which the network layer owns.
abstract class CacheService {
  Future<bool> saveUserData(String userData);
  Future<String?> getUserData();
  Future<bool> clearUserData();

  Future<String?> getLanguageCode();
  Future<void> setLanguageCode(String languageCode);

  Future<bool> saveUserLocation(String location);
  Future<String?> getUserLocation();
  Future<bool> clearUserLocation();

  /// True once the user has seen the onboarding flow.
  Future<bool?> getOnboardingSeen();
  Future<bool> setOnboardingSeen(bool seen);

  /// `'dark'` or `'light'` — the theme the shopper last chose.
  Future<String?> getThemeMode();
  Future<bool> setThemeMode(String mode);

  /// Wipes everything tied to the signed-in user, leaving device-level
  /// preferences (language, onboarding) intact.
  Future<void> clearSession();
}

class CacheServiceImpl implements CacheService {
  static const _userDataKey = 'user_data';
  static const _languageCodeKey = 'language_code';
  static const _locationKey = 'user_location';
  static const _onboardingSeenKey = 'onboarding_seen';
  static const _themeModeKey = 'theme_mode';

  final SharedPrefService _sharedPref;
  final SecureStorageService _secureStorage;

  CacheServiceImpl(this._sharedPref, this._secureStorage);

  @override
  Future<String?> getUserData() => _secureStorage.read(key: _userDataKey);

  @override
  Future<bool> saveUserData(String userData) async {
    await _secureStorage.write(key: _userDataKey, value: userData);
    return true;
  }

  @override
  Future<bool> clearUserData() async {
    await _secureStorage.delete(key: _userDataKey);
    return true;
  }

  @override
  Future<String?> getLanguageCode() =>
      _sharedPref.readString(key: _languageCodeKey);

  @override
  Future<void> setLanguageCode(String languageCode) =>
      _sharedPref.writeString(key: _languageCodeKey, value: languageCode);

  @override
  Future<String?> getUserLocation() =>
      _sharedPref.readString(key: _locationKey);

  @override
  Future<bool> saveUserLocation(String location) =>
      _sharedPref.writeString(key: _locationKey, value: location);

  @override
  Future<bool> clearUserLocation() => _sharedPref.delete(key: _locationKey);

  @override
  Future<bool?> getOnboardingSeen() =>
      _sharedPref.readBool(key: _onboardingSeenKey);

  @override
  Future<bool> setOnboardingSeen(bool seen) =>
      _sharedPref.writeBool(key: _onboardingSeenKey, value: seen);

  @override
  Future<String?> getThemeMode() => _sharedPref.readString(key: _themeModeKey);

  @override
  Future<bool> setThemeMode(String mode) =>
      _sharedPref.writeString(key: _themeModeKey, value: mode);

  @override
  Future<void> clearSession() async {
    await clearUserData();
    await clearUserLocation();
  }
}
