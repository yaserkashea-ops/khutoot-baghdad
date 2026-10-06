import '../models/listing.dart';

abstract final class DuplicateListing {
  static Listing? similar({
    required List<Listing> mine,
    required ListingType type,
    required String area,
    required String destination,
    required TimePeriod? time,
    String? phone,
    String? excludeId,
  }) {
    final a = area.trim();
    final d = destination.trim();
    if (a.isEmpty || d.isEmpty) return null;
    for (final l in mine) {
      if (excludeId != null && l.id == excludeId) continue;
      if (l.type != type) continue;
      if (l.area.trim() != a || l.destination.trim() != d) continue;
      if (time != null && l.timePeriod != time) continue;
      final p = (phone ?? '').trim();
      if (p.isNotEmpty &&
          (l.contactPhone ?? '').trim().isNotEmpty &&
          l.contactPhone!.trim() != p) {
        continue;
      }
      return l;
    }
    return null;
  }
}
