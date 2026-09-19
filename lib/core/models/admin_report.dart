import '../config/admin_contact.dart';
import '../utils/listing_contact.dart';

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
    this.contactPhone,
    this.contactTelegram,
    this.adminNote,
    this.updatedAt,
  });

  final String id;
  final AdminContactKind kind;
  final String message;
  final ReportStatus status;
  final DateTime createdAt;
  final String? listingId;
  /// Legacy single free-text field (older reports).
  final String? contactHint;
  final String? contactPhone;
  final String? contactTelegram;
  final String? adminNote;
  final DateTime? updatedAt;

  String get kindLabel => kind.label;

  String get statusLabel => switch (status) {
        ReportStatus.open => 'جديد',
        ReportStatus.inProgress => 'قيد المعالجة',
        ReportStatus.resolved => 'محلول',
        ReportStatus.dismissed => 'مرفوض',
      };

  String get phoneDisplay => (contactPhone ?? '').trim();
  String get telegramDisplay => (contactTelegram ?? '').trim();

  bool get hasStructuredContact =>
      phoneDisplay.isNotEmpty || telegramDisplay.isNotEmpty;

  List<ContactOption> contactChannels({String? whatsappMessage}) {
    final structured = ListingContact.optionsForChannels(
      phone: contactPhone,
      telegram: contactTelegram,
      whatsappMessage: whatsappMessage,
    );
    if (structured.isNotEmpty) return structured;

    final hint = (contactHint ?? '').trim();
    if (hint.contains(' · ')) {
      final parts = hint.split(' · ').map((e) => e.trim()).where((e) => e.isNotEmpty);
      String? phone;
      String? telegram;
      for (final p in parts) {
        if (ListingContact.whatsappUrl(p) != null) {
          phone ??= p;
        } else if (ListingContact.telegramUrl(p) != null) {
          telegram ??= p;
        }
      }
      final split = ListingContact.optionsForChannels(
        phone: phone,
        telegram: telegram,
        whatsappMessage: whatsappMessage,
      );
      if (split.isNotEmpty) return split;
    }

    return ListingContact.optionsForHint(
      contactHint,
      whatsappMessage: whatsappMessage,
    );
  }

  String get contactSummary {
    final parts = <String>[];
    if (phoneDisplay.isNotEmpty) parts.add(phoneDisplay);
    if (telegramDisplay.isNotEmpty) parts.add(telegramDisplay);
    if (parts.isNotEmpty) return parts.join(' · ');
    final legacy = (contactHint ?? '').trim();
    return legacy;
  }

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
      contactPhone: contactPhone,
      contactTelegram: contactTelegram,
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
    this.outreachFresh = 0,
    this.outreachTotal = 0,
    this.publisherAccountsTotal = 0,
    this.publisherAccountsDrivers = 0,
    this.publisherAccountsRiders = 0,
    this.phoneInstalls = 0,
    this.desktopInstalls = 0,
    this.totalInstalls = 0,
    this.placesTotal = 0,
  });

  final int listingsTotal;
  final int drivers;
  final int riders;
  final int reportsOpen;
  final int reportsTotal;
  final int outreachFresh;
  final int outreachTotal;
  final int publisherAccountsTotal;
  final int publisherAccountsDrivers;
  final int publisherAccountsRiders;
  final int phoneInstalls;
  final int desktopInstalls;
  final int totalInstalls;
  final int placesTotal;
}
