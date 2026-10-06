import 'package:flutter/material.dart';

/// Full-height home column. Width is capped only on very wide screens.
abstract final class HomeLayout {
  static const maxWidth = 720.0;

  static Widget fill(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > maxWidth
            ? maxWidth
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}
