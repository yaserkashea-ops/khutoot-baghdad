import 'package:flutter/material.dart';

import '../feed/unified_feed_page.dart';

/// Public app shell: a single unified listings feed.
class DirectoryShell extends StatelessWidget {
  const DirectoryShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnifiedFeedPage();
  }
}
