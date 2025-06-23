import 'dart:convert';
import 'package:field_ar/data/models/crop.dart';
import 'package:field_ar/data/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:field_ar/core/constants/app_constants.dart';

class CropService {
  final String baseUrl = AppConstants.baseUrl;
  CropService();

  Future<Map<String, String>> getAuthorizationToken() async {
    final userService = UserService();
    return await userService.getAuthorizationToken();
  }

  Future<List<Crop>?> fetchCrops() async {
    final headers = await getAuthorizationToken();
    if (headers.isEmpty) {
      return null;
    }

    headers['Content-Type'] = 'application/json; charset=utf-8';
    headers['Accept'] = 'application/json; charset=utf-8';

    final response = await http.get(
      Uri.parse('$baseUrl/crops'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return (data as List).map((crop) => Crop.fromJson(crop)).toList();
    } else {
      return null;
    }
  }
}
