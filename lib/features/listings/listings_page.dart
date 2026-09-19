import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/activity/directory_activity.dart';
import '../../core/auth/publisher_auth_controller.dart';
import '../../core/bootstrap/app_bootstrap.dart';
import '../../core/data/baghdad_places.dart';
import '../../core/data/learned_places_store.dart';
import '../../core/data/places_catalog.dart';
import '../../core/models/listing.dart';
import '../../core/notifications/match_notify_service.dart';
import '../../core/notifications/notification_prefs.dart';
import '../../core/notifications/publish_notify_service.dart';
import '../../core/pwa/app_install_tracker.dart';
import '../../core/pwa/install_app_button.dart';
import '../../core/pwa/pwa_install.dart';
import '../../core/pwa/share_app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_toggle_button.dart';
import '../../core/utils/listing_contact.dart';
import '../../data/listings_repository.dart';
import '../../data/publisher_repository.dart';
import '../support/contact_admin_sheet.dart';
import 'my_listings_page.dart';
import 'publish_listing_page.dart';
import 'publisher_auth_sheet.dart';
import 'widgets/empty_listings_state.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/listing_card.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key, this.repository});

  final ListingsRepository? repository;

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage>
    with WidgetsBindingObserver {
  ListingsRepository get _repository =>
      widget.repository ?? ListingsRepository.shared;

  List<Listing> _all = [];
  bool _loading = true;
  String? _loadError;
  int _openCount = 0;

  String _areaQuery = '';
  String _destinationQuery = '';
  String? _timeSlot; // صباحي | مسائي
  String? _gender;
  String _departureQuery = '';
  String _returnQuery = '';
  final ScrollController _scrollController = ScrollController();
  final List<String> _pendingViewIds = <String>[];
  Timer? _viewFlushTimer;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onListScroll);
    PwaInstall.setMode('app');
    unawaited(PublisherAuthController.shared.load());
    unawaited(AppInstallTracker.syncOnLaunch());
    unawaited(PlacesCatalog.shared.refresh());
    unawaited(_syncDirectoryActivity());
    unawaited(_resumePublisherNotifications());
    _load();
  }

  Future<void> _resumePublisherNotifications() async {
    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!auth.isLoggedIn) return;
    final prefs = NotificationPrefs.shared;
    if (!prefs.isLoaded) await prefs.load();
    if (!prefs.enabled) return;
    MatchNotifyService.shared.start();
    PublishNotifyService.shared.start();
  }

  void _onListScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset > 360;
    if (show == _showBackToTop) return;
    setState(() => _showBackToTop = show);
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _syncDirectoryActivity() async {
    final cached = await DirectoryActivity.loadCachedCount();
    if (mounted && cached > 0) {
      setState(() => _openCount = cached);
    }
    final n = await DirectoryActivity.syncOnLaunch();
    if (!mounted) return;
    if (n != _openCount) {
      setState(() => _openCount = n);
    }
  }

  @override
  void dispose() {
    _viewFlushTimer?.cancel();
    unawaited(_flushPendingViews());
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onListScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumePublisherNotifications());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      try {
        await AppBootstrap.ready.timeout(const Duration(seconds: 8));
      } on TimeoutException {
        // Continue with whatever repository is ready.
      }
      final results = await Future.wait([
        _repository.fetchAll(),
        LearnedPlacesStore.purgeUserPlaces(),
      ]);
      if (!mounted) return;
      setState(() {
        _all = results[0] as List<Listing>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'تعذر تحميل الخطوط. تحقق من الاتصال وحاول مجدداً.';
      });
    }
  }

  List<Listing> get _filtered {
    final areaQ = _areaQuery.trim();
    final destQ = _destinationQuery.trim();
    final depQ = _departureQuery.trim();
    final retQ = _returnQuery.trim();
    final list = _all.where((l) {
      // Directory shows driver routes only (legacy rider posts stay in DB/admin).
      if (!l.isDriver) return false;
      if (areaQ.isNotEmpty && !_matchesPlace(l, areaQ, preferArea: true)) {
        return false;
      }
      if (destQ.isNotEmpty && !_matchesPlace(l, destQ, preferArea: false)) {
        return false;
      }
      if (_timeSlot != null && l.timePeriodLabel != _timeSlot) return false;
      if (_gender != null && _genderKey(l) != _gender) return false;
      if (depQ.isNotEmpty) {
        final dep = l.departureTime?.trim() ?? '';
        if (dep.isEmpty || !BaghdadPlaces.matchesQuery(dep, depQ)) {
          return false;
        }
      }
      if (retQ.isNotEmpty) {
        final ret = l.returnTime?.trim() ?? '';
        if (ret.isEmpty || !BaghdadPlaces.matchesQuery(ret, retQ)) {
          return false;
        }
      }
      return true;
    }).toList();

    return list;
  }

  bool get _hasPlaceSearch =>
      _areaQuery.trim().isNotEmpty || _destinationQuery.trim().isNotEmpty;

  bool get _hasAnyFilter =>
      _hasPlaceSearch ||
      _timeSlot != null ||
      _gender != null ||
      _departureQuery.trim().isNotEmpty ||
      _returnQuery.trim().isNotEmpty;

  /// Places searchable in "من أين؟" — main departure + all origin subs.
  List<String> get _originSearchPlaces {
    final out = <String>{};
    for (final l in _all) {
      final area = l.area.trim();
      if (area.isNotEmpty) out.add(area);
      for (final s in l.originSubs) {
        final t = s.trim();
        if (t.isNotEmpty) out.add(t);
      }
    }
    return out.toList();
  }

  /// Places searchable in "إلى أين؟" — main destination + all destination subs.
  List<String> get _destinationSearchPlaces {
    final out = <String>{};
    for (final l in _all) {
      final dest = l.destination.trim();
      if (dest.isNotEmpty) out.add(dest);
      for (final s in l.destinationSubs) {
        final t = s.trim();
        if (t.isNotEmpty) out.add(t);
      }
    }
    return out.toList();
  }

  /// Match main place or any nested sub-point on that side of the route.
  bool _matchesPlace(Listing l, String query, {required bool preferArea}) {
    final places = preferArea
        ? <String>[l.area, ...l.originSubs]
        : <String>[l.destination, ...l.destinationSubs];
    return places.any(
      (p) => p.trim().isNotEmpty && BaghdadPlaces.matchesQuery(p, query),
    );
  }

  String _genderKey(Listing l) => switch (l.genderRequirement) {
        GenderRequirement.maleOnly => 'male_only',
        GenderRequirement.femaleOnly => 'female_only',
        GenderRequirement.mixed => 'mixed',
      };

  static const _timeSlots = <String>['صباحي', 'مسائي'];

  String? _resultsStatus(int count) {
    if (_loadError != null) return 'تعذر تحميل النتائج';
    if (count == 0) {
      return _hasAnyFilter ? 'لم نجد خطوطاً مطابقة' : null;
    }
    return '$count خطاً متاحاً';
  }

  Future<void> _openMyListings() async {
    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!mounted) return;

    if (!auth.isLoggedIn) {
      final ok = await showPublisherAuthSheet(context);
      if (!mounted) return;
      if (!ok || !PublisherAuthController.shared.isLoggedIn) return;
    }

    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const MyListingsPage()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openMainAction() async {
    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!mounted) return;

    if (auth.isLoggedIn) {
      await _openMyListings();
      return;
    }

    final c = context.colors;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'أنت سائق؟',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'لإضافة خطك إلى الدليل يلزم إنشاء حساب أو تسجيل الدخول أولاً.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: c.text.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'request'),
                  icon: const Icon(Icons.route_outlined),
                  label: const Text('إنشاء حساب وإضافة خط'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'account'),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('لدي حساب — تسجيل الدخول'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    if (choice == 'account') {
      await _openMyListings();
      return;
    }
    await _startPublishFlow();
  }

  Future<void> _startPublishFlow() async {
    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!mounted) return;
    if (!auth.isLoggedIn) {
      final ok = await showPublisherAuthSheet(
        context,
        title: 'إنشاء حساب مطلوب لإضافة خطك',
      );
      if (!mounted) return;
      if (!ok || !PublisherAuthController.shared.isLoggedIn) return;
    }

    final saved = await Navigator.of(context).push<Listing>(
      MaterialPageRoute(
        builder: (_) => PublishListingPage(
          repository: _repository,
          initialType: ListingType.driver,
          asDirectoryRequest: true,
        ),
      ),
    );
    if (!mounted || saved == null) return;
    await _load();
  }

  /// Every time a card enters the list viewport (including re-appear on scroll),
  /// count one view — repeats from the same user are intentional.
  void _onCardAppeared(Listing listing) {
    if (!listing.isLiveInDirectory) return;
    _pendingViewIds.add(listing.id);
    _viewFlushTimer?.cancel();
    _viewFlushTimer = Timer(const Duration(milliseconds: 350), () {
      unawaited(_flushPendingViews());
    });
  }

  Future<void> _flushPendingViews() async {
    if (_pendingViewIds.isEmpty) return;
    final batch = List<String>.from(_pendingViewIds);
    _pendingViewIds.clear();
    await PublisherRepository.shared.incrementViewsMany(batch);
  }

  Future<void> _onContact(Listing listing) async {
    final options = ListingContact.optionsFor(listing);
    if (!mounted) return;
    if (options.isEmpty) {
      final c = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.text,
          content: Text(
            'لا توجد وسيلة تواصل لهذا الإعلان',
            style: TextStyle(color: c.onPrimary),
          ),
        ),
      );
      return;
    }

    final c = context.colors;
    final chosen = await showModalBottomSheet<ContactOption>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'اختر وسيلة التواصل',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                for (final option in options) ...[
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: c.border),
                    ),
                    title: Row(
                      children: [
                        Text(option.label),
                        if (option.detail != null &&
                            option.detail!.trim().isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: SelectableText(
                              option.detail!,
                              maxLines: 1,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: c.text.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.pop(ctx, option),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (chosen == null) return;
    await ListingContact.openUrl(chosen.url);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 4,
        actionsIconTheme: const IconThemeData(size: 22),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'دليل خطوط بغداد',
            maxLines: 1,
            softWrap: false,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        leadingWidth: _openCount > 0 ? 156 : 56,
        leading: _openCount > 0
            ? Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6),
                  child: _DirectoryUsersChip(count: _openCount),
                ),
              )
            : null,
        actionsPadding: EdgeInsets.zero,
        actions: [
          IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShareAppIconButton(),
                InstallAppIconButton(),
                ThemeToggleButton(),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'التواصل مع الإدارة',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              tooltip: 'التواصل مع الإدارة',
              onPressed: () => showContactAdminSheet(context),
              icon: const Icon(Icons.support_agent_rounded),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IgnorePointer(
            ignoring: !_showBackToTop,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              offset: _showBackToTop ? Offset.zero : const Offset(0, 0.35),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showBackToTop ? 1 : 0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BackToTopButton(onPressed: _scrollToTop),
                ),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: PublisherAuthController.shared,
            builder: (context, _) {
              final loggedIn = PublisherAuthController.shared.isLoggedIn;
              final label = loggedIn ? 'حسابي' : 'أضف خطك';
              return FloatingActionButton.extended(
                onPressed: loggedIn ? _openMyListings : _openMainAction,
                tooltip: label,
                icon: Icon(
                  loggedIn
                      ? Icons.person_outline_rounded
                      : Icons.route_outlined,
                ),
                label: Text(label),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: c.primary),
                  const SizedBox(height: 14),
                  Text(
                    'جاري تحميل الخطوط…',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: c.text.withValues(alpha: 0.65),
                        ),
                  ),
                ],
              ),
            )
          : SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: RefreshIndicator(
                    color: c.primary,
                    onRefresh: _load,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            8,
                            16,
                            8,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: FilterChipsBar(
                              timeSlots: _timeSlots,
                              areaQuery: _areaQuery,
                              destinationQuery: _destinationQuery,
                              selectedTimeSlot: _timeSlot,
                              selectedGender: _gender,
                              departureQuery: _departureQuery,
                              returnQuery: _returnQuery,
                              extraAreaOptions: _originSearchPlaces,
                              extraDestinationOptions:
                                  _destinationSearchPlaces,
                              onAreaQueryChanged: (v) =>
                                  setState(() => _areaQuery = v),
                              onDestinationQueryChanged: (v) =>
                                  setState(() => _destinationQuery = v),
                              onTimeSlotChanged: (v) =>
                                  setState(() => _timeSlot = v),
                              onGenderChanged: (v) =>
                                  setState(() => _gender = v),
                              onDepartureQueryChanged: (v) =>
                                  setState(() => _departureQuery = v),
                              onReturnQueryChanged: (v) =>
                                  setState(() => _returnQuery = v),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              16,
                              10,
                              16,
                              4,
                            ),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: c.border.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Builder(
                            builder: (context) {
                              final status = _resultsStatus(filtered.length);
                              if (status == null) {
                                return const SizedBox(height: 6);
                              }
                              final showActiveDot = filtered.isNotEmpty &&
                                  _loadError == null;
                              return Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  16,
                                  8,
                                  16,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    if (showActiveDot) ...[
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF22C55E),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Flexible(
                                      child: Text(
                                        status,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: c.text
                                                  .withValues(alpha: 0.78),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (_loadError != null)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EmptyListingsState(
                              kind: EmptyListingsKind.error,
                              onPublish: _openMainAction,
                              onRetry: _load,
                            ),
                          )
                        else if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EmptyListingsState(
                              kind: _hasAnyFilter
                                  ? EmptyListingsKind.noMatch
                                  : EmptyListingsKind.promptSearch,
                              onPublish: _openMainAction,
                            ),
                          )
                        else ...[
                          SliverPadding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              16,
                              0,
                              16,
                              0,
                            ),
                            sliver: SliverList.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final listing = filtered[index];
                                return _ImpressionProbe(
                                  key: ValueKey('view-${listing.id}'),
                                  listing: listing,
                                  onAppear: _onCardAppeared,
                                  child: ListingCard(
                                    listing: listing,
                                    onContact: () => _onContact(listing),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (filtered.length < 6)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  20,
                                  16,
                                  8,
                                ),
                                child: _LowResultsCta(
                                  onPublish: _openMainAction,
                                ),
                              ),
                            ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 96),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _BackToTopButton extends StatelessWidget {
  const _BackToTopButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: 'العودة إلى الأعلى',
      child: Material(
        color: c.surface.withValues(alpha: isDark ? 0.92 : 0.96),
        elevation: 2.5,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        shape: CircleBorder(
          side: BorderSide(color: c.border.withValues(alpha: 0.75)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: c.primary,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectoryUsersChip extends StatelessWidget {
  const _DirectoryUsersChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: c.text.withValues(alpha: 0.82),
          height: 1.05,
        );
    return Semantics(
      label: DirectoryActivity.labelFor(count),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : c.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: c.border.withValues(alpha: isDark ? 0.4 : 0.65),
          ),
        ),
        // RTL: first child is on the right.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people,
              size: 15,
              color: c.primary,
            ),
            const SizedBox(width: 4),
            Text(
              DirectoryActivity.formatCount(count),
              maxLines: 1,
              softWrap: false,
              style: labelStyle,
            ),
            const SizedBox(width: 5),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'مستخدم',
              maxLines: 1,
              softWrap: false,
              style: labelStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fires [onAppear] when the card enters the scroll cache / viewport, and again
/// after it was disposed (scrolled away) and rebuilt — so repeated scroll-ins count.
class _ImpressionProbe extends StatefulWidget {
  const _ImpressionProbe({
    super.key,
    required this.listing,
    required this.onAppear,
    required this.child,
  });

  final Listing listing;
  final ValueChanged<Listing> onAppear;
  final Widget child;

  @override
  State<_ImpressionProbe> createState() => _ImpressionProbeState();
}

class _ImpressionProbeState extends State<_ImpressionProbe> {
  @override
  void initState() {
    super.initState();
    widget.onAppear(widget.listing);
  }

  @override
  void didUpdateWidget(covariant _ImpressionProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listing.id != widget.listing.id) {
      widget.onAppear(widget.listing);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _LowResultsCta extends StatelessWidget {
  const _LowResultsCta({required this.onPublish});

  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'سائق؟ انشر خطك في الدليل ليصل إليك الركاب بسهولة.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: c.text.withValues(alpha: 0.78),
                  ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onPublish,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              child: const Text('أضف خطك'),
            ),
          ],
        ),
      ),
    );
  }
}
