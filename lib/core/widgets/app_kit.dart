import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
    this.busy = false,
    this.outlined = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final bool busy;
  final bool outlined;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);
    final min = const Size(AppTokens.minTap, AppTokens.minTap);
    if (outlined) {
      final button = OutlinedButton(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: min,
          foregroundColor: color,
          side: color == null ? null : BorderSide(color: color!.withValues(alpha: 0.45)),
        ),
        child: child,
      );
      return expanded ? SizedBox(width: double.infinity, child: button) : button;
    }
    final button = FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: min,
        backgroundColor: color,
      ),
      child: child,
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.lines = 4});

  final int lines;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.outline.withValues(alpha: 0.35);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          for (var i = 0; i < lines; i++) ...[
            Container(
              height: 92,
              decoration: BoxDecoration(
                color: base,
                borderRadius: AppTokens.borderRadius,
              ),
            ),
            if (i < lines - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.search_off_rounded,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          AppButton(label: actionLabel, onPressed: onAction, expanded: false),
        ],
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.onRetry,
    this.title = 'تعذر تحميل الخطوط حالياً',
    this.body = 'تحقق من اتصالك وحاول مرة أخرى.',
  });

  final VoidCallback onRetry;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      body: body,
      actionLabel: 'إعادة المحاولة',
      onAction: onRetry,
      icon: Icons.wifi_off_rounded,
    );
  }
}

class FormStepper extends StatelessWidget {
  const FormStepper({
    super.key,
    required this.step,
    required this.labels,
  });

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final parts = [
      for (var i = 0; i < labels.length; i++)
        i == step ? '«${i + 1} ${labels[i]}»' : '${i + 1} ${labels[i]}',
    ];
    return Text(
      parts.join(' → '),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: primary,
      ),
    );
  }
}
