import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/admin_config.dart';
import 'core/pwa/install_prompt_host.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/admin/admin_gate_page.dart';
import 'features/listings/listings_page.dart';

class MasaratApp extends StatelessWidget {
  const MasaratApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.shared,
      builder: (context, _) {
        return MaterialApp(
          title: 'خطوط بغداد',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.shared.mode,
          locale: const Locale('ar'),
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final clamped = mq.copyWith(
              textScaler: TextScaler.linear(
                mq.textScaler.scale(1).clamp(0.9, 1.2),
              ),
            );
            return MediaQuery(
              data: clamped,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: InstallPromptHost(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
          initialRoute: '/',
          onGenerateRoute: (settings) {
            final name = settings.name ?? '/';
            if (name == AdminConfig.path ||
                name.startsWith('${AdminConfig.path}/')) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const AdminGatePage(),
              );
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ListingsPage(),
            );
          },
        );
      },
    );
  }
}
