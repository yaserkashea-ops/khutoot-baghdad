import '../config/directory_launch.dart';

enum ListingType { driver, rider }

enum GenderRequirement { maleOnly, femaleOnly, mixed }

enum TimePeriod { morning, evening }

/// Workflow status for directory publishing.
enum ListingStatus {
  pendingReview,
  awaitingPayment,
  published,
  rejected,
}

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
    this.ownerAccountId,
    this.viewCount = 0,
    this.status = ListingStatus.published,
    this.governorate = 'بغداد',
    this.adminNote,
    this.referenceCode,
    this.createdAt,
    this.updatedAt,
    this.bumpedAt,
    this.expiresAt,
    this.isHidden = false,
    this.isBooked = false,
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
  final String? ownerAccountId;
  final int viewCount;
  final ListingStatus status;
  final String governorate;
  final String? adminNote;
  final String? referenceCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? bumpedAt;
  final DateTime? expiresAt;
  final bool isHidden;

  /// Rider request reserved after a paid contact unlock is approved.
  final bool isBooked;

  bool get isDriver => type == ListingType.driver;

  bool get isPublished => status == ListingStatus.published;

  DateTime get subscriptionStart =>
      bumpedAt ?? createdAt ?? updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  DateTime get effectiveExpiresAt {
    if (expiresAt != null) return expiresAt!;
    return subscriptionStart.add(const Duration(days: 30));
  }

  bool get isExpired =>
      isPublished && DateTime.now().isAfter(effectiveExpiresAt);

  /// Visible on the public directory until hidden or deleted by admin.
  bool get isLiveInDirectory => isPublished && !isHidden;

  /// Public card status. Expired posts stay listed until admin deletes them.
  String get directoryRibbon {
    if (!isDriver && isBooked && !DirectoryLaunch.freeRiderContacts) {
      return 'محجوز';
    }
    if (isHidden) return 'مخفي';
    if (status == ListingStatus.pendingReview) return 'قيد المراجعة';
    if (status == ListingStatus.awaitingPayment) {
      return DirectoryLaunch.hidePaymentCopy ? 'قيد التجهيز' : 'بانتظار الدفع';
    }
    if (seatsCount == 0) return 'المقاعد مكتمل';
    if (isPublished) return '';
    if (status == ListingStatus.rejected) return 'مرفوض';
    return '';
  }

  bool get showsLivePulse =>
      isLiveInDirectory &&
      seatsCount != 0 &&
      !(!isDriver && isBooked && !DirectoryLaunch.freeRiderContacts);

  String get lastUpdateLabel {
    final at = (bumpedAt ?? updatedAt ?? createdAt)?.toLocal();
    if (at == null) return 'آخر تحديث: غير محدد';
    final diff = DateTime.now().difference(at);
    if (diff.isNegative || diff.inSeconds < 45) return 'آخر تحديث: الآن';
    if (diff.inMinutes < 60) {
      return 'آخر تحديث: قبل ${diff.inMinutes.clamp(1, 59)} د';
    }
    if (diff.inHours < 24) {
      return 'آخر تحديث: قبل ${diff.inHours.clamp(1, 23)} س';
    }
    return 'آخر تحديث: قبل ${diff.inDays.clamp(1, 999)} ي';
  }

  /// Whole calendar days left (0 if expired).
  int get wholeDaysLeft {
    final days = effectiveExpiresAt.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  DateTime get sortAt =>
      bumpedAt ?? createdAt ?? updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  bool get hasRouteSubs =>
      originSubs.isNotEmpty || destinationSubs.isNotEmpty;

  String get originSubsLabel => originSubs.join('، ');

  String get destinationSubsLabel => destinationSubs.join('، ');

  /// Same style as publish requests: `KH-` + 6 characters.
  String get displayCode => shortRequestCode(referenceCode, id);

  static String shortRequestCode(String? referenceCode, String id) {
    final ref = (referenceCode ?? '').trim().toUpperCase();
    if (ref.isNotEmpty) {
      final rest = (ref.startsWith('KH-') ? ref.substring(3) : ref)
          .replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (rest.length >= 6) return 'KH-${rest.substring(0, 6)}';
      if (rest.isNotEmpty) return 'KH-$rest';
    }
    final hex = id.replaceAll('-', '').toUpperCase();
    if (hex.length >= 6) return 'KH-${hex.substring(0, 6)}';
    return id;
  }

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
        GenderRequirement.femaleOnly => 'اناث فقط',
        GenderRequirement.mixed => 'الكل',
      };

  String? get publicGenderLabel =>
      genderRequirement == GenderRequirement.mixed ? null : genderLabel;

  String get typeLabel => isDriver ? 'خط' : 'راكب';

  /// Free-text rider request details (stored in [vehicleType] for riders).
  String? get routeDetails {
    if (isDriver) return null;
    final v = vehicleType?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  /// Directory cards must not expose rider phones until an unlock is approved.
  Listing withoutPublicContacts() {
    if (isDriver) return this;
    return copyWith(clearPhone: true, clearTelegram: true);
  }

  String get statusLabel {
    if (!isDriver && isBooked && !DirectoryLaunch.freeRiderContacts) {
      return 'محجوز';
    }
    if (isHidden) return 'مخفي';
    return switch (status) {
      ListingStatus.pendingReview => 'بانتظار المراجعة',
      ListingStatus.awaitingPayment => DirectoryLaunch.hidePaymentCopy
          ? 'قيد التجهيز للنشر'
          : 'بانتظار الدفع',
      ListingStatus.published => 'منشور في الدليل',
      ListingStatus.rejected => 'مرفوض',
    };
  }

  /// Owner-only notes. Visibility is not time-limited; last update is the signal.
  String? get visibilityHint {
    if (!isDriver && isBooked && !DirectoryLaunch.freeRiderContacts) {
      return 'الطلب محجوز ويظهر وسم «محجوز» في الدليل حتى يُؤكَّد أنه لا يزال متاحاً ثم يُزال الحجز ويُعاد نشره';
    }
    return null;
  }

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
    String? ownerAccountId,
    int? viewCount,
    ListingStatus? status,
    String? governorate,
    String? adminNote,
    String? referenceCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? bumpedAt,
    DateTime? expiresAt,
    bool? isHidden,
    bool? isBooked,
    bool clearDeparture = false,
    bool clearReturn = false,
    bool clearVehicle = false,
    bool clearSeats = false,
    bool clearPhone = false,
    bool clearTelegram = false,
    bool clearOwner = false,
    bool clearAdminNote = false,
    bool clearReference = false,
    bool clearExpires = false,
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
      ownerAccountId:
          clearOwner ? null : (ownerAccountId ?? this.ownerAccountId),
      viewCount: viewCount ?? this.viewCount,
      status: status ?? this.status,
      governorate: governorate ?? this.governorate,
      adminNote: clearAdminNote ? null : (adminNote ?? this.adminNote),
      referenceCode:
          clearReference ? null : (referenceCode ?? this.referenceCode),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bumpedAt: bumpedAt ?? this.bumpedAt,
      expiresAt: clearExpires ? null : (expiresAt ?? this.expiresAt),
      isHidden: isHidden ?? this.isHidden,
      isBooked: isBooked ?? this.isBooked,
    );
  }
}
