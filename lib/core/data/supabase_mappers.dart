import '../config/admin_contact.dart';
import '../models/admin_report.dart';
import '../models/listing.dart';

abstract final class ListingMapper {
  static Listing fromRow(Map<String, dynamic> row) {
    return Listing(
      id: row['id'] as String,
      type: _typeFrom(row['listing_type'] as String?),
      area: (row['area'] as String?) ?? '',
      destination: (row['destination'] as String?) ?? '',
      originSubs: _stringList(row['origin_subs']),
      destinationSubs: _stringList(row['destination_subs']),
      timePeriod: _periodFrom(row['time_period'] as String?),
      departureTime: row['departure_time'] as String?,
      returnTime: row['return_time'] as String?,
      vehicleType: row['vehicle_type'] as String?,
      seatsCount: row['seats_count'] as int?,
      genderRequirement: _genderFrom(row['gender_requirement'] as String?),
      contactPhone: row['contact_phone'] as String?,
      contactTelegram: row['contact_telegram'] as String?,
      createdAt: _date(row['created_at']),
      updatedAt: _date(row['updated_at']),
    );
  }

  static Map<String, dynamic> toInsert(Listing listing) {
    return {
      'listing_type': _typeTo(listing.type),
      'area': listing.area,
      'destination': listing.destination,
      'origin_subs': listing.originSubs,
      'destination_subs': listing.destinationSubs,
      'time_period': _periodTo(listing.timePeriod),
      'departure_time': listing.departureTime,
      'return_time': listing.returnTime,
      'vehicle_type': listing.vehicleType,
      'seats_count': listing.seatsCount,
      'gender_requirement': _genderTo(listing.genderRequirement),
      'contact_phone': listing.contactPhone,
      'contact_telegram': listing.contactTelegram,
    };
  }

  static Map<String, dynamic> toUpdate(Listing listing) {
    return {
      ...toInsert(listing),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static List<String> _stringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'[،,]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static ListingType _typeFrom(String? value) => switch (value) {
        'rider' => ListingType.rider,
        _ => ListingType.driver,
      };

  static String _typeTo(ListingType type) => switch (type) {
        ListingType.driver => 'driver',
        ListingType.rider => 'rider',
      };

  static TimePeriod _periodFrom(String? value) => switch (value) {
        'evening' => TimePeriod.evening,
        _ => TimePeriod.morning,
      };

  static String _periodTo(TimePeriod period) => switch (period) {
        TimePeriod.morning => 'morning',
        TimePeriod.evening => 'evening',
      };

  static GenderRequirement _genderFrom(String? value) => switch (value) {
        'male_only' => GenderRequirement.maleOnly,
        'female_only' => GenderRequirement.femaleOnly,
        _ => GenderRequirement.mixed,
      };

  static String _genderTo(GenderRequirement gender) => switch (gender) {
        GenderRequirement.maleOnly => 'male_only',
        GenderRequirement.femaleOnly => 'female_only',
        GenderRequirement.mixed => 'mixed',
      };
}

abstract final class AdminReportMapper {
  static AdminReport fromRow(Map<String, dynamic> row) {
    return AdminReport(
      id: row['id'] as String,
      kind: _kindFrom(row['kind'] as String?),
      message: (row['message'] as String?) ?? '',
      status: _statusFrom(row['status'] as String?),
      listingId: row['listing_id'] as String?,
      contactHint: row['contact_hint'] as String?,
      adminNote: row['admin_note'] as String?,
      createdAt: DateTime.tryParse('${row['created_at']}') ?? DateTime.now(),
      updatedAt: DateTime.tryParse('${row['updated_at']}'),
    );
  }

  static Map<String, dynamic> toInsert({
    required AdminContactKind kind,
    required String message,
    String? listingId,
    String? contactHint,
  }) {
    return {
      'kind': _kindTo(kind),
      'message': message,
      'status': 'open',
      'listing_id': listingId,
      'contact_hint': contactHint,
    };
  }

  static AdminContactKind _kindFrom(String? value) => switch (value) {
        'complaint' => AdminContactKind.complaint,
        'problem' => AdminContactKind.problem,
        _ => AdminContactKind.report,
      };

  static String _kindTo(AdminContactKind kind) => switch (kind) {
        AdminContactKind.report => 'report',
        AdminContactKind.complaint => 'complaint',
        AdminContactKind.problem => 'problem',
      };

  static ReportStatus _statusFrom(String? value) => switch (value) {
        'in_progress' => ReportStatus.inProgress,
        'resolved' => ReportStatus.resolved,
        'dismissed' => ReportStatus.dismissed,
        _ => ReportStatus.open,
      };

  static String statusTo(ReportStatus status) => switch (status) {
        ReportStatus.open => 'open',
        ReportStatus.inProgress => 'in_progress',
        ReportStatus.resolved => 'resolved',
        ReportStatus.dismissed => 'dismissed',
      };
}
