import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'preview_mode.dart';

/// Small non-blocking pill so a preview build cannot be mistaken for production.
class PreviewModeBanner extends StatelessWidget {
  const PreviewModeBanner({
    super.key,
    required this.child,
    this.visible,
  });

  final Widget child;

  /// Test hook. Production uses [PreviewMode.enabled].
  final bool? visible;

  bool get _show => visible ?? PreviewMode.enabled;

  @override
  Widget build(BuildContext context) {
    if (!_show) return child;

    final colors = Theme.of(context).extension<MasaratColors>() ??
        MasaratColors.light;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12, top: 6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Text(
                        PreviewMode.badgeLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
