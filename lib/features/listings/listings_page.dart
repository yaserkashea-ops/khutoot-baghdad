import 'package:flutter/material.dart';

import '../../core/data/baghdad_places.dart';
import '../../core/models/listing.dart';
import '../../core/pwa/install_app_button.dart';
import '../../core/pwa/pwa_install.dart';
import '../../core/pwa/share_app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_toggle_button.dart';
import '../../core/utils/listing_contact.dart';
import '../../data/listings_repository.dart';
import '../support/contact_admin_sheet.dart';
import 'publish_listing_page.dart';
import 'widgets/empty_listings_state.dart';
import 'widgets/filter_chips_bar.dart';
import 'widgets/listing_card.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key, this.repository});

  final ListingsRepository? repository;

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  late final ListingsRepository _repository =
      widget.repository ?? ListingsRepository.shared;

  List<Listing> _all = [];
  bool _loading = true;
  String? _loadError;

  String _areaQuery = '';
  String _destinationQuery = '';
  String? _timeSlot; // صباحي | مسائي
  String? _gender;
  String _departureQuery = '';
  String _returnQuery = '';
  ListingType? _listingType; // null = الكل

  @override
  void initState() {
    super.initState();
    PwaInstall.setMode('app');
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final items = await _repository.fetchAll();
      if (!mounted) return;
      setState(() {
        _all = items;
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
    return _all.where((l) {
      if (areaQ.isNotEmpty && !_matchesPlace(l, areaQ, preferArea: true)) {
        return false;
      }
      if (destQ.isNotEmpty && !_matchesPlace(l, destQ, preferArea: false)) {
        return false;
      }
      if (_timeSlot != null && l.timePeriodLabel != _timeSlot) return false;
      if (_gender != null && _genderKey(l) != _gender) return false;
      if (_listingType != null && l.type != _listingType) return false;
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
  }

  bool get _hasPlaceSearch =>
      _areaQuery.trim().isNotEmpty || _destinationQuery.trim().isNotEmpty;

  bool get _hasAnyFilter =>
      _hasPlaceSearch ||
      _timeSlot != null ||
      _gender != null ||
      _listingType != null ||
      _departureQuery.trim().isNotEmpty ||
      _returnQuery.trim().isNotEmpty;

  /// Match main area/destination or any nested from/to sub-points.
  bool _matchesPlace(Listing l, String query, {required bool preferArea}) {
    if (preferArea) {
      if (BaghdadPlaces.matchesQuery(l.area, query)) return true;
      return l.originSubs.any((s) => BaghdadPlaces.matchesQuery(s, query));
    }
    if (BaghdadPlaces.matchesQuery(l.destination, query)) return true;
    return l.destinationSubs.any((s) => BaghdadPlaces.matchesQuery(s, query));
  }

  String _genderKey(Listing l) => switch (l.genderRequirement) {
        GenderRequirement.maleOnly => 'male_only',
        GenderRequirement.femaleOnly => 'female_only',
        GenderRequirement.mixed => 'mixed',
      };

  List<String> get _areas => {
        ..._all.map((e) => e.area),
        ..._all.expand((e) => e.originSubs),
      }.toList()
        ..sort();

  List<String> get _destinations => {
        ..._all.map((e) => e.destination),
        ..._all.expand((e) => e.destinationSubs),
      }.toList()
        ..sort();

  static const _timeSlots = <String>['صباحي', 'مسائي'];

  String? _resultsStatus(int count) {
    if (_loadError != null) return 'تعذر تحميل النتائج';
    if (count == 0) {
      return _hasAnyFilter ? 'لم نجد خطوطاً مطابقة' : null;
    }
    return '$count خطاً متاحاً';
  }

  Future<void> _choosePublishType() async {
    final c = context.colors;
    final choice = await showModalBottomSheet<ListingType>(
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
                  'أنشر',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'اختر نوع إعلانك',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: c.text.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 16),
                _PublishChoiceTile(
                  icon: Icons.person_search_outlined,
                  title: 'أبحث عن مقعد',
                  subtitle: 'راكب يريد الانضمام لخط',
                  color: c.riderAccent,
                  onTap: () => Navigator.pop(ctx, ListingType.rider),
                ),
                const SizedBox(height: 10),
                _PublishChoiceTile(
                  icon: Icons.directions_car_outlined,
                  title: 'لدي مقاعد متاحة',
                  subtitle: 'سائق يعرض خطاً',
                  color: c.accent,
                  onTap: () => Navigator.pop(ctx, ListingType.driver),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    await _onPublish(initialType: choice);
  }

  Future<void> _onPublish({ListingType? initialType}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PublishListingPage(
          repository: _repository,
          initialType: initialType,
        ),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      await _load();
      if (!mounted) return;
      final c = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.primary,
          duration: const Duration(seconds: 2),
          content: Text(
            'تم نشر الإعلان بنجاح',
            style: TextStyle(color: c.onPrimary),
          ),
        ),
      );
    }
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
                    title: Text(option.label),
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
    final wideFab = MediaQuery.sizeOf(context).width >= 390;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('خطوط بغداد'),
        actions: [
          const ShareAppIconButton(),
          const InstallAppIconButton(),
          const ThemeToggleButton(),
          Semantics(
            button: true,
            label: 'التواصل مع الإدارة',
            child: IconButton(
              tooltip: 'التواصل مع الإدارة',
              onPressed: () => showContactAdminSheet(context),
              icon: const Icon(Icons.help_outline_rounded),
            ),
          ),
        ],
      ),
      floatingActionButton: wideFab
          ? FloatingActionButton.extended(
              onPressed: _choosePublishType,
              tooltip: 'أنشر',
              icon: const Icon(Icons.add),
              label: const Text('أنشر'),
            )
          : FloatingActionButton(
              onPressed: _choosePublishType,
              tooltip: 'أنشر',
              child: const Icon(Icons.add),
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
                              areas: _areas,
                              destinations: _destinations,
                              timeSlots: _timeSlots,
                              areaQuery: _areaQuery,
                              destinationQuery: _destinationQuery,
                              selectedTimeSlot: _timeSlot,
                              selectedGender: _gender,
                              departureQuery: _departureQuery,
                              returnQuery: _returnQuery,
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
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              16,
                              12,
                              16,
                              4,
                            ),
                            child: _ListingTypeFilter(
                              selected: _listingType,
                              onChanged: (v) =>
                                  setState(() => _listingType = v),
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
                              return Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  16,
                                  8,
                                  16,
                                  10,
                                ),
                                child: Text(
                                  status,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: c.text.withValues(alpha: 0.78),
                                      ),
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
                              onPublish: _choosePublishType,
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
                              onPublish: _choosePublishType,
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
                                return ListingCard(
                                  listing: listing,
                                  onContact: () => _onContact(listing),
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
                                  onPublish: _choosePublishType,
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

class _ListingTypeFilter extends StatelessWidget {
  const _ListingTypeFilter({
    required this.selected,
    required this.onChanged,
  });

  final ListingType? selected;
  final ValueChanged<ListingType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final options = <(ListingType? value, String label)>[
      (null, 'الكل'),
      (ListingType.driver, 'سائقون'),
      (ListingType.rider, 'راكبون'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'نوع المنشور',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 12,
                color: c.text.withValues(alpha: 0.55),
              ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0)
                  Container(width: 1, height: 28, color: c.border),
                Expanded(
                  child: Material(
                    color: selected == options[i].$1
                        ? c.primary.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    child: InkWell(
                      onTap: () => onChanged(options[i].$1),
                      borderRadius: BorderRadius.circular(11),
                      child: SizedBox(
                        height: 44,
                        child: Center(
                          child: Text(
                            options[i].$2,
                            style: TextStyle(
                              fontWeight: selected == options[i].$1
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 13,
                              color: selected == options[i].$1
                                  ? c.primary
                                  : c.text.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PublishChoiceTile extends StatelessWidget {
  const _PublishChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.text.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: c.text.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
              'لم تجد خطك؟ انشر طلبك وساعد الآخرين على العثور عليك.',
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
              child: const Text('انشر طلباً'),
            ),
          ],
        ),
      ),
    );
  }
}
