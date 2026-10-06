import 'package:flutter/material.dart';

import '../../../core/auth/publisher_auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../directory_mode.dart';

enum EmptyListingsKind {
  promptSearch,
  noMatch,
  error,
  incompleteSearch,
}

class EmptyListingsState extends StatelessWidget {
  const EmptyListingsState({
    super.key,
    required this.onPublish,
    this.onInvite,
    this.kind = EmptyListingsKind.noMatch,
    this.onRetry,
    this.forRiders = false,
    this.onAdjustSearch,
  });

  final VoidCallback onPublish;
  final VoidCallback? onInvite;
  final EmptyListingsKind kind;
  final VoidCallback? onRetry;
  final bool forRiders;
  final VoidCallback? onAdjustSearch;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    final mode = DirectoryMode(riders: forRiders);
    final accent = mode.accent(c);

    final (title, body, IconData icon) = switch (kind) {
      EmptyListingsKind.promptSearch => (
          mode.emptyPromptTitle,
          mode.emptyPromptBody,
          Icons.search_rounded,
        ),
      EmptyListingsKind.noMatch => (
          mode.emptyMatchTitle,
          mode.emptyMatchBody,
          forRiders ? Icons.hail_outlined : Icons.route_outlined,
        ),
      EmptyListingsKind.incompleteSearch => (
          'أكمل البحث',
          'اختر منطقة الانطلاق والوجهة معاً لعرض النتائج.',
          Icons.search_rounded,
        ),
      EmptyListingsKind.error => (
          'تعذر التحميل',
          'تحقق من الاتصال ثم أعد المحاولة',
          Icons.wifi_off_rounded,
        ),
    };

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 28, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: accent.withValues(alpha: 0.85)),
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
                minimumSize: const Size(180, 48),
                backgroundColor: accent,
              ),
              child: const Text('إعادة المحاولة'),
            )
          else if (kind == EmptyListingsKind.noMatch && onInvite != null) ...[
            FilledButton(
              onPressed: onInvite,
              style: FilledButton.styleFrom(
                minimumSize: const Size(180, 46),
                backgroundColor: accent,
              ),
              child: Text(mode.inviteCta),
            ),
            if (onAdjustSearch != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onAdjustSearch,
                child: const Text('تعديل البحث'),
              ),
            ],
          ]
          else if (kind == EmptyListingsKind.incompleteSearch &&
              onAdjustSearch != null)
            FilledButton(
              onPressed: onAdjustSearch,
              style: FilledButton.styleFrom(
                minimumSize: const Size(180, 48),
                backgroundColor: accent,
              ),
              child: const Text('تعديل البحث'),
            )
          else
            OutlinedButton(
              onPressed: onPublish,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(180, 46),
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.45)),
              ),
              child: Text(
                PublisherAuthController.shared.isLoggedIn
                    ? 'حسابي'
                    : mode.fabLabel,
              ),
            ),
        ],
      ),
    );
  }
}
