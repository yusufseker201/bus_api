import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService({
    http.Client? client,
    String? apiBaseUrl,
  })  : _client = client ?? http.Client(),
        apiBaseUrl = apiBaseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://127.0.0.1:8000/api',
            );

  static const String _tokenKey = 'api_token';
  static const String _emailKey = 'auth_email';

  final http.Client _client;
  final String apiBaseUrl;

  Future<String> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/login/'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{
        'email': email.trim(),
        'password': password,
      }),
    );

    final decodedBody = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = (decodedBody['detail'] as String?) ?? 'Giriş başarısız oldu.';
      throw AuthException(message);
    }

    final token = decodedBody['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const AuthException('Token alınamadı.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email.trim());
    return token;
  }

  Future<String> manualLogin(String email, String password) {
    return login(email, password);
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
