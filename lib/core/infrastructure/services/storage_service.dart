import 'package:shared_preferences/shared_preferences.dart';

/// Simple storage service for token and language
/// Can be extended later with flutter_secure_storage for tokens
abstract class StorageService {
  Future<String> getUserToken();
  Future<void> setUserToken(String token);
  String getAppLanguage();
  Future<void> setAppLanguage(String lang);
  Future<void> clearStorage({bool clearAuthParams = false});
}

class StorageServiceImpl implements StorageService {
  final SharedPreferences _sharedPreferences;
  static const String _tokenKey = 'access_token';
  static const String _languageKey = 'language_code';

  StorageServiceImpl(this._sharedPreferences);

  @override
  Future<String> getUserToken() async {
    return _sharedPreferences.getString(_tokenKey) ?? '';
  }

  @override
  Future<void> setUserToken(String token) async {
    await _sharedPreferences.setString(_tokenKey, token);
  }

  @override
  String getAppLanguage() {
    return _sharedPreferences.getString(_languageKey) ?? 'en';
  }

  @override
  Future<void> setAppLanguage(String lang) async {
    await _sharedPreferences.setString(_languageKey, lang);
  }

  @override
  Future<void> clearStorage({bool clearAuthParams = false}) async {
    if (clearAuthParams) {
      await _sharedPreferences.remove(_tokenKey);
    }
  }
}
