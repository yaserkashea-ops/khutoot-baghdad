import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/admin_contact.dart';
import '../core/data/supabase_mappers.dart';
import '../core/models/admin_report.dart';
import '../core/models/outreach_lead.dart';
import '../core/utils/contact_keys.dart';
import '../core/utils/outreach_contact_extractor.dart';
import '../core/utils/phone_digits.dart';
import 'listings_repository.dart';

class OutreachImportResult {
  const OutreachImportResult({
    required this.added,
    required this.merged,
    required this.skippedDuplicate,
    required this.extracted,
  });

  final int added;
  final int merged;
  final int skippedDuplicate;
  final int extracted;
}

/// Reports store + admin helpers.
class AdminRepository {
  AdminRepository({
    ListingsRepository? listings,
    SupabaseClient? client,
  })  : listings = listings ?? ListingsRepository.shared,
        _client = client;

  static AdminRepository shared = AdminRepository();

  final ListingsRepository listings;
  final SupabaseClient? _client;

  late final List<AdminReport> _reports =
      _client == null ? _seedLocal() : <AdminReport>[];
  final List<OutreachLead> _localLeads = [];
  int _seq = 200;
  int _leadSeq = 1;

  static void bindShared({
    required ListingsRepository listings,
    required SupabaseClient client,
  }) {
    shared = AdminRepository(listings: listings, client: client);
  }

  static List<AdminReport> _seedLocal() => [
        AdminReport(
          id: 'r1',
          kind: AdminContactKind.report,
          message: 'إعلان يحتوي على تواصل غير لائق في خط المنصور.',
          status: ReportStatus.open,
          listingId: '1',
          contactPhone: '9647701112233',
          contactTelegram: '@rider_baghdad',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        AdminReport(
          id: 'r2',
          kind: AdminContactKind.complaint,
          message: 'السائق لم يلتزم بالنقاط الفرعية المذكورة.',
          status: ReportStatus.inProgress,
          listingId: '3',
          contactPhone: '07701234567',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          adminNote: 'تم التواصل مع صاحب الإعلان',
        ),
        AdminReport(
          id: 'r3',
          kind: AdminContactKind.problem,
          message: 'لا أستطيع تعديل منشوري بعد إدخال رقم الهاتف.',
          status: ReportStatus.resolved,
          contactTelegram: 'https://t.me/example_user',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          adminNote: 'تم توجيه المستخدم لإعادة المحاولة',
        ),
      ];

  Future<List<AdminReport>> fetchReports({ReportStatus? status}) async {
    if (_client != null) {
      final List<Map<String, dynamic>> rows;
      if (status != null) {
        final raw = await _client
            .from('admin_reports')
            .select()
            .eq('status', AdminReportMapper.statusTo(status))
            .order('created_at', ascending: false);
        rows = (raw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        final raw = await _client
            .from('admin_reports')
            .select()
            .order('created_at', ascending: false);
        rows = (raw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return List<AdminReport>.unmodifiable(
        rows.map(AdminReportMapper.fromRow).toList(),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final copy = List<AdminReport>.from(_reports)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (status == null) return List.unmodifiable(copy);
    return List.unmodifiable(copy.where((r) => r.status == status));
  }

  Future<AdminReport> submitReport({
    required AdminContactKind kind,
    required String message,
    String? listingId,
    String? contactHint,
    String? contactPhone,
    String? contactTelegram,
  }) async {
    if (_client != null) {
      // Do not .select() after insert: anon may INSERT but cannot SELECT
      // admin_reports under RLS, and RETURNING would fail the whole submit.
      final payload = AdminReportMapper.toInsert(
        kind: kind,
        message: message,
        listingId: listingId,
        contactHint: contactHint,
        contactPhone: contactPhone,
        contactTelegram: contactTelegram,
      );
      try {
        await _client.from('admin_reports').insert(payload);
      } catch (e) {
        // Older DBs may lack contact_phone / contact_telegram columns.
        final msg = '$e';
        final missingCols = msg.contains('contact_phone') ||
            msg.contains('contact_telegram') ||
            msg.contains('PGRST204');
        if (!missingCols) rethrow;
        final fallback = Map<String, dynamic>.from(payload)
          ..remove('contact_phone')
          ..remove('contact_telegram');
        await _client.from('admin_reports').insert(fallback);
      }
      return AdminReport(
        id: 'pending',
        kind: kind,
        message: message,
        status: ReportStatus.open,
        listingId: listingId,
        contactHint: contactHint,
        contactPhone: contactPhone,
        contactTelegram: contactTelegram,
        createdAt: DateTime.now(),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final report = AdminReport(
      id: 'r${_seq++}',
      kind: kind,
      message: message,
      status: ReportStatus.open,
      listingId: listingId,
      contactHint: contactHint,
      contactPhone: contactPhone,
      contactTelegram: contactTelegram,
      createdAt: DateTime.now(),
    );
    _reports.insert(0, report);
    return report;
  }

  Future<AdminReport> updateReport(
    String id, {
    ReportStatus? status,
    String? adminNote,
  }) async {
    if (_client != null) {
      final patch = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (status != null) {
        patch['status'] = AdminReportMapper.statusTo(status);
      }
      if (adminNote != null) {
        patch['admin_note'] = adminNote;
      }
      final row = await _client
          .from('admin_reports')
          .update(patch)
          .eq('id', id)
          .select()
          .single();
      return AdminReportMapper.fromRow(Map<String, dynamic>.from(row));
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final index = _reports.indexWhere((r) => r.id == id);
    if (index < 0) throw StateError('Report $id not found');
    final updated = _reports[index].copyWith(
      status: status,
      adminNote: adminNote,
      updatedAt: DateTime.now(),
    );
    _reports[index] = updated;
    return updated;
  }

  Future<bool> deleteReport(String id) async {
    if (_client != null) {
      await _client.from('admin_reports').delete().eq('id', id);
      return true;
    }
    final index = _reports.indexWhere((r) => r.id == id);
    if (index < 0) return false;
    _reports.removeAt(index);
    return true;
  }

  Future<AdminStats> fetchStats() async {
    if (_client != null) {
      final reports = await fetchReports();
      final open = reports.where((r) => r.status == ReportStatus.open).length;
      var fresh = 0;
      var total = 0;
      try {
        final leads = await fetchOutreachLeads();
        total = leads.length;
        fresh =
            leads.where((l) => l.status == OutreachLeadStatus.fresh).length;
      } catch (_) {
        // Table may not exist until migrate_outreach_leads.sql is applied.
      }
      return AdminStats(
        listingsTotal: await listings.countAll(),
        drivers: await listings.countDrivers(),
        riders: await listings.countRiders(),
        reportsOpen: open,
        reportsTotal: reports.length,
        outreachFresh: fresh,
        outreachTotal: total,
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final open =
        _reports.where((r) => r.status == ReportStatus.open).length;
    final fresh =
        _localLeads.where((l) => l.status == OutreachLeadStatus.fresh).length;
    return AdminStats(
      listingsTotal: listings.totalCount,
      drivers: listings.driverCount,
      riders: listings.riderCount,
      reportsOpen: open,
      reportsTotal: _reports.length,
      outreachFresh: fresh,
      outreachTotal: _localLeads.length,
    );
  }

  // —— Outreach invites ——

  Future<List<OutreachLead>> fetchOutreachLeads({
    OutreachLeadStatus? status,
  }) async {
    if (_client != null) {
      try {
        final List raw;
        if (status != null) {
          raw = await _client
              .from('outreach_leads')
              .select()
              .eq('status', status.db)
              .order('created_at', ascending: false);
        } else {
          raw = await _client
              .from('outreach_leads')
              .select()
              .order('created_at', ascending: false);
        }
        return List.unmodifiable(
          raw
              .map((e) => OutreachLead.fromRow(Map<String, dynamic>.from(e as Map)))
              .toList(),
        );
      } catch (e) {
        final msg = '$e';
        if (msg.contains('outreach_leads') || msg.contains('PGRST205')) {
          throw StateError(
            'جدول الدعوات غير موجود — نفّذ migrate_outreach_leads.sql في Supabase',
          );
        }
        rethrow;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final copy = List<OutreachLead>.from(_localLeads)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (status == null) return List.unmodifiable(copy);
    return List.unmodifiable(copy.where((l) => l.status == status));
  }

  Future<OutreachImportResult> importOutreachText(String raw) async {
    final extracted = OutreachContactExtractor.extract(raw);
    var added = 0;
    var merged = 0;
    var skipped = 0;

    for (final item in extracted) {
      final result = await _upsertOutreachContact(item);
      switch (result) {
        case _UpsertKind.added:
          added++;
        case _UpsertKind.merged:
          merged++;
        case _UpsertKind.duplicate:
          skipped++;
      }
    }

    return OutreachImportResult(
      added: added,
      merged: merged,
      skippedDuplicate: skipped,
      extracted: extracted.length,
    );
  }

  Future<_UpsertKind> _upsertOutreachContact(
    ExtractedOutreachContact item,
  ) async {
    // Prefer extractor-canonical values; fall back to ContactKeys.
    var phone = (item.phone ?? '').trim();
    if (phone.isEmpty) {
      phone = ContactKeys.phoneKey(item.phone) ?? '';
    } else {
      phone = ContactKeys.phoneKey(phone) ?? phone;
    }
    if (phone.isNotEmpty && !RegExp(r'^9647\d{9}$').hasMatch(phone)) {
      final n = PhoneDigits.normalize(phone);
      phone = RegExp(r'^9647\d{9}$').hasMatch(n) ? n : '';
    }

    var telegram = (item.telegram ?? '').trim();
    if (telegram.isNotEmpty) {
      if (!telegram.startsWith('@')) telegram = '@$telegram';
      // Keep even if ContactKeys is stricter; only drop pure digits.
      if (RegExp(r'^@\d+$').hasMatch(telegram) ||
          !RegExp(r'^@[A-Za-z][A-Za-z0-9_]{2,31}$').hasMatch(telegram)) {
        telegram = '';
      }
    }
    final tgKey =
        telegram.isEmpty ? null : telegram.substring(1).toLowerCase();
    final phoneKey = phone.isEmpty ? null : phone;

    if (phoneKey == null && tgKey == null) return _UpsertKind.duplicate;

    final existing = await fetchOutreachLeads();
    OutreachLead? byPhone;
    OutreachLead? byTg;
    if (phoneKey != null) {
      for (final l in existing) {
        if (ContactKeys.phoneKey(l.phone) == phoneKey || l.phone == phoneKey) {
          byPhone = l;
          break;
        }
      }
    }
    if (tgKey != null) {
      for (final l in existing) {
        final k = ContactKeys.telegramKey(l.telegram) ??
            (l.telegramDisplay.startsWith('@')
                ? l.telegramDisplay.substring(1).toLowerCase()
                : l.telegramDisplay.toLowerCase());
        if (k == tgKey) {
          byTg = l;
          break;
        }
      }
    }

    if (byPhone != null && byTg != null && byPhone.id != byTg.id) {
      if (!byPhone.hasTelegram && telegram.isNotEmpty) {
        await updateOutreachLead(
          byPhone.id,
          telegram: telegram,
          sourceSnippet: byPhone.sourceSnippet ?? item.snippet,
        );
        return _UpsertKind.merged;
      }
      return _UpsertKind.duplicate;
    }

    final hit = byPhone ?? byTg;
    if (hit != null) {
      var changed = false;
      String? nextPhone = hit.phone;
      String? nextTg = hit.telegram;
      if (!hit.hasPhone && phoneKey != null) {
        nextPhone = phoneKey;
        changed = true;
      }
      if (!hit.hasTelegram && telegram.isNotEmpty) {
        nextTg = telegram;
        changed = true;
      }
      if (!changed) return _UpsertKind.duplicate;
      await updateOutreachLead(
        hit.id,
        phone: nextPhone,
        telegram: nextTg,
        sourceSnippet: hit.sourceSnippet ?? item.snippet,
      );
      return _UpsertKind.merged;
    }

    final lead = OutreachLead(
      id: '',
      phone: phoneKey,
      telegram: telegram.isEmpty ? null : telegram,
      sourceSnippet: item.snippet,
      status: OutreachLeadStatus.fresh,
      createdAt: DateTime.now(),
    );
    await _insertOutreachLead(lead);
    return _UpsertKind.added;
  }

  Future<OutreachLead> _insertOutreachLead(OutreachLead lead) async {
    if (_client != null) {
      final row = await _client
          .from('outreach_leads')
          .insert(lead.toInsert())
          .select()
          .single();
      return OutreachLead.fromRow(Map<String, dynamic>.from(row));
    }
    final created = OutreachLead(
      id: 'ol${_leadSeq++}',
      phone: lead.phone,
      telegram: lead.telegram,
      sourceSnippet: lead.sourceSnippet,
      status: lead.status,
      createdAt: DateTime.now(),
    );
    _localLeads.insert(0, created);
    return created;
  }

  Future<OutreachLead> updateOutreachLead(
    String id, {
    String? phone,
    String? telegram,
    String? sourceSnippet,
    OutreachLeadStatus? status,
    DateTime? lastContactedAt,
    bool touchContacted = false,
  }) async {
    final contacted = touchContacted
        ? (lastContactedAt ?? DateTime.now())
        : lastContactedAt;

    if (_client != null) {
      final patch = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (phone != null) patch['phone'] = phone.trim().isEmpty ? null : phone;
      if (telegram != null) {
        patch['telegram'] = telegram.trim().isEmpty ? null : telegram;
      }
      if (sourceSnippet != null) {
        patch['source_snippet'] =
            sourceSnippet.trim().isEmpty ? null : sourceSnippet.trim();
      }
      if (status != null) patch['status'] = status.db;
      if (touchContacted || lastContactedAt != null) {
        patch['last_contacted_at'] = contacted?.toUtc().toIso8601String();
      }
      final row = await _client
          .from('outreach_leads')
          .update(patch)
          .eq('id', id)
          .select()
          .single();
      return OutreachLead.fromRow(Map<String, dynamic>.from(row));
    }

    final i = _localLeads.indexWhere((l) => l.id == id);
    if (i < 0) throw StateError('Lead $id not found');
    final updated = _localLeads[i].copyWith(
      phone: phone ?? _localLeads[i].phone,
      telegram: telegram ?? _localLeads[i].telegram,
      sourceSnippet: sourceSnippet ?? _localLeads[i].sourceSnippet,
      status: status,
      lastContactedAt: contacted,
      updatedAt: DateTime.now(),
    );
    _localLeads[i] = updated;
    return updated;
  }

  Future<int> markOutreachInvited(Iterable<String> ids) async {
    var n = 0;
    final now = DateTime.now();
    for (final id in ids) {
      await updateOutreachLead(
        id,
        status: OutreachLeadStatus.invited,
        lastContactedAt: now,
        touchContacted: true,
      );
      n++;
    }
    return n;
  }

  Future<bool> deleteOutreachLead(String id) async {
    if (_client != null) {
      await _client.from('outreach_leads').delete().eq('id', id);
      return true;
    }
    final i = _localLeads.indexWhere((l) => l.id == id);
    if (i < 0) return false;
    _localLeads.removeAt(i);
    return true;
  }

  Future<int> deleteOutreachLeads(Iterable<String> ids) async {
    var n = 0;
    for (final id in ids) {
      if (await deleteOutreachLead(id)) n++;
    }
    return n;
  }
}

enum _UpsertKind { added, merged, duplicate }
