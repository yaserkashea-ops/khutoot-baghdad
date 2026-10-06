import 'package:flutter/material.dart';

import '../../../core/models/listing.dart';
import '../../feed/unified_compose_sheet.dart';

/// Admin publish uses the same unified compose as the public feed,
/// then writes the listing as published.
Future<Listing?> openAdminPublishFlow(BuildContext context) {
  return showUnifiedComposeSheet(context, asAdminDirect: true);
}
