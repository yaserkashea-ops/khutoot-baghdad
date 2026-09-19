import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_app.dart';
import 'app.dart';
import 'core/auth/admin_auth_controller.dart';
import 'core/auth/publisher_auth_controller.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/config/admin_contact.dart';
import 'core/config/app_hosts.dart';
import 'core/config/supabase_config.dart';
import 'core/data/places_catalog.dart';
import 'core/theme/theme_controller.dart';
import 'data/admin_repository.dart';
import 'data/listings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  final isAdmin = AppHosts.isAdminHost;

  // Paint UI immediately — never wait on network before first frame
  // (waiting here caused the permanent green splash on slow/mobile).
  if (isAdmin) {
    runApp(const AdminApp());
  } else {
    runApp(const MasaratApp());
  }

  try {
    await Future.wait<void>([
      ThemeController.shared.load(),
      _initSupabase(),
      if (!isAdmin) PublisherAuthController.shared.load(),
    ]).timeout(const Duration(seconds: 8));
    if (isAdmin) {
      await AdminAuthController.shared
          .load()
          .timeout(const Duration(seconds: 5));
    }
  } catch (_) {
    // UI already visible; listings/admin can show errors if needed.
  } finally {
    AppBootstrap.markReady();
  }

  // Background only — never block first paint.
  unawaited(PlacesCatalog.shared.refresh());
  unawaited(AdminContact.shared.refresh());
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
