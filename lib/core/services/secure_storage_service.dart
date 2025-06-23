import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> readToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<void> saveUserInfo(String userId) async {
    await _storage.write(key: 'id', value: userId);
  }

  Future<Map<String, String?>> readUserInfo() async {
    final userId = await _storage.read(key: 'id');
    return {'id': userId};
  }
}
