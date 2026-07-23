import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../utils/app_constants.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: AppConstants.googleWebClientId,
  );

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.postRequest(
        '/api/auth/login',
        {
          'email': email,
          'password': password,
        },
      );

      print('LOGIN STATUS: ${response.statusCode}');
      print('LOGIN BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);

        return {
          'success': true,
          'message': 'Login successful',
        };
      }

      String message = 'Login failed';
      try {
        final data = jsonDecode(response.body);
        message = data['message'] ?? data['error'] ?? message;
      } catch (_) {}

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      print('LOGIN EXCEPTION: $e');
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final response = await _apiService.postRequest(
        '/api/auth/register',
        {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      print('REGISTER STATUS: ${response.statusCode}');
      print('REGISTER BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Registration successful',
        };
      }

      String message = 'Registration failed';
      try {
        final data = jsonDecode(response.body);
        message = data['message'] ?? data['error'] ?? message;
      } catch (_) {}

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      print('REGISTER EXCEPTION: $e');
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Google sign-in cancelled',
        };
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        return {
          'success': false,
          'message': 'Unable to get Google ID token',
        };
      }

      final response = await _apiService.postRequest(
        '/api/auth/google',
        {'idToken': idToken},
      );

      print('GOOGLE LOGIN STATUS: ${response.statusCode}');
      print('GOOGLE LOGIN BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);

        return {
          'success': true,
          'message': data['message'] ?? 'Google login successful',
        };
      }

      String message = 'Google login failed';
      try {
        final data = jsonDecode(response.body);
        message = data['message'] ?? data['error'] ?? message;
      } catch (_) {}

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      print('GOOGLE LOGIN EXCEPTION: $e');
      return {
        'success': false,
        'message': 'Exception: $e',
      };
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<int?> getUserIdFromToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payload);
      final id = decoded['id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
