import '../config/directory_launch.dart';
import 'listing_subscription.dart';

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

  bool get isDriver => type == ListingType.driver;

  bool get isPublished => status == ListingStatus.published;

  /// Anchor for the current 30-day window.
  DateTime get subscriptionStart =>
      bumpedAt ?? createdAt ?? updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Effective end of paid visibility (falls back to start + 30 days).
  DateTime get effectiveExpiresAt {
    if (expiresAt != null) return expiresAt!;
    return subscriptionStart.add(const Duration(days: 30));
  }

  bool get isExpired =>
      isPublished && DateTime.now().isAfter(effectiveExpiresAt);

  /// Visible on the public directory.
  bool get isLiveInDirectory => isPublished && !isHidden && !isExpired;

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
        GenderRequirement.mixed => 'مختلط',
      };

  String get typeLabel => isDriver ? 'خط' : 'راكب';

  String get statusLabel {
    if (isHidden) return 'مخفي';
    if (isExpired) {
      return DirectoryLaunch.hidePaymentCopy
          ? 'انتهت صلاحية الظهور — جدّد النشر'
          : 'انتهى الاشتراك';
    }
    return switch (status) {
      ListingStatus.pendingReview => 'بانتظار المراجعة',
      ListingStatus.awaitingPayment => DirectoryLaunch.hidePaymentCopy
          ? 'قيد التجهيز للنشر'
          : 'بانتظار الدفع',
      ListingStatus.published => 'منشور في الدليل',
      ListingStatus.rejected => 'مرفوض',
    };
  }

  /// Extra line for the driver's own listings about the 30-day window.
  String? get visibilityHint {
    if (isHidden || status == ListingStatus.rejected) return null;
    if (isExpired) {
      return 'انتهت صلاحية الظهور — 0 يوم متبقّى '
          '(من أصل ${ListingSubscription.periodDays}) — جدّد النشر ليظهر مجدداً';
    }
    if (!isPublished) {
      return 'بعد الموافقة والنشر: صلاحية الظهور '
          '${ListingSubscription.periodDays} يوماً، ثم التجديد';
    }
    final days = wholeDaysLeft;
    return 'صلاحية الظهور: متبقّى $days '
        '${_dayWord(days)} من أصل ${ListingSubscription.periodDays} يوماً'
        '${days <= 7 ? ' — جدّد النشر قريباً' : ' — جدّد النشر بعد انتهائها'}';
  }

  static String _dayWord(int days) {
    if (days == 1) return 'يوم';
    if (days == 2) return 'يومين';
    if (days >= 3 && days <= 10) return 'أيام';
    return 'يوماً';
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
    );
  }
}
