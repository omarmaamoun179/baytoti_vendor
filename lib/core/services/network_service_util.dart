import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../network/token_store.dart';
import 'app_service_info.dart';
import 'cache_service.dart';

/// Token, language and device lookups the network layer needs.
///
/// Used only as a helper inside [NetworkService] — do NOT call it elsewhere;
/// features read the session through their own repository.
abstract class NetworkServiceUtil {
  Future<String?> getCurrentAccessToken();
  Future<String?> getLanguageCode();
  Future<String> getAppVersion();
  String getPlatformType();
  Future<void> clearCurrentUserData();
}

class NetworkServiceUtilImpl implements NetworkServiceUtil {
  NetworkServiceUtilImpl(this._cacheService, this._tokenStore, this._appInfo);

  final CacheService _cacheService;

  /// The session lives behind [TokenStore] (Keychain/Keystore), not in
  /// [CacheService] — that holds preferences only.
  final TokenStore _tokenStore;

  final AppInfo _appInfo;

  String? _cachedAppVersion;

  @override
  Future<String?> getCurrentAccessToken() async =>
      (await _tokenStore.read())?.accessToken;

  @override
  Future<String?> getLanguageCode() async {
    final language = await _cacheService.getLanguageCode();
    // Stored as `ar_KW` in some paths; the header wants the language only.
    return language?.split('_').first;
  }

  @override
  Future<String> getAppVersion() async =>
      _cachedAppVersion ??= (_appInfo.version ?? '1.0.0').split('-').first;

  @override
  String getPlatformType() {
    if (kIsWeb) return 'web';
    return Platform.isAndroid ? 'android' : 'ios';
  }

  @override
  Future<void> clearCurrentUserData() async {
    await _tokenStore.clear();
    await _cacheService.clearSession();
  }
}
