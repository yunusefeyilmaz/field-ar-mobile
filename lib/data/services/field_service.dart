import 'dart:convert';
import 'package:field_ar/data/models/field.dart';
import 'package:field_ar/data/models/multiPolygon.dart';
import 'package:field_ar/data/models/waterStress.dart';
import 'package:field_ar/data/models/weather.dart';
import 'package:field_ar/data/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:field_ar/core/constants/app_constants.dart';
import 'package:field_ar/core/services/secure_storage_service.dart';

class FieldService {
  final String baseUrl = AppConstants.baseUrl;
  final storage = SecureStorageService();

  FieldService();

  Future<Map<String, String>> getAuthorizationToken() async {
    final userService = UserService();
    return await userService.getAuthorizationToken();
  }

  Future<Field?> fetchField(String fieldId) async {
    final headers = await getAuthorizationToken();
    if (headers.isEmpty) {
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/field?id=$fieldId&loadModel=true'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final responseText = utf8.decode(response.bodyBytes);
      final data = json.decode(responseText);
      return Field.fromJson(data);
    } else {
      return null;
    }
  }

  Future<List<Field>?> fetchFields() async {
    final headers = await getAuthorizationToken();
    if (headers.isEmpty) {
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/fields?loadModel=true'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final responseText = utf8.decode(response.bodyBytes);
      final data = json.decode(responseText);
      return (data.map<Field>((field) => Field.fromJson(field)).toList()
          as List<Field>);
    } else {
      return null;
    }
  }

  Future<String?> createField(
    String name,
    MultiPolygon geom,
    String cropId,
    String userId,
    DateTime? plantedDate,
    DateTime? harvestedDate,
  ) async {
    final headers = await getAuthorizationToken();
    headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';
    if (headers.isEmpty) {
      return null;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/field'),
      headers: headers,
      body: json.encode({
        'field': {
          'name': name,
          'geom': geom.toJson(),
          'plantedDate':
              plantedDate != null ? '${plantedDate.toIso8601String()}Z' : null,
          'harvestedDate':
              harvestedDate != null
                  ? '${harvestedDate.toIso8601String()}Z'
                  : null,
          'crop': {'id': cropId},
          'user': {'id': userId},
        },
      }),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      return null;
    }
  }

  Future<bool> updateField(
    String fieldId,
    String name,
    MultiPolygon geom,
    String? cropId,
    DateTime? plantedDate,
    DateTime? harvestedDate,
  ) async {
    final headers = await getAuthorizationToken();
    headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';
    if (headers.isEmpty) {
      return false;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/field'),
      headers: headers,
      body: json.encode({
        'field': {
          'id': fieldId,
          'name': name,
          'geom': geom.toJson(),
          if (plantedDate != null &&
              !plantedDate.toIso8601String().endsWith('Z'))
            'plantedDate': '${plantedDate.toIso8601String()}Z',
          if (plantedDate != null &&
              plantedDate.toIso8601String().endsWith('Z'))
            'plantedDate': plantedDate.toIso8601String(),
          if (harvestedDate != null &&
              !harvestedDate.toIso8601String().endsWith('Z'))
            'harvestedDate': '${harvestedDate.toIso8601String()}Z',
          if (harvestedDate != null &&
              harvestedDate.toIso8601String().endsWith('Z'))
            'harvestedDate': harvestedDate.toIso8601String(),
          if (cropId != null) 'crop': {'id': cropId},
        },
      }),
    );

    return response.statusCode == 200;
  }

  Future<Weather?> getWeather(String fieldId) async {
    final headers = await getAuthorizationToken();
    if (headers.isEmpty) {
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/field/weather?id=$fieldId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final responseText = utf8.decode(response.bodyBytes);
      final data = json.decode(responseText);
      return Weather.fromJson(data);
    } else {
      return null;
    }
  }

  Future<bool> deleteField(String fieldId) async {
    final headers = await getAuthorizationToken();
    if (headers.isEmpty) {
      return false;
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/field?id=$fieldId'),
      headers: headers,
    );

    return response.statusCode == 200;
  }

  Future<WaterStressForecast?> getWaterStressForecast(
    String fieldId, {
    required String date,
  }) async {
    final headers = await getAuthorizationToken();
    if (headers.isEmpty) {
      return null;
    }

    final queryParameters = <String, String>{'id': fieldId, 'date': date};

    final uri = Uri.parse(
      '$baseUrl/field/predictWaterStress',
    ).replace(queryParameters: queryParameters);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final responseText = utf8.decode(response.bodyBytes);
      final data = json.decode(responseText);
      return WaterStressForecast.fromJson(data);
    } else {
      return null;
    }
  }

  Future<String?> getGlbModel(
    String fieldId, {
    double? xScale,
    double? yScale,
    double? zScale,
    double? stepSize,
    String? style,
    required String date,
  }) async {
    final headers = await getAuthorizationToken();
    if (headers.isEmpty) {
      return null;
    }

    final queryParameters = <String, String>{
      'id': fieldId,
      if (xScale != null) 'xScale': xScale.toString(),
      if (yScale != null) 'yScale': yScale.toString(),
      if (zScale != null) 'zScale': zScale.toString(),
      if (stepSize != null) 'stepSize': stepSize.toString(),
      if (style != null) 'style': style,
      'date': date,
    };

    final uri = Uri.parse(
      '$baseUrl/field/glbModel',
    ).replace(queryParameters: queryParameters);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = response.bodyBytes;
      final String base64String = base64.encode(data);
      return base64String;
    } else {
      throw Exception('Failed to load model');
    }
  }
}
