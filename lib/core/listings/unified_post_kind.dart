import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../theme/app_colors.dart';

/// Official public labels — use these strings exactly, nowhere else.
abstract final class UnifiedPostKind {
  static const available = 'متوفر خط';
  static const wanted = 'مطلوب خط';

  static IconData iconFor(ListingType type) => type == ListingType.rider
      ? Icons.person_search_rounded
      : Icons.directions_car_rounded;

  static Color colorFor(ListingType type, MasaratColors c) =>
      type == ListingType.rider ? c.wanted : c.primary;

  static String labelFor(ListingType type) =>
      type == ListingType.rider ? wanted : available;

  static ListingType? typeForLabel(String label) {
    if (label == available) return ListingType.driver;
    if (label == wanted) return ListingType.rider;
    return null;
  }
}
