import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class SessionState extends ChangeNotifier {
  SessionState(this._authService);

  final AuthService _authService;

  bool _isReady = false;
  String? _token;
  String? _email;

  bool get isReady => _isReady;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  String? get token => _token;
  String? get email => _email;

  Future<void> load() async {
    _token = await _authService.getSavedToken();
    _email = await _authService.getSavedEmail();
    _isReady = true;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final token = await _authService.login(email, password);
    _token = token;
    _email = email.trim();
    _isReady = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.clearToken();
    _token = null;
    _email = null;
    notifyListeners();
  }
}
