import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_hosts.dart';
import '../../../core/models/outreach_lead.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/listing_contact.dart';
import '../../../data/admin_repository.dart';

enum _InviteChannel { whatsapp, telegram }

class AdminInvitesPage extends StatefulWidget {
  const AdminInvitesPage({super.key});

  @override
  State<AdminInvitesPage> createState() => _AdminInvitesPageState();
}

class _AdminInvitesPageState extends State<AdminInvitesPage> {
  static const _prefsMessageKey = 'outreach_invite_message';
  static const _prefsChannelKey = 'outreach_invite_channel';
  static const _defaultMessage =
      'مرحباً، تطبيق خطوط بغداد يجمع إعلانات الخطوط في مكان واحد بدل اللصق اليومي في الكروبات.\n'
      'جرّبه من هنا: ${AppHosts.publicUrl}';

  final _paste = TextEditingController();
  final _message = TextEditingController();
  final _batchCount = TextEditingController(text: '10');

  List<OutreachLead> _leads = const [];
  final Set<String> _selected = {};
  OutreachLeadStatus? _filter = OutreachLeadStatus.fresh;
  _InviteChannel _channel = _InviteChannel.whatsapp;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _message.text = _defaultMessage;
    _loadPrefs();
    _load();
  }

  @override
  void dispose() {
    _paste.dispose();
    _message.dispose();
    _batchCount.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsMessageKey);
    final ch = prefs.getString(_prefsChannelKey);
    if (!mounted) return;
    setState(() {
      if (saved != null && saved.trim().isNotEmpty) {
        _message.text = saved;
      }
      if (ch == 'telegram') {
        _channel = _InviteChannel.telegram;
      } else if (ch == 'whatsapp') {
        _channel = _InviteChannel.whatsapp;
      }
    });
  }

  Future<void> _saveMessage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsMessageKey, _message.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('تم حفظ نص الدعوة'),
      ),
    );
  }

  Future<void> _setChannel(_InviteChannel channel) async {
    setState(() => _channel = channel);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsChannelKey,
      channel == _InviteChannel.telegram ? 'telegram' : 'whatsapp',
    );
  }

  bool _matchesChannel(OutreachLead lead) {
    return switch (_channel) {
      _InviteChannel.whatsapp => lead.hasPhone,
      _InviteChannel.telegram => lead.hasTelegram,
    };
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final leads = await AdminRepository.shared.fetchOutreachLeads();
      if (!mounted) return;
      final alive = leads.map((e) => e.id).toSet();
      setState(() {
        _leads = leads;
        _selected.removeWhere((id) => !alive.contains(id));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e'.replaceFirst('Bad state: ', '');
      });
    }
  }

  List<OutreachLead> get _visible {
    Iterable<OutreachLead> list = _leads;
    if (_filter != null) {
      list = list.where((l) => l.status == _filter);
    }
    list = list.where(_matchesChannel);
    return list.toList();
  }

  Future<void> _extractAndAdd() async {
    final raw = _paste.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('الصق نص الرسالة أو الأرقام/اليوزرات أولاً'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await AdminRepository.shared.importOutreachText(raw);
      await _load();
      if (!mounted) return;
      _paste.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            result.extracted == 0
                ? 'لم يُعثر على رقم أو يوزر'
                : 'استخراج ${result.extracted}: أُضيف ${result.added}'
                    '${result.merged > 0 ? ' · دُمج ${result.merged}' : ''}'
                    '${result.skippedDuplicate > 0 ? ' · مكرر ${result.skippedDuplicate}' : ''}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$e'.replaceFirst('Bad state: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _selectBatch() {
    final n = int.tryParse(_batchCount.text.trim()) ?? 0;
    if (n <= 0) return;
    final pool = _visible
        .where((l) => l.status == OutreachLeadStatus.fresh)
        .where(_matchesChannel)
        .take(n)
        .map((l) => l.id);
    setState(() {
      _selected
        ..clear()
        ..addAll(pool);
    });
  }

  void _toggleSelect(String id, bool? value) {
    setState(() {
      if (value == true) {
        _selected.add(id);
      } else {
        _selected.remove(id);
      }
    });
  }

  Future<void> _inviteLead(OutreachLead lead) async {
    switch (_channel) {
      case _InviteChannel.whatsapp:
        await _openWhatsApp(lead);
      case _InviteChannel.telegram:
        await _openTelegram(lead);
    }
  }

  Future<bool> _openWhatsApp(OutreachLead lead) async {
    final msg = _message.text.trim();
    final url = ListingContact.whatsappUrl(lead.phone, message: msg);
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('لا يوجد رقم واتساب لهذه الجهة'),
        ),
      );
      return false;
    }
    await ListingContact.openUrl(url);
    return true;
  }

  Future<bool> _openTelegram(OutreachLead lead) async {
    final handle = lead.telegramDisplay;
    if (handle.isEmpty || ListingContact.telegramUrl(handle) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('لا يوجد يوزر تلغرام لهذه الجهة'),
        ),
      );
      return false;
    }

    final msg = _message.text.trim();
    if (msg.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: msg));
    }

    final opened = await ListingContact.openTelegramChat(handle);
    if (!opened) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('تعذر فتح محادثة تلغرام'),
          ),
        );
      }
      return false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          content: Text(
            msg.isEmpty
                ? 'فُتحت محادثة $handle'
                : 'فُتحت محادثة $handle — الصق نص الدعوة (Ctrl+V) ثم أرسل',
          ),
        ),
      );
    }
    return true;
  }

  Future<void> _inviteSelected() async {
    if (_selected.isEmpty) return;
    final leads = _visible
        .where((l) => _selected.contains(l.id))
        .where(_matchesChannel)
        .toList();
    if (leads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _channel == _InviteChannel.whatsapp
                ? 'المحددون بلا رقم واتساب'
                : 'المحددون بلا يوزر تلغرام',
          ),
        ),
      );
      return;
    }

    await _inviteLead(leads.first);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          leads.length == 1
              ? 'تم فتح $_channelLabel'
              : 'فُتحت دعوة واحدة عبر $_channelLabel. بعد الإرسال علّم «تمّت» ثم افتح التالي.',
        ),
      ),
    );
  }

  String get _channelLabel =>
      _channel == _InviteChannel.whatsapp ? 'واتساب' : 'تلغرام';

  Future<void> _markSelectedInvited() async {
    if (_selected.isEmpty) return;
    setState(() => _busy = true);
    try {
      final n = await AdminRepository.shared.markOutreachInvited(_selected);
      await _load();
      if (!mounted) return;
      setState(() => _selected.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('تم تعليم $n كـ«دُعي»'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(OutreachLead lead, OutreachLeadStatus status) async {
    await AdminRepository.shared.updateOutreachLead(
      lead.id,
      status: status,
      touchContacted: status == OutreachLeadStatus.invited,
    );
    await _load();
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المحدد؟'),
        content: Text('سيُحذف ${_selected.length} من قائمة الدعوات.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await AdminRepository.shared.deleteOutreachLeads(_selected);
      await _load();
      if (!mounted) return;
      setState(() => _selected.clear());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.primary));
    }

    final freshCount =
        _leads.where((l) => l.status == OutreachLeadStatus.fresh).length;
    final invitedCount =
        _leads.where((l) => l.status == OutreachLeadStatus.invited).length;
    final channelReady = _leads.where(_matchesChannel).length;

    return RefreshIndicator(
      color: c.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (_error != null) ...[
            Material(
              color: c.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: c.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'قناة الإرسال',
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اختر واتساب أو تلغرام — لا يُفتح الاثنان معاً.',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12.5,
              color: c.text.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<_InviteChannel>(
            segments: const [
              ButtonSegment(
                value: _InviteChannel.whatsapp,
                label: Text('واتساب'),
                icon: Icon(Icons.chat, size: 18),
              ),
              ButtonSegment(
                value: _InviteChannel.telegram,
                label: Text('تلغرام'),
                icon: Icon(Icons.send_outlined, size: 18),
              ),
            ],
            selected: {_channel},
            onSelectionChanged: (s) {
              if (s.isEmpty) return;
              _setChannel(s.first);
            },
          ),
          const SizedBox(height: 14),
          Text(
            'نص الدعوة',
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _message,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _channel == _InviteChannel.whatsapp
                  ? 'يُفتح مع واتساب تلقائياً'
                  : 'يُنسخ للحافظة وتُفتح محادثة اليوزر — الصقه ثم أرسل',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _busy ? null : _saveMessage,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('حفظ النص'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لصق من الكروب',
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'الصق رسالة أو عدة رسائل أو أرقاماً ويوزرات — تُستخرج تلقائياً إلى القائمة.',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12.5,
              color: c.text.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _paste,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText:
                  'مثال: رقم الهاتف 0770…\nتلغرام @user\nأو عدة إعلانات مفصولة بـ ---',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _extractAndAdd,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add),
            label: const Text('استخراج وإضافة للقائمة'),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'قائمة $_channelLabel',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                'جاهز $channelReady · جديد $freshCount · دُعي $invitedCount',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12,
                  color: c.text.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _FilterChip(
                label: 'جديد',
                selected: _filter == OutreachLeadStatus.fresh,
                onTap: () => setState(() => _filter = OutreachLeadStatus.fresh),
              ),
              _FilterChip(
                label: 'دُعي',
                selected: _filter == OutreachLeadStatus.invited,
                onTap: () =>
                    setState(() => _filter = OutreachLeadStatus.invited),
              ),
              _FilterChip(
                label: 'تخطي',
                selected: _filter == OutreachLeadStatus.skipped,
                onTap: () =>
                    setState(() => _filter = OutreachLeadStatus.skipped),
              ),
              _FilterChip(
                label: 'الكل',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Material(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: _batchCount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'عدد',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _busy ? null : _selectBatch,
                    child: const Text('تحديد دفعة'),
                  ),
                  OutlinedButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => setState(() => _selected.clear()),
                    child: Text('إلغاء التحديد (${_selected.length})'),
                  ),
                  FilledButton(
                    onPressed:
                        _busy || _selected.isEmpty ? null : _inviteSelected,
                    child: Text('ادعُ عبر $_channelLabel'),
                  ),
                  FilledButton.tonal(
                    onPressed: _busy || _selected.isEmpty
                        ? null
                        : _markSelectedInvited,
                    child: const Text('تمّت الدعوة للمحدد'),
                  ),
                  TextButton(
                    onPressed:
                        _busy || _selected.isEmpty ? null : _deleteSelected,
                    child: Text(
                      'حذف',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  _leads.isEmpty
                      ? 'القائمة فارغة — الصق رسائل الكروب أعلاه'
                      : _channel == _InviteChannel.whatsapp
                          ? 'لا يوجد أرقام واتساب في هذا الفلتر'
                          : 'لا يوجد يوزرات تلغرام في هذا الفلتر',
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: c.text.withValues(alpha: 0.55),
                  ),
                ),
              ),
            )
          else
            ..._visible.map(
              (lead) => _LeadTile(
                lead: lead,
                channel: _channel,
                selected: _selected.contains(lead.id),
                onSelected: (v) => _toggleSelect(lead.id, v),
                onInvite: () => _inviteLead(lead),
                onMarkInvited: () =>
                    _setStatus(lead, OutreachLeadStatus.invited),
                onSkip: () => _setStatus(lead, OutreachLeadStatus.skipped),
                onReset: () => _setStatus(lead, OutreachLeadStatus.fresh),
                onDelete: () async {
                  await AdminRepository.shared.deleteOutreachLead(lead.id);
                  await _load();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: c.primary.withValues(alpha: 0.16),
      checkmarkColor: c.primary,
      labelStyle: GoogleFonts.ibmPlexSansArabic(
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
    );
  }
}

class _LeadTile extends StatelessWidget {
  const _LeadTile({
    required this.lead,
    required this.channel,
    required this.selected,
    required this.onSelected,
    required this.onInvite,
    required this.onMarkInvited,
    required this.onSkip,
    required this.onReset,
    required this.onDelete,
  });

  final OutreachLead lead;
  final _InviteChannel channel;
  final bool selected;
  final ValueChanged<bool?> onSelected;
  final VoidCallback onInvite;
  final VoidCallback onMarkInvited;
  final VoidCallback onSkip;
  final VoidCallback onReset;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final viaWhatsApp = channel == _InviteChannel.whatsapp;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: selected ? c.primary.withValues(alpha: 0.06) : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? c.primary.withValues(alpha: 0.35)
              : c.border.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(value: selected, onChanged: onSelected),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            viaWhatsApp
                                ? lead.phoneDisplay
                                : lead.telegramDisplay,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          _StatusBadge(status: lead.status),
                        ],
                      ),
                      if ((lead.sourceSnippet ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          lead.sourceSnippet!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12,
                            color: c.text.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onInvite,
                  icon: Icon(
                    viaWhatsApp ? Icons.chat : Icons.send_outlined,
                    size: 16,
                  ),
                  label: Text(viaWhatsApp ? 'واتساب' : 'تلغرام'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                TextButton(
                  onPressed: onMarkInvited,
                  child: const Text('تمّت الدعوة'),
                ),
                TextButton(
                  onPressed: onSkip,
                  child: const Text('تخطي'),
                ),
                if (lead.status != OutreachLeadStatus.fresh)
                  TextButton(
                    onPressed: onReset,
                    child: const Text('إعادة لجديد'),
                  ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OutreachLeadStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (status) {
      OutreachLeadStatus.fresh => c.accent,
      OutreachLeadStatus.invited => c.primary,
      OutreachLeadStatus.skipped => c.text.withValues(alpha: 0.55),
      OutreachLeadStatus.optOut => Colors.red.shade600,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
