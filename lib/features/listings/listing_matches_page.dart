import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/matches/listing_route_match.dart';
import '../../core/matches/match_seen_store.dart';
import '../../core/models/listing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/listing_contact.dart';
import '../../data/listings_repository.dart';
import 'widgets/listing_card.dart';

class ListingMatchesPage extends StatefulWidget {
  const ListingMatchesPage({super.key, required this.mine});

  final Listing mine;

  @override
  State<ListingMatchesPage> createState() => _ListingMatchesPageState();
}

class _ListingMatchesPageState extends State<ListingMatchesPage> {
  List<Listing> _matches = const [];
  Set<String> _newIds = {};
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

  Future<void> _onContact(Listing listing) async {
    final options = ListingContact.optionsFor(listing);
    if (!mounted) return;
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد وسيلة تواصل لهذا الإعلان')),
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
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                for (final option in options) ...[
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: c.border),
                    ),
                    title: Text(
                      option.label,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: option.detail == null ||
                            option.detail!.trim().isEmpty
                        ? null
                        : Text(option.detail!),
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
                        'مطابقات $counterpart حسب المنطقة والوجهة الرئيسيتين فقط',
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
                                'لا توجد مطابقات بعد',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: c.text,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'عند نشر خط أو طلب بنفس منطقتك ووجهتك سيظهر هنا',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: c.text.withValues(alpha: 0.58),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        for (var i = 0; i < _matches.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          ListingCard(
                            listing: _matches[i],
                            badgeLabel: _newIds.contains(_matches[i].id)
                                ? 'جديد'
                                : null,
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
