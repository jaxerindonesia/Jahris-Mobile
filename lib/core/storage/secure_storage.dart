import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return const SecureStorage(FlutterSecureStorage());
});

class SecureStorage {
  const SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _rememberMeKey = 'remember_me';
  static const _sessionCookieKey = 'session_cookie';
  static const _cookieSessionKey = 'cookie_session_active';
  static const _faceConsentPrefix = 'face_consent_';
  static const _languageKey = 'app_language';

  Future<String?> readLanguage() => _storage.read(key: _languageKey);
  Future<void> writeLanguage(String code) =>
      _storage.write(key: _languageKey, value: code);

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<bool> readRememberMe() async {
    return await _storage.read(key: _rememberMeKey) == 'true';
  }

  Future<String?> readSessionCookie() => _storage.read(key: _sessionCookieKey);

  Future<bool> hasCookieSession() async =>
      await _storage.read(key: _cookieSessionKey) == 'true';

  Future<void> writeSessionCookie(String value) =>
      _storage.write(key: _sessionCookieKey, value: value);

  Future<bool?> readFaceConsent(String employeeId) async {
    final value = await _storage.read(key: '$_faceConsentPrefix$employeeId');
    if (value == null) return null;
    return value == 'true';
  }

  Future<void> writeFaceConsent(String employeeId, bool accepted) => _storage
      .write(key: '$_faceConsentPrefix$employeeId', value: accepted.toString());

  Future<void> saveCookieSession({required bool rememberMe}) async {
    await Future.wait([
      _storage.write(key: _cookieSessionKey, value: 'true'),
      _storage.write(key: _rememberMeKey, value: rememberMe.toString()),
    ]);
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required bool rememberMe,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _rememberMeKey, value: rememberMe.toString()),
    ]);
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _rememberMeKey),
      _storage.delete(key: _sessionCookieKey),
      _storage.delete(key: _cookieSessionKey),
    ]);
  }
}
