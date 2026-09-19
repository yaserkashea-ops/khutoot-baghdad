import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Admin session via Supabase Auth (email + password).
class AdminAuthController extends ChangeNotifier {
  AdminAuthController._();

  static final AdminAuthController shared = AdminAuthController._();

  /// Fixed debug/trial credentials (local flutter run only).
  static const demoLogin = 'admin';
  static const demoPassword = 'admin';

  StreamSubscription<AuthState>? _sub;
  bool _loaded = false;
  String? _lastError;
  bool _localDemoSignedIn = false;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get allowsLocalDemo =>
      kDebugMode || !SupabaseConfig.isConfigured;

  bool get isLoaded => _loaded;
  bool get isSignedIn =>
      _localDemoSignedIn || _client?.auth.currentSession != null;
  String get email =>
      _localDemoSignedIn
          ? demoLogin
          : (_client?.auth.currentUser?.email?.trim() ?? '');
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

  bool _isDemoCredentials(String email, String password) {
    final e = email.trim().toLowerCase();
    final p = password.trim();
    return (e == demoLogin || e == '$demoLogin@local') && p == demoPassword;
  }

  Future<bool> signInLocalDemo() async {
    if (!allowsLocalDemo) {
      _lastError = 'الدخول التجريبي متاح في وضع التطوير فقط';
      notifyListeners();
      return false;
    }
    _lastError = null;
    _localDemoSignedIn = true;
    notifyListeners();
    return true;
  }

  Future<bool> signIn(String email, String password) async {
    _lastError = null;
    final cleanedEmail = email.trim();
    final cleanedPassword = password.trim();
    if (cleanedEmail.isEmpty || cleanedPassword.isEmpty) {
      _lastError = allowsLocalDemo
          ? 'أدخل $demoLogin / $demoPassword أو اضغط دخول تجريبي'
          : 'أدخل البريد وكلمة المرور';
      notifyListeners();
      return false;
    }

    // Local / debug trial — works even if Supabase defaults are present.
    if (allowsLocalDemo && _isDemoCredentials(cleanedEmail, cleanedPassword)) {
      _localDemoSignedIn = true;
      notifyListeners();
      return true;
    }

    final client = _client;
    if (client == null) {
      if (allowsLocalDemo) {
        _localDemoSignedIn = true;
        notifyListeners();
        return true;
      }
      _lastError = 'خدمة المصادقة غير جاهزة';
      notifyListeners();
      return false;
    }

    try {
      await client.auth.signInWithPassword(
        email: cleanedEmail.toLowerCase(),
        password: cleanedPassword,
      );
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint(
        'Admin sign-in AuthException: ${e.statusCode} ${e.code} ${e.message}',
      );
      if (allowsLocalDemo && _isDemoCredentials(cleanedEmail, cleanedPassword)) {
        _localDemoSignedIn = true;
        notifyListeners();
        return true;
      }
      _lastError = _mapAuthError(e);
      if (allowsLocalDemo) {
        _lastError =
            '$_lastError\nللتجربة المحلية استخدم: $demoLogin / $demoPassword';
      }
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Admin sign-in error: $e');
      if (allowsLocalDemo && _isDemoCredentials(cleanedEmail, cleanedPassword)) {
        _localDemoSignedIn = true;
        notifyListeners();
        return true;
      }
      _lastError = allowsLocalDemo
          ? 'تعذر الاتصال بـ Supabase. للتجربة: $demoLogin / $demoPassword'
          : 'تعذر تسجيل الدخول. تحقق من الاتصال وحاول مجدداً.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _localDemoSignedIn = false;
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
