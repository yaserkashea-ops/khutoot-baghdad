enum OutreachLeadStatus { fresh, invited, skipped, optOut }

extension OutreachLeadStatusX on OutreachLeadStatus {
  String get db => switch (this) {
        OutreachLeadStatus.fresh => 'new',
        OutreachLeadStatus.invited => 'invited',
        OutreachLeadStatus.skipped => 'skipped',
        OutreachLeadStatus.optOut => 'opt_out',
      };

  String get label => switch (this) {
        OutreachLeadStatus.fresh => 'جديد',
        OutreachLeadStatus.invited => 'دُعي',
        OutreachLeadStatus.skipped => 'تخطي',
        OutreachLeadStatus.optOut => 'رفض',
      };

  static OutreachLeadStatus fromDb(String raw) => switch (raw) {
        'invited' => OutreachLeadStatus.invited,
        'skipped' => OutreachLeadStatus.skipped,
        'opt_out' => OutreachLeadStatus.optOut,
        _ => OutreachLeadStatus.fresh,
      };
}

class OutreachLead {
  const OutreachLead({
    required this.id,
    required this.status,
    required this.createdAt,
    this.phone,
    this.telegram,
    this.sourceSnippet,
    this.lastContactedAt,
    this.updatedAt,
  });

  final String id;
  final String? phone;
  final String? telegram;
  final String? sourceSnippet;
  final OutreachLeadStatus status;
  final DateTime createdAt;
  final DateTime? lastContactedAt;
  final DateTime? updatedAt;

  String get phoneDisplay => (phone ?? '').trim();
  String get telegramDisplay => (telegram ?? '').trim();

  bool get hasPhone => phoneDisplay.isNotEmpty;
  bool get hasTelegram => telegramDisplay.isNotEmpty;

  OutreachLead copyWith({
    String? phone,
    String? telegram,
    String? sourceSnippet,
    OutreachLeadStatus? status,
    DateTime? lastContactedAt,
    DateTime? updatedAt,
    bool clearLastContacted = false,
  }) {
    return OutreachLead(
      id: id,
      phone: phone ?? this.phone,
      telegram: telegram ?? this.telegram,
      sourceSnippet: sourceSnippet ?? this.sourceSnippet,
      status: status ?? this.status,
      createdAt: createdAt,
      lastContactedAt: clearLastContacted
          ? null
          : (lastContactedAt ?? this.lastContactedAt),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static OutreachLead fromRow(Map<String, dynamic> row) {
    return OutreachLead(
      id: '${row['id']}',
      phone: (row['phone'] as String?)?.trim(),
      telegram: (row['telegram'] as String?)?.trim(),
      sourceSnippet: (row['source_snippet'] as String?)?.trim(),
      status: OutreachLeadStatusX.fromDb('${row['status'] ?? 'new'}'),
      createdAt: DateTime.tryParse('${row['created_at']}') ?? DateTime.now(),
      lastContactedAt: row['last_contacted_at'] == null
          ? null
          : DateTime.tryParse('${row['last_contacted_at']}'),
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.tryParse('${row['updated_at']}'),
    );
  }

  Map<String, dynamic> toInsert() => {
        if (phoneDisplay.isNotEmpty) 'phone': phoneDisplay,
        if (telegramDisplay.isNotEmpty) 'telegram': telegramDisplay,
        if ((sourceSnippet ?? '').trim().isNotEmpty)
          'source_snippet': sourceSnippet!.trim(),
        'status': status.db,
      };
}
