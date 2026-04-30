import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:si2_p1_mobile/config/env.dart';

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveToken(String token) async {
    await _storage.write(key: Env.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: Env.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: Env.tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> getString(String key) async {
    return _storage.read(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
