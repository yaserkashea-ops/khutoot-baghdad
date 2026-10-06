import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/baghdad_places.dart';
import '../../core/listings/unified_search_query.dart';
import '../../core/models/listing.dart';
import '../../core/theme/app_colors.dart';
import 'place_suggest_field.dart';

Future<UnifiedSearchQuery?> showUnifiedSearchSheet(
  BuildContext context, {
  UnifiedSearchQuery? initial,
}) {
  return showModalBottomSheet<UnifiedSearchQuery>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => UnifiedSearchSheet(initial: initial),
  );
}

class UnifiedSearchSheet extends StatefulWidget {
  const UnifiedSearchSheet({super.key, this.initial});

  final UnifiedSearchQuery? initial;

  @override
  State<UnifiedSearchSheet> createState() => _UnifiedSearchSheetState();
}

class _UnifiedSearchSheetState extends State<UnifiedSearchSheet> {
  late final TextEditingController _origin;
  late final TextEditingController _destination;
  TimePeriod? _time;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _origin = TextEditingController(text: initial?.origin ?? '');
    _destination = TextEditingController(text: initial?.destination ?? '');
    _time = initial?.time;
  }

  @override
  void dispose() {
    _origin.dispose();
    _destination.dispose();
    super.dispose();
  }

  List<String> get _places => BaghdadPlaces.prioritize({
        ...BaghdadPlaces.areas,
        ...BaghdadPlaces.destinations,
      });

  bool _knownPlace(String value) {
    return BaghdadPlaces.areas.contains(value) ||
        BaghdadPlaces.destinations.contains(value) ||
        _places.contains(value);
  }

  void _submit() {
    final origin = _origin.text.trim();
    final dest = _destination.text.trim();
    if (origin.isEmpty) {
      setState(() => _error = 'اختر منطقة الانطلاق');
      return;
    }
    if (dest.isEmpty) {
      setState(() => _error = 'اختر منطقة الوصول');
      return;
    }
    if (!_knownPlace(origin)) {
      setState(() => _error = 'اختر منطقة الانطلاق من القائمة');
      return;
    }
    if (!_knownPlace(dest)) {
      setState(() => _error = 'اختر منطقة الوصول من القائمة');
      return;
    }
    if (_time == null) {
      setState(() => _error = 'اختر التوقيت صباحي أو مسائي');
      return;
    }
    Navigator.of(context).pop(
      UnifiedSearchQuery(origin: origin, destination: dest, time: _time!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxH = MediaQuery.sizeOf(context).height * 0.86;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'بحث في الإعلانات',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: GoogleFonts.ibmPlexSansArabic(
                  color: c.riderAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlaceSuggestField(
                  label: 'الانطلاق',
                  hint: 'اختر منطقة الانطلاق',
                  controller: _origin,
                  options: _places,
                ),
                const SizedBox(height: 10),
                PlaceSuggestField(
                  label: 'الوصول',
                  hint: 'اختر منطقة الوصول',
                  controller: _destination,
                  options: _places,
                ),
                const SizedBox(height: 16),
                Text(
                  'التوقيت',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TimePick(
                        label: 'صباحي',
                        icon: Icons.wb_sunny_outlined,
                        selected: _time == TimePeriod.morning,
                        color: c.accent,
                        onTap: () =>
                            setState(() => _time = TimePeriod.morning),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TimePick(
                        label: 'مسائي',
                        icon: Icons.nights_stay_outlined,
                        selected: _time == TimePeriod.evening,
                        color: c.primary,
                        onTap: () =>
                            setState(() => _time = TimePeriod.evening),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('بحث'),
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _TimePick extends StatelessWidget {
  const _TimePick({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.16) : context.colors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : context.colors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? color : context.colors.text),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w600,
                  color: selected ? color : context.colors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
