import 'listing.dart';

enum ContactUnlockStatus { pending, approved, rejected }

class ContactUnlock {
  const ContactUnlock({
    required this.id,
    required this.riderRequestId,
    required this.driverContact,
    this.driverAccountId,
    this.status = ContactUnlockStatus.pending,
    this.requestedAt,
    this.approvedAt,
    this.request,
  });

  final String id;
  final String riderRequestId;
  final String driverContact;
  final String? driverAccountId;
  final ContactUnlockStatus status;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final Listing? request;

  bool get isPending => status == ContactUnlockStatus.pending;
  bool get isApproved => status == ContactUnlockStatus.approved;
  bool get isRejected => status == ContactUnlockStatus.rejected;

  ContactUnlock copyWith({
    Listing? request,
    ContactUnlockStatus? status,
  }) {
    return ContactUnlock(
      id: id,
      riderRequestId: riderRequestId,
      driverContact: driverContact,
      driverAccountId: driverAccountId,
      status: status ?? this.status,
      requestedAt: requestedAt,
      approvedAt: approvedAt,
      request: request ?? this.request,
    );
  }

  static ContactUnlockStatus statusFrom(String? raw) => switch (raw) {
        'approved' => ContactUnlockStatus.approved,
        'rejected' => ContactUnlockStatus.rejected,
        _ => ContactUnlockStatus.pending,
      };

  static String statusTo(ContactUnlockStatus status) => switch (status) {
        ContactUnlockStatus.pending => 'pending',
        ContactUnlockStatus.approved => 'approved',
        ContactUnlockStatus.rejected => 'rejected',
      };

  static ContactUnlock fromRow(Map<String, dynamic> row, {Listing? request}) {
    return ContactUnlock(
      id: row['id'] as String,
      riderRequestId: row['rider_request_id'] as String,
      driverContact: (row['driver_contact'] as String?) ?? '',
      driverAccountId: row['driver_account_id'] as String?,
      status: statusFrom(row['status'] as String?),
      requestedAt: DateTime.tryParse('${row['requested_at'] ?? ''}'),
      approvedAt: DateTime.tryParse('${row['approved_at'] ?? ''}'),
      request: request,
    );
  }
}
