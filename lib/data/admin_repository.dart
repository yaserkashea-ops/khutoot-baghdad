import '../core/config/admin_contact.dart';
import '../core/models/admin_report.dart';
import 'listings_repository.dart';

/// Reports store + admin helpers. Shares [ListingsRepository] for listing ops.
class AdminRepository {
  AdminRepository({ListingsRepository? listings})
      : listings = listings ?? ListingsRepository.shared;

  static final AdminRepository shared = AdminRepository();

  final ListingsRepository listings;

  final List<AdminReport> _reports = [
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

  int _seq = 200;

  Future<List<AdminReport>> fetchReports({ReportStatus? status}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
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
    await Future<void>.delayed(const Duration(milliseconds: 60));
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
    await Future<void>.delayed(const Duration(milliseconds: 60));
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
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final index = _reports.indexWhere((r) => r.id == id);
    if (index < 0) return false;
    _reports.removeAt(index);
    return true;
  }

  Future<AdminStats> fetchStats() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final open = _reports
        .where(
          (r) =>
              r.status == ReportStatus.open ||
              r.status == ReportStatus.inProgress,
        )
        .length;
    return AdminStats(
      listingsTotal: listings.totalCount,
      drivers: listings.driverCount,
      riders: listings.riderCount,
      reportsOpen: open,
      reportsTotal: _reports.length,
    );
  }
}
