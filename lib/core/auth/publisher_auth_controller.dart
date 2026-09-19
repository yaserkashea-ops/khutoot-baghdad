import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'publisher_session_store.dart';

/// Publisher accounts (username/phone + password, no OTP).
/// Session is stored on-device (SharedPreferences + web localStorage/cookie)
/// so it survives reopening via link or installed PWA on the same origin.
class PublisherAuthController extends ChangeNotifier {
  PublisherAuthController._();
  static final PublisherAuthController shared = PublisherAuthController._();

  String? _token;
  String? _login;
  String? _accountId;
  String? _lastError;
  bool _loaded = false;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  String? get token => _token;
  String? get login => _login;
  String? get accountId => _accountId;
  String? get lastError => _lastError;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final data = await PublisherSessionStore.load();
      if (data != null && data.isValid) {
        _token = data.token;
        _accountId = data.accountId;
        _login = data.login;
      } else {
        _token = null;
        _accountId = null;
        _login = null;
      }
    } catch (e) {
      debugPrint('PublisherAuthController.load failed: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<bool> register(String login, String password) async {
    return _authRpc('publisher_register', login, password);
  }

  Future<bool> signIn(String login, String password) async {
    return _authRpc('publisher_login', login, password);
  }

  Future<bool> _authRpc(String fn, String login, String password) async {
    _lastError = null;
    final client = _clientOrNull();
    if (client == null) {
      _lastError = 'الاتصال غير جاهز. حاول مجدداً.';
      notifyListeners();
      return false;
    }
    try {
      final raw = await client.rpc(
        fn,
        params: {
          'p_login': login.trim(),
          'p_password': password,
        },
      );
      final map = Map<String, dynamic>.from(raw as Map);
      await _persist(
        token: map['token']?.toString() ?? '',
        accountId: map['account_id']?.toString() ?? '',
        login: map['login']?.toString() ?? login.trim(),
      );
      notifyListeners();
      return isLoggedIn;
    } on PostgrestException catch (e) {
      _lastError = _mapError(e.message);
      notifyListeners();
      return false;
    } catch (_) {
      _lastError = 'تعذر إتمام العملية. حاول مجدداً.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await PublisherSessionStore.clear();
    _token = null;
    _login = null;
    _accountId = null;
    notifyListeners();
  }

  Future<void> _persist({
    required String token,
    required String accountId,
    required String login,
  }) async {
    final data = PublisherSessionData(
      token: token,
      accountId: accountId,
      login: login,
    );
    if (!data.isValid) return;
    await PublisherSessionStore.save(data);
    _token = data.token;
    _accountId = data.accountId;
    _login = data.login;
  }

  SupabaseClient? _clientOrNull() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String _mapError(String message) {
    final m = message.toUpperCase();
    if (m.contains('LOGIN_TAKEN')) return 'هذا الاسم أو الرقم مستخدم مسبقاً';
    if (m.contains('LOGIN_TOO_SHORT')) {
      return 'اكتب اسماً أو رقماً أوضح (٣ أحرف على الأقل)';
    }
    if (m.contains('PASSWORD_TOO_SHORT')) {
      return 'كلمة المرور قصيرة جداً (٤ أحرف على الأقل)';
    }
    if (m.contains('BAD_CREDENTIALS')) {
      return 'اسم المستخدم/الرقم أو كلمة المرور غير صحيحة';
    }
    if (m.contains('SESSION_EXPIRED')) {
      return 'انتهت الجلسة. سجّل الدخول مجدداً';
    }
    if (m.contains('GEN_SALT') || m.contains('CRYPT') || m.contains('PGCRYPTO')) {
      return 'إعداد قاعدة البيانات غير مكتمل. تواصل مع الإدارة.';
    }
    return 'تعذر إتمام العملية';
  }
}
