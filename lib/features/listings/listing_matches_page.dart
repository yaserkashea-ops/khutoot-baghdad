import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/publisher_auth_controller.dart';
import '../../core/config/directory_launch.dart';
import '../../core/config/unlock_payment.dart';
import '../../core/matches/listing_route_match.dart';
import '../../core/matches/match_seen_store.dart';
import '../../core/models/contact_unlock.dart';
import '../../core/models/listing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/listing_contact.dart';
import '../../core/widgets/contact_options_sheet.dart';
import '../../data/contact_unlocks_repository.dart';
import '../../data/listings_repository.dart';
import 'publish_listing_page.dart';
import 'publish_rider_page.dart';
import 'publish_role_sheet.dart';
import 'publisher_auth_sheet.dart';
import 'widgets/listing_card.dart';
import 'widgets/rider_book_sheet.dart';

class ListingMatchesPage extends StatefulWidget {
  const ListingMatchesPage({super.key, required this.mine});

  final Listing mine;

  @override
  State<ListingMatchesPage> createState() => _ListingMatchesPageState();
}

class _ListingMatchesPageState extends State<ListingMatchesPage> {
  List<Listing> _matches = const [];
  Set<String> _newIds = {};
  Map<String, ContactUnlock> _unlocks = const {};
  bool _loading = true;
  String? _error;
  int _newCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows =
          await ListingsRepository.shared.fetchRouteMatches(widget.mine);
      var unlocks = <String, ContactUnlock>{};
      if (!DirectoryLaunch.freeRiderContacts) {
        try {
          final mineUnlocks = await ContactUnlocksRepository.shared.mine();
          unlocks = {for (final u in mineUnlocks) u.riderRequestId: u};
        } catch (_) {}
      }
      final seen = await MatchSeenStore.seenIds(widget.mine.id);
      final fresh = <String>{};
      for (final m in rows) {
        if (!seen.contains(m.id)) fresh.add(m.id);
      }
      if (!mounted) return;
      setState(() {
        _matches = rows;
        _newIds = fresh;
        _newCount = fresh.length;
        _unlocks = unlocks;
        _loading = false;
      });
      if (rows.isNotEmpty) {
        await MatchSeenStore.markSeen(
          widget.mine.id,
          rows.map((e) => e.id),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل المطابقات. حاول مجدداً.';
      });
    }
  }

  Future<void> _inviteAdd({required bool asRider}) async {
    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!auth.isLoggedIn) {
      if (!mounted) return;
      final ok = await showPublisherAuthSheet(
        context,
        title: asRider ? 'سجّل لإضافة طلب راكب' : 'سجّل لإضافة خط سائق',
        requiredToContinue: true,
      );
      if (!ok || !mounted) return;
    }
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
  }

  Future<void> _onContact(Listing listing) async {
    if (!listing.isDriver && !DirectoryLaunch.freeRiderContacts) {
      final unlock = _unlocks[listing.id];
      final updated = await openRiderBooking(
        context,
        listing: listing,
        existing: unlock,
      );
      if (!mounted || updated == null) return;
      setState(() {
        _unlocks = {..._unlocks, listing.id: updated};
        if (updated.isPending || updated.isApproved) {
          _matches = [
            for (final l in _matches)
              l.id == listing.id ? l.copyWith(isBooked: true) : l,
          ];
        }
      });
      return;
    }
    final options = ListingContact.optionsFor(listing);
    if (!mounted) return;
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد وسيلة تواصل لهذا الإعلان')),
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
    final mine = widget.mine;
    final counterpart = mine.isDriver ? 'باحثون عن خط' : 'سائقون';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المطابقات',
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      Text(
                        '${mine.area} ← ${mine.destination}',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مطابقات $counterpart عند تطابق الانطلاق والوجهة معاً (رئيسية أو فرعية) ونفس التوقيت',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          height: 1.4,
                          color: c.text.withValues(alpha: 0.58),
                        ),
                      ),
                      if (_newCount > 0) ...[
                        const SizedBox(height: 14),
                        _NewMatchesBanner(
                          label: ListingRouteMatch.newMatchesLabel(_newCount),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_matches.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.route_outlined,
                                size: 44,
                                color: c.text.withValues(alpha: 0.32),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد مطابقات لهذا البحث',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: c.text,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.mine.isDriver
                                    ? 'لا طلب مطابق. أضف خط سائق ليظهر للركاب.'
                                    : 'لا خط مطابق. أضف طلب خط ليظهر للسائقين.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: c.text.withValues(alpha: 0.58),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () =>
                                    _inviteAdd(asRider: !widget.mine.isDriver),
                                child: Text(
                                  widget.mine.isDriver
                                      ? 'اضافة خط سائق'
                                      : 'اضافة طلب خط',
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        for (var i = 0; i < _matches.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          ListingCard(
                            listing: () {
                              final item = _matches[i];
                              if (item.isDriver ||
                                  DirectoryLaunch.freeRiderContacts) {
                                return item;
                              }
                              final revealed =
                                  _unlocks[item.id]?.isApproved == true;
                              return revealed
                                  ? item
                                  : item.withoutPublicContacts();
                            }(),
                            badgeLabel: _newIds.contains(_matches[i].id)
                                ? 'جديد'
                                : null,
                            revealPending: DirectoryLaunch.freeRiderContacts
                                ? false
                                : _unlocks[_matches[i].id]?.isPending == true,
                            contactRevealed:
                                DirectoryLaunch.freeRiderContacts ||
                                    _unlocks[_matches[i].id]?.isApproved == true,
                            contactLabel: _matches[i].isDriver
                                ? null
                                : (DirectoryLaunch.freeRiderContacts ||
                                        _unlocks[_matches[i].id]?.isApproved ==
                                            true
                                    ? 'تواصل مع الراكب'
                                    : UnlockPayment.bookAction),
                            onContact: () => _onContact(_matches[i]),
                          ),
                        ],
                    ],
                  ),
                ),
    );
  }
}

class _NewMatchesBanner extends StatelessWidget {
  const _NewMatchesBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            c.primary.withValues(alpha: 0.14),
            c.primary.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: c.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: c.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
