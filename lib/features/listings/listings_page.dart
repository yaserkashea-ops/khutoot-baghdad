import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/activity/directory_activity.dart';
import '../../core/auth/auth_gate_for_publishing.dart';
import '../../core/auth/publisher_auth_controller.dart';
import '../../core/bootstrap/app_bootstrap.dart';
import '../../core/data/baghdad_places.dart';
import '../../core/data/learned_places_store.dart';
import '../../core/data/places_catalog.dart';
import '../../core/models/listing.dart';
import '../../core/config/directory_launch.dart';
import '../../core/matches/listing_route_match.dart';
import '../../core/config/unlock_payment.dart';
import '../../core/models/contact_unlock.dart';
import '../../core/notifications/match_notify_service.dart';
import '../../core/notifications/notification_prefs.dart';
import '../../core/notifications/notifications_bell_button.dart';
import '../../core/notifications/publish_notify_service.dart';
import '../../core/notifications/publisher_push_registrar.dart';
import '../../core/notifications/unlock_notify_service.dart';
import '../../core/pwa/app_install_tracker.dart';
import '../../core/pwa/install_app_button.dart';
import '../../core/pwa/pwa_install.dart';
import '../../core/pwa/share_app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_toggle_button.dart';
import '../../core/utils/listing_contact.dart';
import '../../core/widgets/app_kit.dart';
import '../../core/widgets/contact_options_sheet.dart';
import '../../data/contact_unlocks_repository.dart';
import '../../data/listings_repository.dart';
import '../../data/publisher_repository.dart';
import '../support/contact_admin_sheet.dart';
import 'my_listings_page.dart';
import 'publish_listing_page.dart';
import 'publish_rider_page.dart';
import 'publish_role_sheet.dart';
import 'widgets/empty_listings_state.dart';
import 'directory_browse.dart';
import 'directory_mode.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/listing_card.dart';
import 'widgets/rider_book_sheet.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key, this.repository, this.showFab = true});

  final ListingsRepository? repository;
  final bool showFab;

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
  String _areaQuery = '';
  String _destinationQuery = '';
  String _timeSlot = 'صباحي';
  String? _gender;
  String _departureQuery = '';
  String _returnQuery = '';
  final ScrollController _scrollController = ScrollController();
  final List<String> _pendingViewIds = <String>[];
  Timer? _viewFlushTimer;
  bool _showBackToTop = false;
  bool _ridersTab = false;
  Map<String, ContactUnlock> _unlocks = const {};

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
    DirectoryBrowse.query.addListener(_onBrowseIntent);
    _applyBrowse(DirectoryBrowse.query.value);
    _load();
  }

  void _onBrowseIntent() => _applyBrowse(DirectoryBrowse.query.value);

  void _applyBrowse(DirectoryBrowseQuery? q) {
    if (q == null || !mounted) return;
    setState(() {
      _ridersTab = q.riders;
      _areaQuery = q.area;
      _destinationQuery = q.destination;
      _timeSlot = (q.timeSlot == 'مسائي') ? 'مسائي' : 'صباحي';
    });
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
    UnlockNotifyService.shared.start();
    unawaited(PublisherPushRegistrar.register());
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
    await DirectoryActivity.syncOnLaunch();
  }

  @override
  void dispose() {
    _viewFlushTimer?.cancel();
    unawaited(_flushPendingViews());
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onListScroll);
    DirectoryBrowse.query.removeListener(_onBrowseIntent);
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
      if (!DirectoryLaunch.freeRiderContacts) {
        unawaited(_loadUnlocks());
      }
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
      if (_ridersTab) {
        if (l.isDriver) return false;
      } else {
        if (!l.isDriver) return false;
      }
      if (areaQ.isNotEmpty &&
          !ListingRouteMatch.matchesOriginQuery(l, areaQ)) {
        return false;
      }
      if (destQ.isNotEmpty &&
          !ListingRouteMatch.matchesDestinationQuery(l, destQ)) {
        return false;
      }
      if (l.timePeriodLabel != _timeSlot) {
        return false;
      }
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

  bool get _incompletePlaceSearch {
    final a = _areaQuery.trim().isNotEmpty;
    final d = _destinationQuery.trim().isNotEmpty;
    return a != d;
  }

  bool get _hasPlaceSearch =>
      _areaQuery.trim().isNotEmpty || _destinationQuery.trim().isNotEmpty;

  bool get _hasAnyFilter =>
      _hasPlaceSearch ||
      _gender != null ||
      _departureQuery.trim().isNotEmpty ||
      _returnQuery.trim().isNotEmpty;

  /// Places searchable in "من أين؟" — main departure + all origin subs.
  List<String> get _originSearchPlaces {
    final out = <String>{};
    for (final l in _all) {
      out.addAll(ListingRouteMatch.originPlaces(l));
    }
    return out.toList();
  }

  /// Places searchable in "إلى أين؟" — main destination + all destination subs.
  List<String> get _destinationSearchPlaces {
    final out = <String>{};
    for (final l in _all) {
      out.addAll(ListingRouteMatch.destinationPlaces(l));
    }
    return out.toList();
  }

  String _genderKey(Listing l) => switch (l.genderRequirement) {
        GenderRequirement.maleOnly => 'male_only',
        GenderRequirement.femaleOnly => 'female_only',
        GenderRequirement.mixed => 'mixed',
      };

  static const _timeSlots = <String>['صباحي', 'مسائي'];

  Future<void> _openMyListings({bool blocking = false}) async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MyListingsPage(
          onBrowse: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openPublish({required bool asRider}) async {
    if (!await AuthGateForPublishing.ensure(context, asRider: asRider)) return;
    if (!mounted) return;
    if (!await confirmPublishLane(context, asRider: asRider)) return;
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => asRider
            ? const PublishRiderPage()
            : PublishListingPage(
                repository: ListingsRepository.shared,
                initialType: ListingType.driver,
                asDirectoryRequest: true,
              ),
      ),
    );
    if (mounted) unawaited(_load());
  }

  Future<void> _loadUnlocks() async {
    if (DirectoryLaunch.freeRiderContacts) return;
    try {
      final rows = await ContactUnlocksRepository.shared.mine();
      if (!mounted) return;
      setState(() {
        _unlocks = {for (final u in rows) u.riderRequestId: u};
      });
    } catch (_) {}
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

  Future<void> _onRiderContact(Listing listing) async {
    final existing = _unlocks[listing.id];
    final updated = await openRiderBooking(
      context,
      listing: listing,
      existing: existing,
    );
    if (!mounted || updated == null) return;
    setState(() {
      _unlocks = {..._unlocks, listing.id: updated};
      if (updated.isPending || updated.isApproved) {
        _all = [
          for (final l in _all)
            l.id == listing.id ? l.copyWith(isBooked: true) : l,
        ];
      }
    });
  }

  Future<void> _onContact(Listing listing) async {
    if (!listing.isDriver && !DirectoryLaunch.freeRiderContacts) {
      await _onRiderContact(listing);
      return;
    }
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

    final chosen = await showContactOptionsSheet(
      context,
      title: listing.isDriver ? 'تواصل مع السائق' : 'تواصل مع الراكب',
      options: options,
    );
    if (chosen == null) return;
    await ListingContact.openUrl(chosen.url);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filtered = _incompletePlaceSearch ? const <Listing>[] : _filtered;

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
        actionsPadding: const EdgeInsetsDirectional.only(end: 2),
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
                NotificationsBellButton(),
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
          if (widget.showFab)
            ListenableBuilder(
            listenable: PublisherAuthController.shared,
            builder: (context, _) {
              final inAccount = PublisherAuthController.shared.isLoggedIn;
              return FloatingActionButton.extended(
                onPressed: () => _openMyListings(blocking: !inAccount),
                tooltip: inAccount ? 'حسابي' : 'اضافة',
                icon: Icon(
                  inAccount ? Icons.person_rounded : Icons.add_rounded,
                ),
                label: Text(inAccount ? 'حسابي' : 'اضافة'),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const LoadingSkeleton(lines: 5)
          : SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: RefreshIndicator(
                    color: DirectoryMode(riders: _ridersTab).accent(c),
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
                              ridersTab: _ridersTab,
                              onRidersTabChanged: (v) =>
                                  setState(() => _ridersTab = v),
                              onShowResults: () {
                                _scrollController.animateTo(
                                  280,
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                );
                              },
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
                        if (_loadError != null)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EmptyListingsState(
                              kind: EmptyListingsKind.error,
                              forRiders: _ridersTab,
                              onPublish: () => _openMyListings(blocking: true),
                              onRetry: _load,
                            ),
                          )
                        else if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EmptyListingsState(
                              kind: _incompletePlaceSearch
                                  ? EmptyListingsKind.incompleteSearch
                                  : _hasAnyFilter
                                  ? EmptyListingsKind.noMatch
                                  : EmptyListingsKind.promptSearch,
                              forRiders: _ridersTab,
                              onPublish: () => _openMyListings(blocking: true),
                              onAdjustSearch: () => _scrollToTop(),
                              onInvite: () =>
                                  _openPublish(asRider: !_ridersTab),
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
                                final unlock = _unlocks[listing.id];
                                final revealed =
                                    unlock != null && unlock.isApproved;
                                final pending =
                                    unlock != null && unlock.isPending;
                                return _ImpressionProbe(
                                  key: ValueKey('view-${listing.id}'),
                                  listing: listing,
                                  onAppear: _onCardAppeared,
                                  child: ListingCard(
                                    listing: DirectoryLaunch.freeRiderContacts ||
                                            revealed ||
                                            listing.isDriver
                                        ? listing
                                        : listing.withoutPublicContacts(),
                                    onContact: () => _onContact(listing),
                                    revealPending:
                                        DirectoryLaunch.freeRiderContacts
                                            ? false
                                            : pending,
                                    contactRevealed:
                                        DirectoryLaunch.freeRiderContacts ||
                                            revealed,
                                    contactLabel: listing.isDriver ||
                                            DirectoryLaunch.freeRiderContacts
                                        ? null
                                        : (revealed
                                            ? 'تواصل مع الراكب'
                                            : UnlockPayment.bookAction),
                                  ),
                                );
                              },
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
