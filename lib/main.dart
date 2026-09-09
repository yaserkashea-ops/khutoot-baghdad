import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_app.dart';
import 'app.dart';
import 'core/auth/admin_auth_controller.dart';
import 'core/config/app_hosts.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/theme_controller.dart';
import 'data/admin_repository.dart';
import 'data/listings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.shared.load();
  await AdminAuthController.shared.load();
  await _initSupabase();

  // موقع الإدارة المنفصل يجب أن يفتح لوحة التحكم فقط، حتى لو وُجد index.html.
  if (AppHosts.isAdminHost) {
    runApp(const AdminApp());
  } else {
    runApp(const MasaratApp());
  }
}

Future<void> _initSupabase() async {
  if (!SupabaseConfig.isConfigured) {
    debugPrint(
      'Supabase غير مُعدّ — البيانات محلية. '
      'ضع SUPABASE_URL و SUPABASE_ANON_KEY في supabase_config.dart',
    );
    return;
  }
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );
  final client = Supabase.instance.client;
  ListingsRepository.bindShared(client);
  AdminRepository.bindShared(
    listings: ListingsRepository.shared,
    client: client,
  );
}
