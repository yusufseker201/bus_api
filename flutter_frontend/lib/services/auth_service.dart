import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService({
    http.Client? client,
    String? apiBaseUrl,
  })  : _client = client ?? http.Client(),
        apiBaseUrl = apiBaseUrl ??
            (kIsWeb
                ? '/api'
                : const String.fromEnvironment(
                    'API_BASE_URL',
                    defaultValue: 'http://10.0.2.2:8000/api',
                  ));

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
      final message =
          (decodedBody['detail'] as String?) ?? 'Giriş başarısız oldu.';
      throw AuthException(message);
    }

    final token = decodedBody['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const AuthException('Token alınamadı.');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_emailKey, email.trim());
    } catch (_) {
      // Keep the in-memory login active even when browser storage is unavailable.
    }
    return token;
  }

  Future<String> manualLogin(String email, String password) {
    return login(email, password);
  }

  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/auth/register/'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{
        'email': email.trim(),
        'password': password,
        'confirm_password': confirmPassword,
      }),
    );

    final decodedBody = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _messageFromBody(
          decodedBody,
          fallback: 'Kayıt oluşturulamadı.',
        ),
      );
    }
  }

  Future<PasswordResetChallenge> requestPasswordReset({
    required String identifier,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/auth/password-reset/request/'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{
        'identifier': identifier.trim(),
      }),
    );

    final decodedBody = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _messageFromBody(
          decodedBody,
          fallback: 'Şifre sıfırlama isteği oluşturulamadı.',
        ),
      );
    }

    return PasswordResetChallenge(
      message: _stringFromBody(decodedBody['detail']) ??
          'Şifre sıfırlama bilgileri hazır.',
      uid: _stringFromBody(decodedBody['uid']),
      token: _stringFromBody(decodedBody['token']),
    );
  }

  Future<void> confirmPasswordReset({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/auth/password-reset/confirm/'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{
        'uid': uid,
        'token': token,
        'new_password': newPassword,
        'confirm_password': newPassword,
      }),
    );

    final decodedBody = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _messageFromBody(
          decodedBody,
          fallback: 'Şifre güncellenemedi.',
        ),
      );
    }
  }

  Future<String?> getSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {
      // Ignore storage failures; the token is still usable for this session.
    }
  }

  Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emailKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_emailKey);
    } catch (_) {
      // Ignore storage failures while logging out.
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{'detail': decoded.toString()};
  }

  String _messageFromBody(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    final detail = _stringFromBody(body['detail']);
    if (detail != null && detail.isNotEmpty) {
      return detail;
    }

    for (final value in body.values) {
      final message = _stringFromBody(value);
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }

  String? _stringFromBody(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      return value;
    }

    if (value is List) {
      final messages = value
          .map((item) => item?.toString().trim())
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList();
      if (messages.isNotEmpty) {
        return messages.join(' ');
      }
    }

    return value.toString();
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PasswordResetChallenge {
  const PasswordResetChallenge({
    required this.message,
    this.uid,
    this.token,
  });

  final String message;
  final String? uid;
  final String? token;

  bool get canResetNow => uid != null && uid!.isNotEmpty && token != null && token!.isNotEmpty;
}
