import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'admin_app.dart';
import 'core/auth/admin_auth_controller.dart';
import 'core/theme/theme_controller.dart';

/// نقطة دخول مستقلة للوحة التحكم:
/// `flutter run -t lib/admin_main.dart -d chrome`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await ThemeController.shared.load();
  await AdminAuthController.shared.load();
  runApp(const AdminApp());
}
