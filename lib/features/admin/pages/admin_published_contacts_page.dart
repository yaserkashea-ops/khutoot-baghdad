import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/contact_keys.dart';
import '../../../core/utils/listing_contact.dart';
import '../../../core/utils/phone_digits.dart';
import '../../../data/listings_repository.dart';

enum _TypeFilter { all, driver, rider }

class _ContactEntry {
  const _ContactEntry({
    required this.key,
    required this.display,
    required this.isPhone,
    required this.driverCount,
    required this.riderCount,
  });

  final String key;
  final String display;
  final bool isPhone;
  final int driverCount;
  final int riderCount;

  int get total => driverCount + riderCount;

  _ContactEntry merge(_ContactEntry other) {
    return _ContactEntry(
      key: key,
      display: display.length >= other.display.length ? display : other.display,
      isPhone: isPhone,
      driverCount: driverCount + other.driverCount,
      riderCount: riderCount + other.riderCount,
    );
  }
}

class AdminPublishedContactsPage extends StatefulWidget {
  const AdminPublishedContactsPage({super.key});

  @override
  State<AdminPublishedContactsPage> createState() =>
      _AdminPublishedContactsPageState();
}

class _AdminPublishedContactsPageState
    extends State<AdminPublishedContactsPage> {
  bool _loading = true;
  String? _error;
  List<_ContactEntry> _phones = const [];
  List<_ContactEntry> _telegrams = const [];
  final _TypeFilter _typeFilter = _TypeFilter.all;

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
      final listings = await ListingsRepository.shared.fetchAll();
      final phones = <String, _ContactEntry>{};
      final telegrams = <String, _ContactEntry>{};

      void addPhone(Listing l) {
        final key = ContactKeys.phoneKey(l.contactPhone);
        if (key == null) return;
        final display = _formatPhone(key);
        final next = _ContactEntry(
          key: key,
          display: display,
          isPhone: true,
          driverCount: l.type == ListingType.driver ? 1 : 0,
          riderCount: l.type == ListingType.rider ? 1 : 0,
        );
        phones[key] = phones.containsKey(key) ? phones[key]!.merge(next) : next;
      }

      void addTelegram(Listing l) {
        final key = ContactKeys.telegramKey(l.contactTelegram);
        if (key == null) return;
        final display = '@$key';
        final next = _ContactEntry(
          key: key,
          display: display,
          isPhone: false,
          driverCount: l.type == ListingType.driver ? 1 : 0,
          riderCount: l.type == ListingType.rider ? 1 : 0,
        );
        telegrams[key] =
            telegrams.containsKey(key) ? telegrams[key]!.merge(next) : next;
      }

      for (final l in listings) {
        addPhone(l);
        addTelegram(l);
      }

      final phoneList = phones.values.toList()
        ..sort((a, b) => b.total.compareTo(a.total));
      final tgList = telegrams.values.toList()
        ..sort((a, b) => b.total.compareTo(a.total));

      if (!mounted) return;
      setState(() {
        _phones = phoneList;
        _telegrams = tgList;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  String _formatPhone(String digits964) {
    final n = PhoneDigits.normalize(digits964);
    if (n.startsWith('964') && n.length >= 13) {
      return '0${n.substring(3)}';
    }
    return n;
  }

  List<_ContactEntry> _filter(List<_ContactEntry> source) {
    return switch (_typeFilter) {
      _TypeFilter.all => source,
      _TypeFilter.driver =>
        source.where((e) => e.driverCount > 0).toList(),
      _TypeFilter.rider => source.where((e) => e.riderCount > 0).toList(),
    };
  }

  int _countFor(_ContactEntry e) => switch (_typeFilter) {
        _TypeFilter.all => e.total,
        _TypeFilter.driver => e.driverCount,
        _TypeFilter.rider => e.riderCount,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.primary));
    }

    final phones = _filter(_phones);
    final telegrams = _filter(_telegrams);
    final phoneUnique = phones.length;
    final tgUnique = telegrams.length;

    return RefreshIndicator(
      color: c.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 12),
          ],
          Text(
            'إحصائية جهات المنشورات',
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'الأرقام واليوزرات المستخدمة في إعلانات التطبيق المنشورة.',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12.5,
              color: c.text.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SoftStat(
                label: 'أرقام فريدة',
                value: '${_phones.length}',
                accent: c.primary,
              ),
              _SoftStat(
                label: 'يوزرات فريدة',
                value: '${_telegrams.length}',
                accent: c.accent,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'الأرقام',
            count: phoneUnique,
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 8),
          if (phones.isEmpty)
            _EmptySoft(text: 'لا توجد أرقام في هذا الفلتر')
          else
            ...phones.map(
              (e) => _SoftContactTile(
                entry: e,
                count: _countFor(e),
                typeFilter: _typeFilter,
                onCopy: () => _copy(e.display),
                onOpen: () async {
                  final url = ListingContact.whatsappUrl(e.key);
                  if (url != null) await ListingContact.openUrl(url);
                },
              ),
            ),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'يوزرات تلغرام',
            count: tgUnique,
            icon: Icons.send_outlined,
          ),
          const SizedBox(height: 8),
          if (telegrams.isEmpty)
            _EmptySoft(text: 'لا توجد يوزرات في هذا الفلتر')
          else
            ...telegrams.map(
              (e) => _SoftContactTile(
                entry: e,
                count: _countFor(e),
                typeFilter: _typeFilter,
                onCopy: () => _copy(e.display),
                onOpen: () async {
                  await ListingContact.openTelegramChat(e.display);
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('تم نسخ $value'),
      ),
    );
  }
}

class _SoftStat extends StatelessWidget {
  const _SoftStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12,
              color: c.text.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
  });

  final String title;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 18, color: c.primary.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($count)',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            color: c.text.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _EmptySoft extends StatelessWidget {
  const _EmptySoft({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        text,
        style: GoogleFonts.ibmPlexSansArabic(
          color: c.text.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _SoftContactTile extends StatelessWidget {
  const _SoftContactTile({
    required this.entry,
    required this.count,
    required this.typeFilter,
    required this.onCopy,
    required this.onOpen,
  });

  final _ContactEntry entry;
  final int count;
  final _TypeFilter typeFilter;
  final VoidCallback onCopy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final typeBits = <String>['$count ظهور'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.display,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  typeBits.join(' · '),
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: c.text.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'نسخ',
            onPressed: onCopy,
            icon: Icon(
              Icons.copy_outlined,
              size: 18,
              color: c.text.withValues(alpha: 0.55),
            ),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: entry.isPhone ? 'واتساب' : 'تلغرام',
            onPressed: onOpen,
            icon: Icon(
              entry.isPhone ? Icons.chat_outlined : Icons.send_outlined,
              size: 18,
              color: c.primary,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
