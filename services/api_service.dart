import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_constants.dart';

class ApiService {
  Future<http.Response> postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    print('POST URL: $uri');

    return await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));
  }

  Future<http.Response> getRequest(
    String endpoint, {
    String? token,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    print('GET URL: $uri');

    return await http
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 8));
  }

  Future<http.Response> deleteRequest(
    String endpoint, {
    String? token,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    print('DELETE URL: $uri');

    return await http
        .delete(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 8));
  }

  Future<http.Response> putRequest(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    print('PUT URL: $uri');

    return await http
        .put(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));
  }
}