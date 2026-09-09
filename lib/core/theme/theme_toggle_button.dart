import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'theme_controller.dart';

/// App-bar control: tap toggles light/dark; long-press opens light/dark/system.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  Future<void> _pickMode(BuildContext context) async {
    final controller = ThemeController.shared;
    final chosen = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) {
        final c = ctx.colors;
        Widget tile({
          required ThemeMode mode,
          required String title,
          required IconData icon,
        }) {
          final selected = controller.mode == mode;
          return ListTile(
            leading: Icon(icon, color: selected ? c.primary : c.text),
            title: Text(
              title,
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: c.text,
              ),
            ),
            trailing: selected
                ? Icon(Icons.check, color: c.primary, size: 20)
                : null,
            onTap: () => Navigator.pop(ctx, mode),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'المظهر',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              tile(
                mode: ThemeMode.light,
                title: 'نهاري',
                icon: Icons.light_mode_outlined,
              ),
              tile(
                mode: ThemeMode.dark,
                title: 'ليلي',
                icon: Icons.dark_mode_outlined,
              ),
              tile(
                mode: ThemeMode.system,
                title: 'حسب النظام',
                icon: Icons.brightness_auto_outlined,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (chosen != null) await controller.setMode(chosen);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.shared,
      builder: (context, _) {
        final dark = ThemeController.shared.isDarkEffective(context);
        return IconButton(
          tooltip: dark ? 'الوضع النهاري' : 'الوضع الليلي',
          onPressed: () => ThemeController.shared.toggle(context),
          onLongPress: () => _pickMode(context),
          icon: Icon(
            dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        );
      },
    );
  }
}
