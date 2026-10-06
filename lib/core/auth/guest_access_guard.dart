import 'package:flutter/material.dart';

import 'auth_gate_for_publishing.dart';
import 'publisher_auth_controller.dart';

/// Blocks only account-bound actions. Browsing stays open without a session.
abstract final class GuestAccessGuard {
  static bool get canBrowse => true;

  static bool get hasAccount => PublisherAuthController.shared.isLoggedIn;

  static Future<bool> requireAccount(
    BuildContext context, {
    required bool asRider,
  }) {
    return AuthGateForPublishing.ensure(context, asRider: asRider);
  }
}
