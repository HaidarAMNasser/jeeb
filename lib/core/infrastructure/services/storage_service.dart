import 'package:shared_preferences/shared_preferences.dart';

/// Simple storage service for token, language, and auth state
/// Can be extended later with flutter_secure_storage for tokens
abstract class StorageService {
  Future<String> getUserToken();
  Future<void> setUserToken(String token);
  String getAppLanguage();
  Future<void> setAppLanguage(String lang);
  Future<String?> getUserRole();
  Future<void> setUserRole(String role);
  Future<int?> getUserId();
  Future<void> setUserId(int userId);
  Future<bool> isFirstLaunch();
  Future<void> setFirstLaunchCompleted();
  Future<bool> isLoggedIn();
  Future<void> setLoggedIn(bool value);
  Future<bool> isVerified();
  Future<void> setVerified(bool value);
  Future<String?> getPendingVerifyEmail();
  Future<void> setPendingVerifyEmail(String? email);
  Future<String?> getFcmToken();
  Future<void> setFcmToken(String token);
  Future<String?> getLastSyncedFcmToken();
  Future<void> setLastSyncedFcmToken(String token);
  Future<int?> getLastSyncedFcmUserId();
  Future<void> setLastSyncedFcmUserId(int userId);
  Future<void> clearStorage({bool clearAuthParams = false});
}

class StorageServiceImpl implements StorageService {
  final SharedPreferences _sharedPreferences;
  static const String _tokenKey = 'access_token';
  static const String _languageKey = 'language_code';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _firstLaunchKey = 'first_launch_done';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _isVerifiedKey = 'is_verified';
  static const String _pendingVerifyEmailKey = 'pending_verify_email';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _lastSyncedFcmTokenKey = 'last_synced_fcm_token';
  static const String _lastSyncedFcmUserIdKey = 'last_synced_fcm_user_id';

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
    return _sharedPreferences.getString(_languageKey) ?? '';
  }

  @override
  Future<void> setAppLanguage(String lang) async {
    await _sharedPreferences.setString(_languageKey, lang);
  }

  @override
  Future<String?> getUserRole() async {
    return _sharedPreferences.getString(_userRoleKey);
  }

  @override
  Future<void> setUserRole(String role) async {
    await _sharedPreferences.setString(_userRoleKey, role);
  }

  @override
  Future<int?> getUserId() async {
    return _sharedPreferences.getInt(_userIdKey);
  }

  @override
  Future<void> setUserId(int userId) async {
    await _sharedPreferences.setInt(_userIdKey, userId);
  }

  @override
  Future<bool> isFirstLaunch() async {
    return !(_sharedPreferences.getBool(_firstLaunchKey) ?? false);
  }

  @override
  Future<void> setFirstLaunchCompleted() async {
    await _sharedPreferences.setBool(_firstLaunchKey, true);
  }

  @override
  Future<bool> isLoggedIn() async {
    return _sharedPreferences.getBool(_isLoggedInKey) ?? false;
  }

  @override
  Future<void> setLoggedIn(bool value) async {
    await _sharedPreferences.setBool(_isLoggedInKey, value);
  }

  @override
  Future<bool> isVerified() async {
    return _sharedPreferences.getBool(_isVerifiedKey) ?? false;
  }

  @override
  Future<void> setVerified(bool value) async {
    await _sharedPreferences.setBool(_isVerifiedKey, value);
  }

  @override
  Future<String?> getPendingVerifyEmail() async {
    return _sharedPreferences.getString(_pendingVerifyEmailKey);
  }

  @override
  Future<void> setPendingVerifyEmail(String? email) async {
    if (email == null) {
      await _sharedPreferences.remove(_pendingVerifyEmailKey);
    } else {
      await _sharedPreferences.setString(_pendingVerifyEmailKey, email);
    }
  }

  @override
  Future<String?> getFcmToken() async {
    return _sharedPreferences.getString(_fcmTokenKey);
  }

  @override
  Future<void> setFcmToken(String token) async {
    await _sharedPreferences.setString(_fcmTokenKey, token);
  }

  @override
  Future<String?> getLastSyncedFcmToken() async {
    return _sharedPreferences.getString(_lastSyncedFcmTokenKey);
  }

  @override
  Future<void> setLastSyncedFcmToken(String token) async {
    await _sharedPreferences.setString(_lastSyncedFcmTokenKey, token);
  }

  @override
  Future<int?> getLastSyncedFcmUserId() async {
    return _sharedPreferences.getInt(_lastSyncedFcmUserIdKey);
  }

  @override
  Future<void> setLastSyncedFcmUserId(int userId) async {
    await _sharedPreferences.setInt(_lastSyncedFcmUserIdKey, userId);
  }

  @override
  Future<void> clearStorage({bool clearAuthParams = false}) async {
    if (clearAuthParams) {
      await _sharedPreferences.remove(_tokenKey);
      await _sharedPreferences.remove(_userRoleKey);
      await _sharedPreferences.remove(_userIdKey);
      await _sharedPreferences.remove(_isLoggedInKey);
      await _sharedPreferences.remove(_isVerifiedKey);
      await _sharedPreferences.remove(_pendingVerifyEmailKey);
      await _sharedPreferences.remove(_lastSyncedFcmTokenKey);
      await _sharedPreferences.remove(_lastSyncedFcmUserIdKey);
    }
  }
}
