import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the auth token securely (Keychain on iOS, Keystore on Android).
///
/// On desktop (esp. unsigned macOS debug builds) the platform keychain can
/// throw `errSecMissingEntitlement`. Rather than break login, we fall back to
/// an in-memory token for the session so development works everywhere. Mobile
/// builds keep using real secure storage.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'bifix_auth_token';

  // Session fallback used only when secure storage is unavailable.
  static String? _memoryToken;

  Future<String?> read() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('TokenStorage.read fell back to memory: $e');
      return _memoryToken;
    }
  }

  Future<void> write(String token) async {
    _memoryToken = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('TokenStorage.write fell back to memory: $e');
    }
  }

  Future<void> clear() async {
    _memoryToken = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('TokenStorage.clear fell back to memory: $e');
    }
  }
}
