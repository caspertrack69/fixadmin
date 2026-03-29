import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStore {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({
    required FlutterSecureStorage storage,
  }) : _storage = storage;

  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;
  String? _cachedToken;
  bool _isLoaded = false;

  @override
  Future<String?> readToken() async {
    if (_isLoaded) {
      return _cachedToken;
    }

    _cachedToken = await _storage.read(key: _tokenKey);
    _isLoaded = true;
    return _cachedToken;
  }

  @override
  Future<void> saveToken(String token) async {
    _cachedToken = token;
    _isLoaded = true;
    await _storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<void> clearToken() async {
    _cachedToken = null;
    _isLoaded = true;
    await _storage.delete(key: _tokenKey);
  }
}
