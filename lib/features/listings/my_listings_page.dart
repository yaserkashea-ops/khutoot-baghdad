import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/publisher_auth_controller.dart';
import '../../core/config/directory_launch.dart';
import '../../core/auth/publisher_limits.dart';
import '../../core/matches/listing_route_match.dart';
import '../../core/models/contact_unlock.dart';
import '../../core/models/listing.dart';
import '../../data/contact_unlocks_repository.dart';
import '../../data/listings_repository.dart';
import '../../data/publisher_repository.dart';
import 'listing_matches_page.dart';
import 'publish_listing_page.dart';
import 'publish_rider_page.dart';
import '../../core/notifications/match_notify_service.dart';
import '../../core/notifications/notification_prefs.dart';
import '../../core/notifications/notifications_bell_button.dart';
import '../../core/notifications/publish_notify_service.dart';
import '../../core/notifications/publisher_push_registrar.dart';
import '../../core/pwa/share_app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_toggle_button.dart';
import 'publisher_auth_sheet.dart';
import 'publish_role_sheet.dart';
import '../../core/notifications/unlock_notify_service.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../admin/widgets/share_listing_card_page.dart';
import 'widgets/add_party_ctas.dart';
import 'widgets/revealed_rider_sheet.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({
    super.key,
    this.embedded = false,
    this.onBrowse,
  });

  final bool embedded;
  final VoidCallback? onBrowse;

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  List<Listing> _items = const [];
  List<ContactUnlock> _unlocks = const [];
  bool _loading = true;
  String? _error;
  bool _matchesTab = false;
  Map<String, int> _matchCounts = {};
  bool _matchesLoading = false;
  bool _guest = false;

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
      if (!mounted) return;
      setState(() {
        _loading = false;
        _guest = true;
        _error = null;
      });
      return;
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
    UnlockNotifyService.shared.start();
    unawaited(PublisherPushRegistrar.register());
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
      List<ContactUnlock> unlocks = const [];
      if (!DirectoryLaunch.freeRiderContacts) {
        try {
          unlocks = await ContactUnlocksRepository.shared.mine();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _items = rows;
        _unlocks = unlocks;
        _loading = false;
      });
      unawaited(_refreshMatchCounts());
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
    if (!await confirmPublishLane(context, asRider: false)) return;
    if (!mounted) return;
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

  Future<void> _createRiderRequest() async {
    if (!await confirmPublishLane(context, asRider: true)) return;
    if (!mounted) return;
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
      MaterialPageRoute(builder: (_) => const PublishRiderPage()),
    );
    if (!mounted) return;
    if (saved != null) await _load();
  }

  Future<void> _edit(Listing listing) async {
    if (!listing.isDriver) {
      final saved = await Navigator.of(context).push<Listing>(
        MaterialPageRoute(builder: (_) => PublishRiderPage(initial: listing)),
      );
      if (!mounted || saved == null) return;
      await _load();
      return;
    }
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

  Future<void> _refreshListing(Listing listing) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'تحديث المنشور؟',
      body:
          '${listing.area} ← ${listing.destination}\nسيظهر تاريخ آخر تحديث الآن في الدليل.',
      confirmLabel: 'تحديث',
    );
    if (!ok || !mounted) return;
    try {
      await PublisherRepository.shared.republishListing(listing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث المنشور')),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث المنشور')),
      );
    }
  }

  Future<void> _saveCardImage(Listing listing) {
    return openShareListingCardPage(context, listing);
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

  Future<void> _refreshMatchCounts() async {
    final published = _items.where((l) => l.isPublished).toList();
    if (published.isEmpty) {
      if (mounted) {
        setState(() {
          _matchCounts = {};
          _matchesLoading = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _matchesLoading = true);
    final counts = <String, int>{};
    for (final listing in published) {
      try {
        final rows =
            await ListingsRepository.shared.fetchRouteMatches(listing);
        counts[listing.id] = rows.length;
      } catch (_) {
        counts[listing.id] = 0;
      }
    }
    if (!mounted) return;
    setState(() {
      _matchCounts = counts;
      _matchesLoading = false;
    });
  }

  Future<void> _openMatches(Listing listing) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ListingMatchesPage(mine: listing),
      ),
    );
    if (mounted) unawaited(_refreshMatchCounts());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = PublisherAuthController.shared;
    final username = (auth.login ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          const ShareAppIconButton(),
          const ThemeToggleButton(),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : _guest
              ? _GuestAccountPanel(
                  onCreate: () async {
                    final ok = await showPublisherAuthSheet(
                      context,
                      title: 'أنشئ حساباً لإدارة منشورك والرجوع إليه لاحقاً',
                    );
                    if (!mounted) return;
                    if (ok && PublisherAuthController.shared.isLoggedIn) {
                      setState(() => _guest = false);
                      await _load();
                    }
                  },
                  onBrowse: widget.onBrowse ??
                      () => Navigator.of(context).maybePop(),
                )
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
                      const SizedBox(height: 14),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _AccountTab(
                                label: 'منشوراتي',
                                selected: !_matchesTab,
                                onTap: () =>
                                    setState(() => _matchesTab = false),
                              ),
                            ),
                            Expanded(
                              child: _AccountTab(
                                label: 'المطابقات',
                                selected: _matchesTab,
                                onTap: () =>
                                    setState(() => _matchesTab = true),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_matchesTab) ...[
                        if (_matchesLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_items.where((l) => l.isPublished).isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Column(
                              children: [
                                Text(
                                  'لا يوجد طرف مطابق. إن كنت سائقاً أضف خطك، وإن كنت راكباً أضف طلبك.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    height: 1.45,
                                    color: c.text.withValues(alpha: 0.62),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                AddPartyCtas(
                                  onAddLine: _createListing,
                                  onAddRequest: _createRiderRequest,
                                ),
                              ],
                            ),
                          )
                        else ...[
                          for (final listing
                              in _items.where((l) => l.isPublished)) ...[
                            _MatchRouteTile(
                              listing: listing,
                              count: _matchCounts[listing.id] ?? 0,
                              onOpen: () => _openMatches(listing),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ] else ...[
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
                          'أضف خط سائق ليظهر للركاب، أو طلب راكب ليظهر للسائقين. '
                          'يمكنك تعديل منشورك في أي وقت — يعتمد الدليل على آخر تحديث.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 13.5,
                            height: 1.45,
                            color: c.text.withValues(alpha: 0.62),
                          ),
                        ),
                        const SizedBox(height: 18),
                        AddPartyCtas(
                          onAddLine: _createListing,
                          onAddRequest: _createRiderRequest,
                        ),
                      ] else ...[
                        Text(
                          'خطوطي',
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
                            onRefresh: () => _refreshListing(_items[i]),
                            onSaveCard: () => _saveCardImage(_items[i]),
                            onDelete: () => _delete(_items[i]),
                          ),
                        ],
                      ],
                      if (!DirectoryLaunch.freeRiderContacts &&
                          _unlocks.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'الطلبات التي فتحتها',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final u in _unlocks) ...[
                          InkWell(
                            onTap: u.isApproved && u.request != null
                                ? () => showRevealedRiderSheet(context, u.request!)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: c.riderAccent.withValues(alpha: 0.45),
                              ),
                              color: c.riderAccent.withValues(alpha: 0.08),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.request == null
                                      ? 'طلب راكب'
                                      : '${u.request!.area} ← ${u.request!.destination}',
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  u.isApproved
                                      ? 'اضغط لفتح بطاقة الراكب وواتساب أو تلغرام'
                                      : u.isPending
                                          ? 'بانتظار تأكيد الدفع'
                                          : 'مرفوض',
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: c.text.withValues(alpha: 0.78),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                        ],
                      ],
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _AccountTab extends StatelessWidget {
  const _AccountTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.primary.withValues(alpha: 0.14) : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              color: selected ? c.primary : c.text.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchRouteTile extends StatelessWidget {
  const _MatchRouteTile({
    required this.listing,
    required this.count,
    required this.onOpen,
  });

  final Listing listing;
  final int count;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final kind = listing.isDriver ? 'خطك' : 'طلبك';
    final other = listing.isDriver ? 'طلبات ركاب' : 'خطوط سائقين';
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$kind · $other',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        color: c.text.withValues(alpha: 0.58),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${listing.area} ← ${listing.destination}',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ListingRouteMatch.matchesCountLabel(count),
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: count > 0 ? c.primary : c.text.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: c.text.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyListingTile extends StatelessWidget {
  const _MyListingTile({
    required this.listing,
    required this.onEdit,
    required this.onRefresh,
    required this.onSaveCard,
    required this.onDelete,
  });

  final Listing listing;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;
  final VoidCallback onSaveCard;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = c.accent;

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
            const SizedBox(height: 4),
            Text(
              listing.lastUpdateLabel,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12,
                color: c.text.withValues(alpha: 0.55),
              ),
            ),
            if (listing.visibilityHint != null) ...[
              const SizedBox(height: 12),
              _VisibilityAlert(message: listing.visibilityHint!),
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
                      TextButton.icon(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.update_rounded, size: 18),
                        label: const Text('تحديث المنشور'),
                      ),
                      TextButton.icon(
                        onPressed: onSaveCard,
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: const Text('حفظ صورة البطاقة'),
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
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = c.primary;
    final icon = Icons.info_outline;

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

class _GuestAccountPanel extends StatelessWidget {
  const _GuestAccountPanel({
    required this.onCreate,
    required this.onBrowse,
  });

  final VoidCallback onCreate;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          Icon(Icons.person_outline_rounded, size: 40, color: c.primary),
          const SizedBox(height: 14),
          Text(
            'أنشئ حساباً لإدارة منشورك والرجوع إليه لاحقاً',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'التسجيل مطلوب فقط لإنشاء منشور أو تعديله. يمكنك متابعة التصفح بدون حساب.',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
              height: 1.45,
              color: c.text.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onCreate,
              child: const Text('إنشاء حساب'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onCreate,
              child: const Text('تسجيل دخول'),
            ),
          ),
          TextButton(
            onPressed: onBrowse,
            child: const Text('العودة للتصفح'),
          ),
        ],
      ),
    );
  }
}
