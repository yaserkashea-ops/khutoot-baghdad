import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_app.dart';
import 'core/auth/admin_auth_controller.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/theme_controller.dart';
import 'data/admin_repository.dart';
import 'data/listings_repository.dart';

/// نقطة دخول مستقلة للوحة التحكم:
/// `flutter run -t lib/admin_main.dart -d chrome`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await Future.wait<void>([
    ThemeController.shared.load(),
    _initSupabase(),
  ]);
  await AdminAuthController.shared.load();
  runApp(const AdminApp());
}

Future<void> _initSupabase() async {
  if (!SupabaseConfig.isConfigured) return;
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
