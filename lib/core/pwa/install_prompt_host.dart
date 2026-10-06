import 'package:flutter/material.dart';

/// Install help lives on the home card. Do not auto-open a sheet on launch.
class InstallPromptHost extends StatelessWidget {
  const InstallPromptHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
