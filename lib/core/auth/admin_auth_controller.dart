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
    final cleanedEmail = email.trim().toLowerCase();
    final cleanedPassword = password.trim();
    if (cleanedEmail.isEmpty || cleanedPassword.isEmpty) {
      _lastError = 'أدخل البريد وكلمة المرور';
      notifyListeners();
      return false;
    }
    try {
      await client.auth.signInWithPassword(
        email: cleanedEmail,
        password: cleanedPassword,
      );
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('Admin sign-in AuthException: ${e.statusCode} ${e.code} ${e.message}');
      _lastError = _mapAuthError(e);
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Admin sign-in error: $e');
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
    final code = (e.code ?? '').toLowerCase();
    if (code.contains('email_not_confirmed') ||
        m.contains('email not confirmed') ||
        m.contains('not confirmed')) {
      return 'البريد غير مؤكَّد. من Supabase → Authentication → Users افتح المستخدم وفعّل Confirm email أو أعد إنشاءه مع تفعيل Auto Confirm User.';
    }
    if (code.contains('invalid_credentials') ||
        m.contains('invalid login') ||
        m.contains('invalid credentials')) {
      return 'البريد أو كلمة المرور غير صحيحة. تأكد أن المستخدم موجود في Authentication → Users لنفس مشروع خطوط بغداد.';
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
