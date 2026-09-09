import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/baghdad_places.dart';
import '../../core/models/listing.dart';
import '../../core/pwa/install_app_button.dart';
import '../../core/pwa/pwa_install.dart';
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

  String _areaQuery = '';
  String _destinationQuery = '';
  String? _timeSlot; // صباحي | مسائي
  String? _gender;

  @override
  void initState() {
    super.initState();
    PwaInstall.setMode('app');
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _repository.fetchAll();
    if (!mounted) return;
    setState(() {
      _all = items;
      _loading = false;
    });
  }

  List<Listing> get _filtered {
    final areaQ = _areaQuery.trim();
    final destQ = _destinationQuery.trim();
    return _all.where((l) {
      if (areaQ.isNotEmpty && !_matchesPlace(l, areaQ, preferArea: true)) {
        return false;
      }
      if (destQ.isNotEmpty && !_matchesPlace(l, destQ, preferArea: false)) {
        return false;
      }
      if (_timeSlot != null && l.timePeriodLabel != _timeSlot) return false;
      if (_gender != null && _genderKey(l) != _gender) return false;
      return true;
    }).toList();
  }

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

  List<String> get _areas =>
      _all.map((e) => e.area).toSet().toList()..sort();

  List<String> get _destinations =>
      _all.map((e) => e.destination).toSet().toList()..sort();

  static const _timeSlots = <String>['صباحي', 'مسائي'];

  Future<void> _onPublish() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PublishListingPage(repository: _repository),
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
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w400,
              color: c.onPrimary,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _onContact(Listing listing) async {
    final opened = await ListingContact.open(listing);
    if (opened || !mounted) return;
    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.text,
        content: Text(
          'لا توجد وسيلة تواصل لهذا الإعلان',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w400,
            color: c.onPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'خطوط بغداد',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          const InstallAppIconButton(),
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'التواصل مع الإدارة',
            onPressed: () => showContactAdminSheet(context),
            icon: const Icon(Icons.support_agent_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onPublish,
        tooltip: 'نشر إعلان',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: c.primary),
            )
          : SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          4,
                          16,
                          12,
                        ),
                        child: FilterChipsBar(
                          areas: _areas,
                          destinations: _destinations,
                          timeSlots: _timeSlots,
                          areaQuery: _areaQuery,
                          destinationQuery: _destinationQuery,
                          selectedTimeSlot: _timeSlot,
                          selectedGender: _gender,
                          onAreaQueryChanged: (v) =>
                              setState(() => _areaQuery = v),
                          onDestinationQueryChanged: (v) =>
                              setState(() => _destinationQuery = v),
                          onTimeSlotChanged: (v) =>
                              setState(() => _timeSlot = v),
                          onGenderChanged: (v) => setState(() => _gender = v),
                        ),
                      ),
                      Divider(height: 1, color: c.border),
                      Expanded(
                        child: filtered.isEmpty
                            ? EmptyListingsState(onPublish: _onPublish)
                            : RefreshIndicator(
                                color: c.primary,
                                onRefresh: _load,
                                child: ListView.separated(
                                  padding:
                                      const EdgeInsetsDirectional.fromSTEB(
                                    0,
                                    8,
                                    0,
                                    88,
                                  ),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, _) => Divider(
                                    height: 1,
                                    color: c.border,
                                  ),
                                  itemBuilder: (context, index) {
                                    final listing = filtered[index];
                                    return ListingCard(
                                      listing: listing,
                                      onContact: () => _onContact(listing),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
