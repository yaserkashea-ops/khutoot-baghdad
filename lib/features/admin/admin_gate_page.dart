import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/auth/admin_auth_controller.dart';
import '../../core/bootstrap/app_bootstrap.dart';
import '../../core/config/admin_config.dart';
import '../../core/pwa/install_app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_toggle_button.dart';
import 'admin_shell_page.dart';

class AdminGatePage extends StatefulWidget {
  const AdminGatePage({super.key});

  @override
  State<AdminGatePage> createState() => _AdminGatePageState();
}

class _AdminGatePageState extends State<AdminGatePage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _obscure = true;
  bool _busy = false;

  bool get _demo => AdminAuthController.shared.allowsLocalDemo;

  @override
  void initState() {
    super.initState();
    if (_demo) {
      _email.text = AdminAuthController.demoLogin;
      _password.text = AdminAuthController.demoPassword;
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await AppBootstrap.ready.timeout(const Duration(seconds: 8));
    } catch (_) {}
    final auth = AdminAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!mounted) return;
    if (auth.isSignedIn) {
      _goShell();
      return;
    }
    if (!_demo && auth.email.isNotEmpty) _email.text = auth.email;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _goShell() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AdminShellPage()),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await AdminAuthController.shared.signIn(
      _email.text,
      _password.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _goShell();
      return;
    }
    setState(() {
      _error = AdminAuthController.shared.lastError ??
          'البريد أو كلمة المرور غير صحيحة';
    });
  }

  Future<void> _enterDemo() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await AdminAuthController.shared.signInLocalDemo();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _goShell();
      return;
    }
    setState(() {
      _error = AdminAuthController.shared.lastError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('دخول الإدارة'),
        actions: const [
          InstallAppIconButton(forAdmin: true),
          ThemeToggleButton(),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AdminConfig.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _demo
                      ? 'تجربة محلية — استخدم admin / admin أو اضغط دخول تجريبي'
                      : 'سجّل الدخول بحساب المشرف في Supabase',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: c.text.withValues(alpha: 0.55),
                    height: 1.4,
                  ),
                ),
                if (_demo) ...[
                  const SizedBox(height: 14),
                  FilledButton.tonal(
                    onPressed: _busy ? null : _enterDemo,
                    child: const Text('دخول تجريبي (بدون Supabase)'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أو عبر النموذج: ${AdminAuthController.demoLogin} / ${AdminAuthController.demoPassword}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: c.text.withValues(alpha: 0.5),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: _demo ? 'المستخدم' : 'البريد الإلكتروني',
                    hintText: _demo
                        ? AdminAuthController.demoLogin
                        : 'name@example.com',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    hintText: _demo ? AdminAuthController.demoPassword : null,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: c.riderAccent,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.onPrimary,
                          ),
                        )
                      : const Text('دخول'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  Text(
                    'افتح الإدارة من: …/?mode=admin',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: c.text.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
