import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/unlock_payment.dart';
import '../../../core/models/contact_unlock.dart';
import '../../../core/models/listing.dart';
import '../../../core/notifications/publisher_push_registrar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/contact_unlocks_repository.dart';
import '../../../data/listings_repository.dart';
import '../widgets/admin_double_confirm.dart';
import '../../listings/widgets/listing_card.dart';
import '../../listings/widgets/revealed_rider_sheet.dart';

class AdminUnlocksPage extends StatefulWidget {
  const AdminUnlocksPage({super.key});

  @override
  State<AdminUnlocksPage> createState() => _AdminUnlocksPageState();
}

class _AdminUnlocksPageState extends State<AdminUnlocksPage> {
  List<ContactUnlock> _items = const [];
  bool _loading = true;
  bool _tableMissing = false;
  String? _busyId;
  ContactUnlockStatus? _filter = ContactUnlockStatus.pending;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _tableMissing = false;
    });
    try {
      final rows = await ContactUnlocksRepository.shared.adminQueue();
      if (!mounted) return;
      setState(() {
        _items = rows;
        _loading = false;
      });
    } on ContactUnlocksTableMissing {
      if (!mounted) return;
      setState(() {
        _tableMissing = true;
        _items = const [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<ContactUnlock> get _visible {
    final f = _filter;
    if (f == null) return _items;
    return _items.where((u) => u.status == f).toList();
  }

  String _code(ContactUnlock u) {
    return u.request?.displayCode ??
        Listing.shortRequestCode(null, u.riderRequestId);
  }

  Future<void> _setStatus(ContactUnlock u, ContactUnlockStatus status) async {
    setState(() => _busyId = u.id);
    try {
      await ContactUnlocksRepository.shared.setStatus(id: u.id, status: status);
      if (status == ContactUnlockStatus.approved) {
        unawaited(ListingPublishPush.notifyUnlockApproved(u.id));
        try {
          await ListingsRepository.shared.setBooked(
            u.riderRequestId,
            booked: true,
          );
        } catch (_) {}
      }
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحديث الحالة. شغّل SQL تحديث جدول contact_unlocks.',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _copySql() async {
    await Clipboard.setData(
      const ClipboardData(text: _setupSql),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'نُسخ أمر SQL — الصقه في محرر Supabase ثم Run',
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
      ),
    );
  }

  Future<void> _releaseBooking(ContactUnlock u) async {
    final ok = await AdminDoubleConfirm.show(
      context,
      title: 'إزالة الحجز؟',
      detail: 'يُزال وسم محجوز فوراً ويُعاد نشر الطلب في الدليل ليصبح متاحاً للحجز.',
      confirmLabel: 'تأكيد الإزالة',
    );
    if (!ok || !mounted) return;
    setState(() {
      _busyId = u.id;
      _items = [
        for (final item in _items)
          item.riderRequestId == u.riderRequestId
              ? item.copyWith(
                  status: ContactUnlockStatus.rejected,
                  request: item.request?.copyWith(isBooked: false),
                )
              : item,
      ];
    });
    try {
      await ContactUnlocksRepository.shared.releaseActiveForRequest(
        u.riderRequestId,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أُزيل الحجز وأُعيد نشر الطلب في الدليل',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر إزالة الحجز. أعد المحاولة.',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _openRiderContact(ContactUnlock u) async {
    final listing = u.request;
    if (listing == null) return;
    await showRevealedRiderSheet(context, listing);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_tableMissing) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text(
            'جدول طلبات التواصل غير مفعّل بعد',
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'شغّل أمر SQL مرة واحدة في Supabase حتى تظهر هنا طلبات السائقين لكشف رقم الراكب.',
            style: GoogleFonts.ibmPlexSansArabic(
              height: 1.45,
              color: c.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _copySql,
            icon: const Icon(Icons.copy),
            label: const Text('نسخ أمر التفعيل'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _load,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      );
    }

    final rows = _visible;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            'عندما يدفع السائق اضغط «إظهار الرقم» فيُحجز الطلب ويظهر وسم محجوز. إن تأكدت أنه لا يزال متاحاً أزل الحجز وأعد نشره.',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 13,
              height: 1.4,
              color: c.text.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('بانتظار'),
                selected: _filter == ContactUnlockStatus.pending,
                onSelected: (_) =>
                    setState(() => _filter = ContactUnlockStatus.pending),
              ),
              FilterChip(
                label: const Text('ظهر الرقم'),
                selected: _filter == ContactUnlockStatus.approved,
                onSelected: (_) =>
                    setState(() => _filter = ContactUnlockStatus.approved),
              ),
              FilterChip(
                label: const Text('مرفوض'),
                selected: _filter == ContactUnlockStatus.rejected,
                onSelected: (_) =>
                    setState(() => _filter = ContactUnlockStatus.rejected),
              ),
              FilterChip(
                label: const Text('الكل'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Text(
                'لا طلبات تواصل في هذا التبويب',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                  color: c.text.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            for (final u in rows) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        u.isPending
                            ? 'بانتظار الدفع'
                            : u.isApproved
                                ? 'الرقم ظاهر للسائق'
                                : 'مرفوض',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.w700,
                          color: c.riderAccent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'الكود: ${_code(u)}',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'الانطلاق: ${u.request?.area ?? '—'}',
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                      ),
                      Text(
                        'الوجهة: ${u.request?.destination ?? '—'}',
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                      ),
                      Text(
                        'المبلغ: ${UnlockPayment.amountLabel}',
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                      ),
                      Text(
                        'السائق: ${u.driverContact}',
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                      ),
                      if (u.isApproved && u.request != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'رقم الراكب: ${u.request!.contactPhone ?? '—'}',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        if ((u.request!.contactTelegram ?? '').isNotEmpty)
                          Text(
                            'تلغرام: ${u.request!.contactTelegram}',
                            style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                          ),
                      ],
                      if (u.request != null) ...[
                        const SizedBox(height: 10),
                        ListingCard(
                          listing: u.request!,
                          contactLabel: 'تواصل مع الراكب',
                          onContact: u.isApproved
                              ? () => showListingContactChooser(
                                    context,
                                    u.request!,
                                  )
                              : null,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (u.isPending) ...[
                            FilledButton(
                              onPressed: _busyId == u.id
                                  ? null
                                  : () => _setStatus(
                                        u,
                                        ContactUnlockStatus.approved,
                                      ),
                              child: const Text('إظهار الرقم'),
                            ),
                            TextButton(
                              onPressed: _busyId == u.id
                                  ? null
                                  : () => _setStatus(
                                        u,
                                        ContactUnlockStatus.rejected,
                                      ),
                              child: const Text('رفض'),
                            ),
                          ],
                          if (u.isApproved)
                            FilledButton.icon(
                              onPressed: () => _openRiderContact(u),
                              icon: const Icon(Icons.badge_outlined, size: 18),
                              label: const Text('عرض بطاقة الدليل'),
                            ),
                          if (!u.isRejected)
                            OutlinedButton(
                              onPressed: _busyId == u.id
                                  ? null
                                  : () => _releaseBooking(u),
                              child: const Text(
                                'إزالة الحجز وإعادة النشر',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

const _setupSql = '''
alter table public.listings add column if not exists route_details text;
alter table public.listings add column if not exists is_booked boolean;
update public.listings set is_booked = false where is_booked is null;
alter table public.listings alter column is_booked set default false;

create table if not exists public.contact_unlocks (
  id uuid primary key default gen_random_uuid(),
  rider_request_id uuid not null references public.listings(id) on delete cascade,
  driver_account_id uuid,
  driver_contact text not null,
  status text not null default 'pending'
    check (status in ('pending','approved','rejected')),
  requested_at timestamptz not null default now(),
  approved_at timestamptz
);

create unique index if not exists contact_unlocks_request_driver_uidx
  on public.contact_unlocks (rider_request_id, driver_contact);

create unique index if not exists contact_unlocks_one_active_booking
  on public.contact_unlocks (rider_request_id)
  where status in ('pending', 'approved');

alter table public.contact_unlocks enable row level security;

drop policy if exists contact_unlocks_public_select on public.contact_unlocks;
drop policy if exists contact_unlocks_public_insert on public.contact_unlocks;
drop policy if exists contact_unlocks_public_update on public.contact_unlocks;
drop policy if exists contact_unlocks_admin_all on public.contact_unlocks;

create policy contact_unlocks_public_select on public.contact_unlocks
  for select to anon, authenticated using (true);
create policy contact_unlocks_public_insert on public.contact_unlocks
  for insert to anon, authenticated with check (status = 'pending');
create policy contact_unlocks_public_update on public.contact_unlocks
  for update to anon, authenticated using (true) with check (true);
create policy contact_unlocks_admin_all on public.contact_unlocks
  for all to authenticated using (true) with check (true);

grant select, insert, update on public.contact_unlocks to anon;
grant select, insert, update, delete on public.contact_unlocks to authenticated;
''';
