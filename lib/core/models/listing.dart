enum ListingType { driver, rider }

enum GenderRequirement { maleOnly, femaleOnly, mixed }

enum TimePeriod { morning, evening }

class Listing {
  const Listing({
    required this.id,
    required this.type,
    required this.area,
    required this.destination,
    required this.timePeriod,
    required this.genderRequirement,
    this.originSubs = const [],
    this.destinationSubs = const [],
    this.departureTime,
    this.returnTime,
    this.vehicleType,
    this.seatsCount,
    this.contactPhone,
    this.contactTelegram,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final ListingType type;
  final String area;
  final String destination;
  final TimePeriod timePeriod;
  final GenderRequirement genderRequirement;

  /// نقاط انطلاق فرعية داخل [area] (حي/شارع/معلم…).
  final List<String> originSubs;

  /// نقاط وصول فرعية داخل [destination].
  final List<String> destinationSubs;

  /// ساعة انطلاق اختيارية (نص حر، مثال: 7:30).
  final String? departureTime;

  /// ساعة عودة اختيارية (نص حر، مثال: 2:00).
  final String? returnTime;

  final String? vehicleType;
  final int? seatsCount;
  final String? contactPhone;
  final String? contactTelegram;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDriver => type == ListingType.driver;

  bool get hasRouteSubs =>
      originSubs.isNotEmpty || destinationSubs.isNotEmpty;

  String get originSubsLabel => originSubs.join('، ');

  String get destinationSubsLabel => destinationSubs.join('، ');

  String get timePeriodLabel => switch (timePeriod) {
        TimePeriod.morning => 'صباحي',
        TimePeriod.evening => 'مسائي',
      };

  /// Compact schedule line for cards.
  String get scheduleLabel {
    final parts = <String>[timePeriodLabel];
    final dep = departureTime?.trim();
    final ret = returnTime?.trim();
    if (dep != null && dep.isNotEmpty) parts.add('انطلاق $dep');
    if (ret != null && ret.isNotEmpty) parts.add('عودة $ret');
    return parts.join(' · ');
  }

  String get genderLabel => switch (genderRequirement) {
        GenderRequirement.maleOnly => 'ذكور فقط',
        GenderRequirement.femaleOnly => 'بنات فقط',
        GenderRequirement.mixed => 'مختلط',
      };

  String get typeLabel => isDriver ? 'سائق' : 'راكب';

  Listing copyWith({
    String? id,
    ListingType? type,
    String? area,
    String? destination,
    TimePeriod? timePeriod,
    GenderRequirement? genderRequirement,
    List<String>? originSubs,
    List<String>? destinationSubs,
    String? departureTime,
    String? returnTime,
    String? vehicleType,
    int? seatsCount,
    String? contactPhone,
    String? contactTelegram,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDeparture = false,
    bool clearReturn = false,
    bool clearVehicle = false,
    bool clearSeats = false,
    bool clearPhone = false,
    bool clearTelegram = false,
  }) {
    return Listing(
      id: id ?? this.id,
      type: type ?? this.type,
      area: area ?? this.area,
      destination: destination ?? this.destination,
      timePeriod: timePeriod ?? this.timePeriod,
      genderRequirement: genderRequirement ?? this.genderRequirement,
      originSubs: originSubs ?? this.originSubs,
      destinationSubs: destinationSubs ?? this.destinationSubs,
      departureTime:
          clearDeparture ? null : (departureTime ?? this.departureTime),
      returnTime: clearReturn ? null : (returnTime ?? this.returnTime),
      vehicleType: clearVehicle ? null : (vehicleType ?? this.vehicleType),
      seatsCount: clearSeats ? null : (seatsCount ?? this.seatsCount),
      contactPhone: clearPhone ? null : (contactPhone ?? this.contactPhone),
      contactTelegram:
          clearTelegram ? null : (contactTelegram ?? this.contactTelegram),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
