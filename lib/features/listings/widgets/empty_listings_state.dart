import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class EmptyListingsState extends StatelessWidget {
  const EmptyListingsState({super.key, required this.onPublish});

  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(28, 48, 28, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'لا يوجد إعلانات مطابقة الآن، جرّب توسيع الفلاتر أو كن أول من ينشر في هذه المنطقة',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w400,
              fontSize: 15,
              height: 1.6,
              color: c.text.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onPublish,
            style: TextButton.styleFrom(
              foregroundColor: c.primary,
              textStyle: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            child: const Text('نشر إعلان'),
          ),
        ],
      ),
    );
  }
}
