import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/admin_config.dart';

/// Local email/password gate + session for the admin panel.
class AdminAuthController extends ChangeNotifier {
  AdminAuthController._();

  static final AdminAuthController shared = AdminAuthController._();

  static const _emailKey = 'masarat_admin_email';
  static const _passwordKey = 'masarat_admin_password';
  static const _sessionKey = 'masarat_admin_session';

  String _email = AdminConfig.defaultEmail;
  String _password = AdminConfig.defaultPassword;
  bool _signedIn = false;
  bool _loaded = false;

  String get email => _email;
  bool get isSignedIn => _signedIn;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString(_emailKey) ?? AdminConfig.defaultEmail;
    _password = prefs.getString(_passwordKey) ?? AdminConfig.defaultPassword;
    _signedIn = prefs.getBool(_sessionKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  bool validate(String email, String password) {
    return email.trim().toLowerCase() == _email.trim().toLowerCase() &&
        password == _password;
  }

  Future<bool> signIn(String email, String password) async {
    if (!validate(email, password)) return false;
    _signedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    _signedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, false);
    notifyListeners();
  }

  /// Change login credentials (stored locally until backend auth is wired).
  Future<void> updateCredentials({
    required String email,
    required String password,
  }) async {
    final nextEmail = email.trim();
    if (nextEmail.isEmpty || password.isEmpty) {
      throw ArgumentError('البريد وكلمة المرور مطلوبان');
    }
    if (!nextEmail.contains('@')) {
      throw ArgumentError('صيغة البريد غير صحيحة');
    }
    if (password.length < 6) {
      throw ArgumentError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
    }
    _email = nextEmail;
    _password = password;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, _email);
    await prefs.setString(_passwordKey, _password);
    notifyListeners();
  }
}
