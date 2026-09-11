import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin session via Supabase Auth (email + password).
class AdminAuthController extends ChangeNotifier {
  AdminAuthController._();

  static final AdminAuthController shared = AdminAuthController._();

  StreamSubscription<AuthState>? _sub;
  bool _loaded = false;
  String? _lastError;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isLoaded => _loaded;
  bool get isSignedIn => _client?.auth.currentSession != null;
  String get email => _client?.auth.currentUser?.email?.trim() ?? '';
  String? get lastError => _lastError;

  Future<void> load() async {
    await _sub?.cancel();
    final client = _client;
    if (client != null) {
      _sub = client.auth.onAuthStateChange.listen((_) {
        notifyListeners();
      });
    }
    _loaded = true;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _lastError = null;
    final client = _client;
    if (client == null) {
      _lastError = 'خدمة المصادقة غير جاهزة';
      notifyListeners();
      return false;
    }
    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _lastError = _mapAuthError(e);
      notifyListeners();
      return false;
    } catch (_) {
      _lastError = 'تعذر تسجيل الدخول. تحقق من الاتصال وحاول مجدداً.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      await client.auth.signOut();
    }
    notifyListeners();
  }

  Future<void> updatePassword(String newPassword) async {
    if (newPassword.length < 8) {
      throw ArgumentError('كلمة المرور يجب أن تكون 8 أحرف على الأقل');
    }
    final client = _client;
    if (client == null) {
      throw StateError('خدمة المصادقة غير جاهزة');
    }
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  String _mapAuthError(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return 'البريد أو كلمة المرور غير صحيحة';
    }
    if (m.contains('email')) {
      return 'تحقق من البريد الإلكتروني';
    }
    return e.message;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
