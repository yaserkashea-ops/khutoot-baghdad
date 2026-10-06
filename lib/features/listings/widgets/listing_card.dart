import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/listings/legacy_listing_adapter.dart';
import '../../../core/listings/unified_post_kind.dart';
import '../../../core/utils/listing_contact.dart';
import '../../../core/models/listing.dart';
import '../../../core/config/directory_launch.dart';
import '../../../core/listings/publish_draft_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_kit.dart';

class ListingCard extends StatefulWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.onContact,
    this.highlighted = false,
    this.badgeLabel,
    this.contactLabel,
    this.revealPending = false,
    this.contactRevealed = false,
    this.showContactAction = true,
    this.unifiedPublicCard = false,
  });

  final Listing listing;
  final VoidCallback? onContact;
  final bool highlighted;
  final String? badgeLabel;
  final String? contactLabel;
  final bool revealPending;
  final bool contactRevealed;
  final bool showContactAction;
  final bool unifiedPublicCard;

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> {
  bool _detailsOpen = false;

  Listing get listing => widget.listing;

  bool get _canSave {
    final id = listing.id.trim();
    return id.isNotEmpty && id != 'preview';
  }

  @override
  void initState() {
    super.initState();
    if (_canSave) {
      unawaited(() async {
        await PublishDraftStore.savedIds();
        if (mounted) setState(() {});
      }());
    }
  }

  String get _contactLabel {
    if (widget.contactLabel != null) return widget.contactLabel!;
    if (!listing.isDriver) return 'تواصل مع الراكب';
    return 'تواصل مع السائق';
  }

  bool get _hideContact {
    if (listing.seatsCount == 0) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final view = LegacyListingAdapter.toView(listing);
    final isRider = !listing.isDriver;
    final accent = UnifiedPostKind.colorFor(listing.type, c);
    final wash = Color.lerp(
      c.surface,
      accent,
      view.available ? 0.05 : 0.035,
    )!;
    final typeRibbon = (widget.badgeLabel != null &&
            widget.badgeLabel!.trim().isNotEmpty)
        ? widget.badgeLabel!.trim()
        : view.kindLabel;
    final details = listing.routeDetails;
    final showMore = details != null && details.length > 100;
    final visibleDetails = details == null
        ? null
        : (_detailsOpen || !showMore
            ? details
            : '${details.substring(0, 100).trim()}…');

    return Material(
      color: widget.unifiedPublicCard ? wash : c.surface,
      borderRadius: AppTokens.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.unifiedPublicCard ? null : widget.onContact,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: AppTokens.restShadow(c.text),
            border: BorderDirectional(
              start: BorderSide(
                color: accent.withValues(alpha: view.available ? 1 : 0.72),
                width: widget.unifiedPublicCard
                    ? (view.available ? 4 : 3)
                    : 3,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (listing.showsLivePulse) ...[
                    const _LivePulseDot(),
                    const SizedBox(width: 6),
                  ],
                  _KindIdentityChip(
                    label: typeRibbon,
                    icon: UnifiedPostKind.iconFor(listing.type),
                    color: accent,
                    available: view.available,
                  ),
                  if (view.legacyBadge != null) ...[
                    const SizedBox(width: 8),
                    AppBadge(label: view.legacyBadge!, color: accent),
                  ] else if (listing.directoryRibbon.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    AppBadge(label: listing.directoryRibbon, color: accent),
                  ],
                  const Spacer(),
                  if (widget.unifiedPublicCard)
                    Text(
                      listing.timePeriodLabel,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: accent,
                      ),
                    ),
                  if (_canSave && !widget.unifiedPublicCard)
                    ListenableBuilder(
                      listenable: PublishDraftStore.savedRevision,
                      builder: (context, _) {
                        final saved = PublishDraftStore.isSaved(listing.id);
                        return IconButton(
                          tooltip: saved ? 'إزالة من المحفوظات' : 'حفظ',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          onPressed: () =>
                              PublishDraftStore.toggleSaved(listing.id),
                          icon: Icon(
                            saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 22,
                            color: saved
                                ? accent
                                : AppTokens.muted(c.text),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (isRider &&
                  listing.isBooked &&
                  !DirectoryLaunch.freeRiderContacts) ...[
                const AppBadge(label: 'محجوز', color: Color(0xFFB5623F)),
                const SizedBox(height: 8),
              ],
              if (view.routeLine.isNotEmpty)
                Text(
                  view.routeLine,
                  softWrap: true,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        color: c.text,
                        height: 1.35,
                      ),
                ),
              if (!widget.unifiedPublicCard && listing.hasRouteSubs) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if (listing.originSubs.isNotEmpty) listing.originSubsLabel,
                    if (listing.destinationSubs.isNotEmpty)
                      listing.destinationSubsLabel,
                  ].join(' ← '),
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w500,
                    fontSize: 12.5,
                    color: accent,
                  ),
                ),
              ],
              if (!widget.unifiedPublicCard) ...[
                const SizedBox(height: 8),
                Text(
                  [
                    listing.scheduleLabel,
                    if (listing.publicGenderLabel != null)
                      listing.publicGenderLabel!,
                  ].join(' · '),
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    color: AppTokens.muted(c.text),
                  ),
                ),
                if (listing.seatsCount != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    listing.isDriver
                        ? '${listing.seatsCount} مقاعد شاغرة'
                        : '${listing.seatsCount} مقاعد مطلوبة',
                    style: AppTheme.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                ],
                if (listing.isDriver &&
                    (listing.vehicleType ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'نوع السيارة: ${listing.vehicleType!.trim()}',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12,
                      color: AppTokens.muted(c.text),
                    ),
                  ),
                ],
                if (isRider && visibleDetails != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    visibleDetails,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 13,
                      height: 1.45,
                      color: c.text.withValues(alpha: 0.82),
                    ),
                  ),
                  if (showMore)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _detailsOpen = !_detailsOpen),
                        child: Text(_detailsOpen ? 'عرض أقل' : 'عرض المزيد'),
                      ),
                    ),
                ],
              ] else if ((view.body ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  view.body!,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    height: 1.45,
                    color: c.text.withValues(alpha: 0.82),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (!widget.unifiedPublicCard)
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppTokens.muted(c.text),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        listing.lastUpdateLabel,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 11,
                          color: AppTokens.muted(c.text),
                        ),
                      ),
                    ),
                  ],
                ),
              if (widget.showContactAction &&
                  (widget.unifiedPublicCard || !_hideContact)) ...[
                const SizedBox(height: 10),
                if (isRider &&
                    listing.isBooked &&
                    !widget.contactRevealed &&
                    !DirectoryLaunch.freeRiderContacts)
                  Text(
                    'محجوز — بانتظار التأكد أنه لا يزال متاحاً',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTokens.muted(c.text),
                    ),
                  )
                else if (isRider &&
                    widget.revealPending &&
                    !DirectoryLaunch.freeRiderContacts)
                  Text(
                    'بانتظار التأكيد',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: accent,
                    ),
                  )
                else if (widget.unifiedPublicCard)
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final option in view.contacts)
                              _CompactContactButton(
                                option: option,
                                color: accent,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        view.postedLabel,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 11,
                          color: AppTokens.muted(c.text),
                        ),
                      ),
                    ],
                  )
                else
                  AppButton(
                    label: _contactLabel,
                    outlined: true,
                    color: accent,
                    onPressed: widget.onContact,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KindIdentityChip extends StatelessWidget {
  const _KindIdentityChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.available,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: available ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactContactButton extends StatelessWidget {
  const _CompactContactButton({
    required this.option,
    required this.color,
  });

  final ContactOption option;
  final Color color;

  IconData get _icon {
    switch (option.label) {
      case 'اتصال':
        return Icons.call_rounded;
      case 'واتساب':
        return Icons.chat_rounded;
      case 'تلغرام':
        return Icons.send_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: option.label,
      child: Material(
        color: color.withValues(alpha: 0.07),
        shape: StadiumBorder(
          side: BorderSide(color: color.withValues(alpha: 0.22)),
        ),
        child: InkWell(
          onTap: () => ListingContact.openUrl(option.url),
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon, size: 13, color: color),
                const SizedBox(width: 3),
                Text(
                  option.label,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1.1,
                    color: color,
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

class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot();

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'نشط',
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
        child: Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: Color(0xFF22A45A),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
