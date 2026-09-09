import '../core/models/listing.dart';

/// Local store until Supabase is wired. Same instance must be shared by list + form.
class ListingsRepository {
  ListingsRepository();

  static final ListingsRepository shared = ListingsRepository();

  final List<Listing> _items = [
    Listing(
      id: '1',
      type: ListingType.driver,
      area: 'المنصور',
      destination: 'الجادرية',
      originSubs: const ['شارع الرواد', 'حي دراغ'],
      destinationSubs: const ['جامعة بغداد', 'مول الجادرية'],
      timePeriod: TimePeriod.morning,
      departureTime: '7:30',
      returnTime: '2:00',
      vehicleType: 'سيارة صالون',
      seatsCount: 3,
      genderRequirement: GenderRequirement.mixed,
      contactPhone: '9647701234567',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Listing(
      id: '2',
      type: ListingType.rider,
      area: 'المنصور',
      destination: 'جامعة بغداد — الجادرية',
      originSubs: const ['حي الجامعة'],
      destinationSubs: const ['مجمع الجادرية', 'بوابة الجادرية'],
      timePeriod: TimePeriod.morning,
      departureTime: '7:00',
      genderRequirement: GenderRequirement.femaleOnly,
      contactTelegram: 'https://t.me/example_rider',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Listing(
      id: '3',
      type: ListingType.driver,
      area: 'الأعظمية',
      destination: 'باب المعظم',
      originSubs: const ['شارع الرشيد', 'الفضل'],
      destinationSubs: const ['باب المعظم — الوزارات', 'مدينة الطب'],
      timePeriod: TimePeriod.evening,
      returnTime: '5:30',
      vehicleType: 'فان',
      seatsCount: 6,
      genderRequirement: GenderRequirement.maleOnly,
      contactPhone: '9647809876543',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Listing(
      id: '4',
      type: ListingType.rider,
      area: 'الدورة',
      destination: 'الجامعة التكنولوجية',
      timePeriod: TimePeriod.morning,
      genderRequirement: GenderRequirement.mixed,
      contactPhone: '9647511112233',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    Listing(
      id: '5',
      type: ListingType.driver,
      area: 'البياع',
      destination: 'الجامعة المستنصرية',
      originSubs: const ['السيدية'],
      destinationSubs: const ['شارع فلسطين', 'الوزيرية'],
      timePeriod: TimePeriod.evening,
      vehicleType: 'سيارة صالون',
      seatsCount: 2,
      genderRequirement: GenderRequirement.femaleOnly,
      contactTelegram: '@baghdad_line',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  int _seq = 100;

  Future<List<Listing>> fetchAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final copy = List<Listing>.from(_items)
      ..sort((a, b) {
        final aAt = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bAt = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });
    return List<Listing>.unmodifiable(copy);
  }

  Future<Listing?> findByPhone(String phone) async {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return null;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    try {
      return _items.firstWhere((l) => (l.contactPhone ?? '').trim() == trimmed);
    } catch (_) {
      return null;
    }
  }

  Future<Listing> insert(Listing listing) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final now = DateTime.now();
    final created = listing.copyWith(
      id: listing.id.isEmpty ? '${_seq++}' : listing.id,
      createdAt: now,
      updatedAt: now,
    );
    _items.insert(0, created);
    return created;
  }

  /// Bulk-publish imported drafts (newest first).
  Future<List<Listing>> insertMany(Iterable<Listing> listings) async {
    final created = <Listing>[];
    for (final listing in listings) {
      created.add(await insert(listing));
    }
    return created;
  }

  Future<Listing> update(Listing listing) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final index = _items.indexWhere((l) => l.id == listing.id);
    if (index < 0) {
      throw StateError('Listing ${listing.id} not found');
    }
    final updated = listing.copyWith(updatedAt: DateTime.now());
    _items[index] = updated;
    return updated;
  }

  Future<Listing?> findById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    try {
      return _items.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    final index = _items.indexWhere((l) => l.id == id);
    if (index < 0) return false;
    _items.removeAt(index);
    return true;
  }

  int get driverCount =>
      _items.where((l) => l.type == ListingType.driver).length;

  int get riderCount =>
      _items.where((l) => l.type == ListingType.rider).length;

  int get totalCount => _items.length;
}
