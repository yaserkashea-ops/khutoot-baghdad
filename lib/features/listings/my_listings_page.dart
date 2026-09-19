import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/publisher_auth_controller.dart';
import '../../core/auth/publisher_limits.dart';
import '../../core/models/listing.dart';
import '../../core/models/listing_subscription.dart';
import '../../core/notifications/match_notify_service.dart';
import '../../core/notifications/notification_prefs.dart';
import '../../core/notifications/notifications_bell_button.dart';
import '../../core/notifications/publish_notify_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/listings_repository.dart';
import '../../data/publisher_repository.dart';
import 'publish_listing_page.dart';
import 'publisher_auth_sheet.dart';
import 'widgets/listing_card.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  List<Listing> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!mounted) return;
    // الجلسة محفوظة محلياً — لا نطلب تسجيل دخول إن كان المستخدم مسجّلاً.
    if (!auth.isLoggedIn) {
      final ok = await showPublisherAuthSheet(context);
      if (!mounted) return;
      if (!ok || !PublisherAuthController.shared.isLoggedIn) {
        Navigator.of(context).maybePop();
        return;
      }
    }
    await _load();
    unawaited(_resumeNotifyServices());
  }

  Future<void> _resumeNotifyServices() async {
    final prefs = NotificationPrefs.shared;
    if (!prefs.isLoaded) await prefs.load();
    if (!prefs.enabled) return;
    MatchNotifyService.shared.start();
    PublishNotifyService.shared.start();
    await _checkPublishNotifications();
  }

  Future<void> _checkPublishNotifications() async {
    final activated = await PublishNotifyService.shared.checkNow();
    if (!mounted || activated.isEmpty) return;
    final first = activated.first;
    final msg = activated.length == 1
        ? 'تم تفعيل خطك: ${first.area} ← ${first.destination}'
        : 'تم تفعيل ${activated.length} من خطوطك';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg, style: GoogleFonts.ibmPlexSansArabic()),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await PublisherRepository.shared.myListings();
      if (!mounted) return;
      setState(() {
        _items = rows;
        _loading = false;
      });
      await _checkPublishNotifications();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل خطوطك. سجّل الدخول مجدداً.';
      });
    }
  }

  Future<void> _createListing() async {
    if (_items.length >= PublisherLimits.maxActiveListings) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('وصلت للحد الأقصى'),
          content: Text(
            PublisherLimits.limitReachedMessage,
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      return;
    }

    final saved = await Navigator.of(context).push<Listing>(
      MaterialPageRoute(
        builder: (_) => PublishListingPage(
          repository: ListingsRepository.shared,
          initialType: ListingType.driver,
          asDirectoryRequest: true,
        ),
      ),
    );
    if (!mounted) return;
    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أُرسل الطلب للمراجعة${saved.referenceCode != null ? ' · ${saved.referenceCode}' : ''}',
          ),
        ),
      );
      await _load();
    }
  }

  Future<void> _edit(Listing listing) async {
    final saved = await Navigator.of(context).push<Listing>(
      MaterialPageRoute(
        builder: (_) => PublishListingPage(
          repository: ListingsRepository.shared,
          initial: listing,
          draftOnly: true,
        ),
      ),
    );
    if (saved == null || !mounted) return;
    try {
      await PublisherRepository.shared.updateListing(saved);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ التعديل')),
      );
    }
  }

  Future<void> _delete(Listing listing) async {
    final c = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الخط؟'),
        content: Text(
          '${listing.area} ← ${listing.destination}',
          style: GoogleFonts.ibmPlexSansArabic(color: c.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final deleted = await PublisherRepository.shared.deleteListing(listing.id);
    if (!mounted) return;
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الحذف')),
      );
      return;
    }
    await _load();
  }

  Future<void> _previewInDirectory(Listing listing) async {
    final c = context.colors;
    final live = listing.isLiveInDirectory;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'معاينة في الدليل',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  live
                      ? 'هكذا يظهر خطك للباحثين في الدليل حالياً.'
                      : listing.isExpired || listing.isHidden
                          ? 'هذه معاينة لشكل البطاقة — الخط غير ظاهر للعامة حالياً.'
                          : 'هذه معاينة لشكل البطاقة بعد النشر في الدليل.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    height: 1.45,
                    color: c.text.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 14),
                ListingCard(
                  listing: listing,
                  highlighted: true,
                  badgeLabel: live ? 'خطك في الدليل' : 'معاينة',
                  onContact: () {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'هذه معاينة من حسابك — زر التواصل يظهر للباحثين في الدليل',
                          style: GoogleFonts.ibmPlexSansArabic(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'إغلاق',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = PublisherAuthController.shared;
    final username = (auth.login ?? '').trim();
    final canPublishNew = !_loading &&
        _error == null &&
        _items.isNotEmpty &&
        _items.length < PublisherLimits.maxActiveListings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: const [
          NotificationsBellButton(),
        ],
      ),
      floatingActionButton: canPublishNew
          ? FloatingActionButton.extended(
              onPressed: _createListing,
              icon: const Icon(Icons.add),
              label: Text(
                'أضف خطك',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _bootstrap,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    children: [
                      if (username.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.border),
                            color: c.surface,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    c.primary.withValues(alpha: 0.12),
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  color: c.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'اسم المستخدم',
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 12,
                                        color: c.text.withValues(alpha: 0.55),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      username,
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: c.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const NotificationsEnableTile(),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: c.primary.withValues(alpha: 0.08),
                          border: Border.all(
                            color: c.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 20,
                              color: c.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ListingSubscription.driverVisibilityNote,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: c.text.withValues(alpha: 0.82),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_items.isEmpty) ...[
                        const SizedBox(height: 14),
                        Icon(
                          Icons.campaign_outlined,
                          size: 48,
                          color: c.text.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لا منشورات في حسابك بعد',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أضف خطك ليظهر في الدليل لمدة ${ListingSubscription.periodDays} يوماً، '
                          'ثم جدّد النشر بعدها من هنا',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 13.5,
                            height: 1.45,
                            color: c.text.withValues(alpha: 0.62),
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _createListing,
                          icon: const Icon(Icons.add),
                          label: const Text('أضف خطك'),
                        ),
                      ] else ...[
                        Text(
                          'خطوطك',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (var i = 0; i < _items.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _MyListingTile(
                            listing: _items[i],
                            onEdit: () => _edit(_items[i]),
                            onDelete: () => _delete(_items[i]),
                            onPreview: _items[i].isPublished
                                ? () => _previewInDirectory(_items[i])
                                : null,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _MyListingTile extends StatelessWidget {
  const _MyListingTile({
    required this.listing,
    required this.onEdit,
    required this.onDelete,
    this.onPreview,
  });

  final Listing listing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPreview;

  DateTime? get _publishedAt =>
      listing.bumpedAt ?? listing.createdAt ?? listing.updatedAt;

  String? get _dateLabel {
    final at = _publishedAt?.toLocal();
    if (at == null) return null;
    return _relativeArabic(at);
  }

  String _relativeArabic(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.isNegative || diff.inSeconds < 45) return 'منذ لحظات';
    if (diff.inMinutes < 60) {
      final n = diff.inMinutes.clamp(1, 59);
      return 'منذ ${_countLabel(n, 'دقيقة', 'دقيقتين', 'دقائق')}';
    }
    if (diff.inHours < 24) {
      final n = diff.inHours.clamp(1, 23);
      return 'منذ ${_countLabel(n, 'ساعة', 'ساعتين', 'ساعات')}';
    }
    if (diff.inDays < 7) {
      final n = diff.inDays.clamp(1, 6);
      return 'منذ ${_countLabel(n, 'يوم', 'يومين', 'أيام')}';
    }
    if (diff.inDays < 30) {
      final n = (diff.inDays / 7).floor().clamp(1, 4);
      return 'منذ ${_countLabel(n, 'أسبوع', 'أسبوعين', 'أسابيع')}';
    }
    if (diff.inDays < 365) {
      final n = (diff.inDays / 30).floor().clamp(1, 11);
      return 'منذ ${_countLabel(n, 'شهر', 'شهرين', 'أشهر')}';
    }
    final n = (diff.inDays / 365).floor().clamp(1, 99);
    return 'منذ ${_countLabel(n, 'سنة', 'سنتين', 'سنوات')}';
  }

  String _countLabel(int n, String one, String two, String many) {
    if (n == 1) return one;
    if (n == 2) return two;
    if (n >= 3 && n <= 10) return '$n $many';
    return '$n $one';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = c.accent;
    final dateLabel = _dateLabel;

    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    listing.statusLabel,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: accent,
                    ),
                  ),
                ),
                Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: c.text.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 4),
                Text(
                  '${listing.viewCount}',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: c.text.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            if (listing.referenceCode != null &&
                listing.referenceCode!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'رقم الطلب: ${listing.referenceCode}',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12,
                  color: c.text.withValues(alpha: 0.55),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${listing.area} ← ${listing.destination}',
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: c.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              listing.scheduleLabel,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12.5,
                color: c.text.withValues(alpha: 0.6),
              ),
            ),
            if (dateLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12,
                  color: c.text.withValues(alpha: 0.55),
                ),
              ),
            ],
            if (listing.visibilityHint != null) ...[
              const SizedBox(height: 12),
              _VisibilityAlert(message: listing.visibilityHint!, listing: listing),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 0,
                    runSpacing: 0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('تعديل'),
                      ),
                      if (onPreview != null)
                        TextButton.icon(
                          onPressed: onPreview,
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('معاينة في الدليل'),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityAlert extends StatelessWidget {
  const _VisibilityAlert({
    required this.message,
    required this.listing,
  });

  final String message;
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final urgent = listing.isExpired ||
        (listing.isPublished && listing.wholeDaysLeft <= 7);
    final tone = urgent ? Theme.of(context).colorScheme.error : c.primary;
    final icon = listing.isExpired
        ? Icons.event_busy_outlined
        : urgent
            ? Icons.notification_important_outlined
            : Icons.schedule_outlined;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: tone.withValues(alpha: 0.08),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12.5,
                height: 1.45,
                color: c.text.withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
