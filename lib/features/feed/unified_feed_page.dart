import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/listings/unified_post_kind.dart';
import '../../core/listings/unified_search_query.dart';
import '../../core/models/listing.dart';
import '../../core/pwa/install_app_button.dart';
import '../../core/pwa/pwa_install.dart';
import '../../core/pwa/share_app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_toggle_button.dart';
import '../../data/listings_repository.dart';
import '../home/install_app_card.dart';
import '../listings/widgets/listing_card.dart';
import '../support/contact_admin_sheet.dart';
import 'unified_compose_sheet.dart';
import 'unified_search_sheet.dart';

class UnifiedFeedPage extends StatefulWidget {
  const UnifiedFeedPage({super.key});

  @override
  State<UnifiedFeedPage> createState() => _UnifiedFeedPageState();
}

enum _FeedKindFilter { all, available, wanted }

class _UnifiedFeedPageState extends State<UnifiedFeedPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  List<Listing> _items = const [];
  bool _loading = true;
  _FeedKindFilter _kind = _FeedKindFilter.all;
  UnifiedSearchQuery? _query;
  bool _showInstall = !PwaInstall.isStandalone;
  bool _showBackToTop = false;
  StreamSubscription<void>? _installStateSub;
  StreamSubscription<String>? _installOutcomeSub;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
    _installStateSub = PwaInstall.onStateChanged.listen((_) => _syncInstall());
    _installOutcomeSub = PwaInstall.onInstallOutcome.listen((outcome) {
      if (outcome == 'accepted') _syncInstall();
    });
    _syncInstall();
  }

  @override
  void dispose() {
    _installStateSub?.cancel();
    _installOutcomeSub?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final show = _scroll.offset > 360;
    if (show == _showBackToTop) return;
    setState(() => _showBackToTop = show);
  }

  Future<void> _scrollToTop() async {
    if (!_scroll.hasClients) return;
    await _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _syncInstall() {
    final show = !PwaInstall.isStandalone;
    if (!mounted || show == _showInstall) return;
    setState(() => _showInstall = show);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await ListingsRepository.shared.fetchAll(publishedOnly: true);
    if (!mounted) return;
    setState(() {
      _items = all;
      _loading = false;
    });
  }

  bool _matchesSearch(Listing listing) {
    final query = _query;
    if (query == null) return true;
    return query.matches(listing);
  }

  List<Listing> get _visible {
    return _items.where((l) {
      if (_kind == _FeedKindFilter.available && !l.isDriver) return false;
      if (_kind == _FeedKindFilter.wanted && l.isDriver) return false;
      return _matchesSearch(l);
    }).toList();
  }

  Future<void> _openSearch() async {
    final result = await showUnifiedSearchSheet(context, initial: _query);
    if (!mounted || result == null) return;
    setState(() {
      _query = result;
      _search.text = result.summary;
    });
  }

  void _clearSearch() {
    setState(() {
      _query = null;
      _search.clear();
    });
  }

  Future<void> _compose() async {
    final created = await showUnifiedComposeSheet(context);
    if (!mounted || created == null) return;
    await _load();
    if (!mounted) return;
    await showGuestSubmitReceivedDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final visible = _visible;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'دليل خطوط بغداد',
            maxLines: 1,
            softWrap: false,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
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
                ThemeToggleButton(),
                InstallAppIconButton(),
              ],
            ),
          ),
          IconButton(
            tooltip: 'التواصل مع الإدارة',
            onPressed: () => showContactAdminSheet(context),
            icon: const Icon(Icons.support_agent_rounded),
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
          FloatingActionButton.extended(
            onPressed: _compose,
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              'اكتب إعلاناً',
              style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      alignment: AlignmentDirectional.centerStart,
                      children: [
                        GestureDetector(
                          key: const Key('unified_search_field'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _openSearch,
                          child: IgnorePointer(
                            child: TextField(
                              controller: _search,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'ابحث في الإعلانات',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _query == null
                                    ? null
                                    : const SizedBox(width: 40, height: 40),
                              ),
                            ),
                          ),
                        ),
                        if (_query != null)
                          IconButton(
                            tooltip: 'مسح البحث',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close),
                          ),
                      ],
                    ),
                    if (_showInstall) ...[
                      const SizedBox(height: 10),
                      InstallAppCard(onInstalled: _syncInstall),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(
                          label: 'الكل',
                          selected: _kind == _FeedKindFilter.all,
                          onTap: () => setState(() {
                            _kind = _FeedKindFilter.all;
                          }),
                        ),
                        _Chip(
                          label: UnifiedPostKind.available,
                          icon: UnifiedPostKind.iconFor(ListingType.driver),
                          color: c.primary,
                          selected: _kind == _FeedKindFilter.available,
                          onTap: () => setState(
                            () => _kind = _FeedKindFilter.available,
                          ),
                        ),
                        _Chip(
                          label: UnifiedPostKind.wanted,
                          icon: UnifiedPostKind.iconFor(ListingType.rider),
                          color: UnifiedPostKind.colorFor(ListingType.rider, c),
                          selected: _kind == _FeedKindFilter.wanted,
                          onTap: () => setState(
                            () => _kind = _FeedKindFilter.wanted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'لا إعلانات بهذه التصفية',
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: c.text.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    return ListingCard(
                      listing: visible[i],
                      unifiedPublicCard: true,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = color ?? c.primary;
    return Material(
      color: selected ? tint.withValues(alpha: 0.16) : c.surface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? tint : c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: selected ? tint : c.text),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  height: 1.1,
                  color: selected ? tint : c.text,
                ),
              ),
            ],
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
