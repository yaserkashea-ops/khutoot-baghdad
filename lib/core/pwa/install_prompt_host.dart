import 'package:flutter/material.dart';

/// Pass-through host kept for future global PWA hooks (no bottom banner).
class InstallPromptHost extends StatelessWidget {
  const InstallPromptHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
