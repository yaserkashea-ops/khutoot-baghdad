import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/admin_contact.dart';
import '../core/data/supabase_mappers.dart';
import '../core/models/admin_report.dart';
import 'listings_repository.dart';

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
  int _seq = 200;

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
          contactHint: '9647701112233',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        AdminReport(
          id: 'r2',
          kind: AdminContactKind.complaint,
          message: 'السائق لم يلتزم بالنقاط الفرعية المذكورة.',
          status: ReportStatus.inProgress,
          listingId: '3',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          adminNote: 'تم التواصل مع صاحب الإعلان',
        ),
        AdminReport(
          id: 'r3',
          kind: AdminContactKind.problem,
          message: 'لا أستطيع تعديل منشوري بعد إدخال رقم الهاتف.',
          status: ReportStatus.resolved,
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
  }) async {
    if (_client != null) {
      // Do not .select() after insert: anon may INSERT but cannot SELECT
      // admin_reports under RLS, and RETURNING would fail the whole submit.
      await _client.from('admin_reports').insert(
            AdminReportMapper.toInsert(
              kind: kind,
              message: message,
              listingId: listingId,
              contactHint: contactHint,
            ),
          );
      return AdminReport(
        id: 'pending',
        kind: kind,
        message: message,
        status: ReportStatus.open,
        listingId: listingId,
        contactHint: contactHint,
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
      return AdminStats(
        listingsTotal: await listings.countAll(),
        drivers: await listings.countDrivers(),
        riders: await listings.countRiders(),
        reportsOpen: open,
        reportsTotal: reports.length,
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final open =
        _reports.where((r) => r.status == ReportStatus.open).length;
    return AdminStats(
      listingsTotal: listings.totalCount,
      drivers: listings.driverCount,
      riders: listings.riderCount,
      reportsOpen: open,
      reportsTotal: _reports.length,
    );
  }
}
