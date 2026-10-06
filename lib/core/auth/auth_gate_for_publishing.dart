import 'package:flutter/material.dart';

import '../../features/listings/publisher_auth_sheet.dart';
import 'publisher_auth_controller.dart';

/// Login is requested only for publish / manage — never for browsing.
abstract final class AuthGateForPublishing {
  static Future<bool> ensure(
    BuildContext context, {
    required bool asRider,
  }) async {
    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (auth.isLoggedIn) return true;
    if (!context.mounted) return false;
    final ok = await showPublisherAuthSheet(
      context,
      requiredToContinue: false,
      title: asRider
          ? 'أنشئ حساباً لنشر طلبك'
          : 'أنشئ حساباً لحفظ هذا الخط والرجوع إليه لاحقاً',
    );
    if (!context.mounted) return false;
    return ok && PublisherAuthController.shared.isLoggedIn;
  }
}
