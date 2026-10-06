import 'package:flutter/material.dart';

/// Shared visual tokens for the preview UX pass.
abstract final class AppTokens {
  static const radius = 16.0;
  static const radiusInner = 14.0;
  static const minTap = 48.0;
  static const mutedOpacity = 0.72;

  static BorderRadius get borderRadius => BorderRadius.circular(radius);

  static Color muted(Color text) => text.withValues(alpha: mutedOpacity);

  static List<BoxShadow> restShadow(Color text) => [
        BoxShadow(
          color: text.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
