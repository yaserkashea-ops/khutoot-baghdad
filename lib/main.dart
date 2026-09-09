import 'package:flutter/material.dart';

import 'app.dart';
import 'core/auth/admin_auth_controller.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hash URLs (#/ and #/admin) work reliably on static hosts like GitHub Pages.
  await ThemeController.shared.load();
  await AdminAuthController.shared.load();
  runApp(const MasaratApp());
}
