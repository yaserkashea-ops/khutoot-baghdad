import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Two publish actions: a driver line and a rider request, never mixed in one button.
class AddPartyCtas extends StatelessWidget {
  const AddPartyCtas({
    super.key,
    required this.onAddLine,
    required this.onAddRequest,
    this.primaryIsRequest = false,
  });

  final VoidCallback onAddLine;
  final VoidCallback onAddRequest;

  /// Rider browsing driver lines → request is primary. Driver browsing requests → line is primary.
  final bool primaryIsRequest;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final line = _PartyButton(
      label: 'اضافة خط سائق',
      filled: !primaryIsRequest,
      color: c.primary,
      onPressed: onAddLine,
    );
    final request = _PartyButton(
      label: 'اضافة طلب راكب',
      filled: primaryIsRequest,
      color: c.opportunity,
      onPressed: onAddRequest,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (primaryIsRequest) request else line,
        const SizedBox(height: 8),
        if (primaryIsRequest) line else request,
      ],
    );
  }
}

class _PartyButton extends StatelessWidget {
  const _PartyButton({
    required this.label,
    required this.filled,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Text(label);
    final size = const Size.fromHeight(46);
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: size,
          backgroundColor: color,
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: size,
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.45)),
      ),
      child: child,
    );
  }
}
