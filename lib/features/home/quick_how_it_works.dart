import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

class QuickHowItWorks extends StatelessWidget {
  const QuickHowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const steps = [
      'اختر ما تبحث عنه',
      'حدّد طريقك ووقتك',
      'افتح التفاصيل وتواصل مباشرة',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'طريقة الاستخدام',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: c.text.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusInner),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: c.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[i],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        height: 1.35,
                        color: c.text.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
