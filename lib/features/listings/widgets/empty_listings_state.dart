import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum EmptyListingsKind {
  /// No place filters yet.
  promptSearch,

  /// Filters applied but nothing matched.
  noMatch,

  /// Load failed.
  error,
}

class EmptyListingsState extends StatelessWidget {
  const EmptyListingsState({
    super.key,
    required this.onPublish,
    this.kind = EmptyListingsKind.noMatch,
    this.onRetry,
  });

  final VoidCallback onPublish;
  final EmptyListingsKind kind;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);

    final (title, body, IconData icon) = switch (kind) {
      EmptyListingsKind.promptSearch => (
          'ابدأ البحث',
          'اختر المنطقة والوجهة لعرض الخطوط',
          Icons.search_rounded,
        ),
      EmptyListingsKind.noMatch => (
          'لم نجد خطوطاً مطابقة',
          'جرّب توسيع الفلاتر أو انشر طلبك ليراك الآخرون',
          Icons.route_outlined,
        ),
      EmptyListingsKind.error => (
          'تعذر تحميل الخطوط',
          'تحقق من الاتصال ثم أعد المحاولة',
          Icons.wifi_off_rounded,
        ),
    };

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 28, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: c.primary.withValues(alpha: 0.85)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
              color: c.text.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 20),
          if (kind == EmptyListingsKind.error && onRetry != null)
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                minimumSize: const Size(180, 46),
              ),
              child: const Text('إعادة المحاولة'),
            )
          else
            OutlinedButton(
              onPressed: onPublish,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(180, 46),
              ),
              child: const Text('انشر طلباً'),
            ),
        ],
      ),
    );
  }
}
