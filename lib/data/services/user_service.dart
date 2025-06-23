import 'dart:convert';
import 'package:field_ar/data/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:field_ar/core/constants/app_constants.dart';
import 'package:field_ar/core/services/secure_storage_service.dart';

class UserService {
  final String baseUrl = AppConstants.baseUrl;
  final storage = SecureStorageService();

  UserService();

  Future<Map<String, String?>> getUserInfo() async {
    final userInfo = await storage.readUserInfo();
    return userInfo;
  }

  Future<Map<String, String>> getAuthorizationToken() async {
    final token = await storage.readToken();
    if (token == null) {
      return <String, String>{};
    }
    final headers = <String, String>{};
    headers['Authorization'] = 'Bearer $token';

    return headers;
  }

  Future<void> saveToken(String token) async {
    await storage.saveToken(token);
  }

  Future<void> logoutUser() async {
    await storage.deleteToken();
  }

  Future<User?> fetchUser() async {
    final headers = await getAuthorizationToken();
    if (headers.isEmpty) {
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return User.fromJson(data);
    } else {
      return null;
    }
  }

  Future<User?> registerUser(
    String username,
    String name,
    String surname,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'user': {
          'username': username,
          'name': name,
          'surname': surname,
          'password': password,
        },
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return User.fromJson(data);
    } else if (response.statusCode == 400) {
      return null; // Bad request
    } else {
      return null; // Other errors
    }
  }

  Future<User?> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'login': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token'] as String;
      await saveToken(token);
      await storage.saveUserInfo(data['id'] as String);
      return User.fromJson(data);
    } else {
      return null; // Other errors
    }
  }
}
