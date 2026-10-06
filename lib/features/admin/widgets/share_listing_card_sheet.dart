import 'package:flutter/material.dart';

import '../../../core/models/listing.dart';
import 'share_listing_card_page.dart';

/// Opens the full-screen card share experience (رجوع / حفظ / مشاركة).
Future<void> showShareListingCardSheet(
  BuildContext context,
  Listing listing,
) {
  return openShareListingCardPage(context, listing);
}
