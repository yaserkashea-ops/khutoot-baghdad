import '../config/admin_contact.dart';

enum ReportStatus { open, inProgress, resolved, dismissed }

class AdminReport {
  const AdminReport({
    required this.id,
    required this.kind,
    required this.message,
    required this.status,
    required this.createdAt,
    this.listingId,
    this.contactHint,
    this.adminNote,
    this.updatedAt,
  });

  final String id;
  final AdminContactKind kind;
  final String message;
  final ReportStatus status;
  final DateTime createdAt;
  final String? listingId;
  final String? contactHint;
  final String? adminNote;
  final DateTime? updatedAt;

  String get kindLabel => kind.label;

  String get statusLabel => switch (status) {
        ReportStatus.open => 'جديد',
        ReportStatus.inProgress => 'قيد المعالجة',
        ReportStatus.resolved => 'محلول',
        ReportStatus.dismissed => 'مرفوض',
      };

  AdminReport copyWith({
    ReportStatus? status,
    String? adminNote,
    DateTime? updatedAt,
  }) {
    return AdminReport(
      id: id,
      kind: kind,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
      listingId: listingId,
      contactHint: contactHint,
      adminNote: adminNote ?? this.adminNote,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AdminStats {
  const AdminStats({
    required this.listingsTotal,
    required this.drivers,
    required this.riders,
    required this.reportsOpen,
    required this.reportsTotal,
  });

  final int listingsTotal;
  final int drivers;
  final int riders;
  final int reportsOpen;
  final int reportsTotal;
}
