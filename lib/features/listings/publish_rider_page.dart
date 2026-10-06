import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/publisher_auth_controller.dart';
import '../../core/auth/publisher_limits.dart';
import '../../core/data/baghdad_places.dart';
import '../../core/data/places_catalog.dart';
import '../../core/listings/duplicate_listing.dart';
import '../../core/listings/publish_draft_store.dart';
import '../../core/models/listing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_digits.dart';
import '../../core/utils/place_text_rules.dart';
import '../../data/listings_repository.dart';
import '../../data/publisher_repository.dart';
import 'publisher_auth_sheet.dart';
import 'widgets/listing_card.dart';
import 'widgets/suggestible_text_field.dart';

class PublishRiderPage extends StatefulWidget {
  const PublishRiderPage({
    super.key,
    this.initial,
    this.asAdminDirect = false,
    this.allowFreeTextPlaces = false,
  });

  final Listing? initial;
  final bool asAdminDirect;
  final bool allowFreeTextPlaces;

  @override
  State<PublishRiderPage> createState() => _PublishRiderPageState();
}

class _PublishRiderPageState extends State<PublishRiderPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _area;
  late final TextEditingController _destination;
  late final TextEditingController _originSubInput;
  late final TextEditingController _destinationSubInput;
  late final TextEditingController _details;
  late final TextEditingController _seats;
  late final TextEditingController _departureTime;
  late final TextEditingController _returnTime;
  late final TextEditingController _phone;
  late final TextEditingController _telegram;
  List<String> _originSubs = [];
  List<String> _destinationSubs = [];
  GenderRequirement _gender = GenderRequirement.mixed;
  TimePeriod? _timePeriod;
  bool _saving = false;
  int _step = 0;

  bool get _isEditing => (widget.initial?.id ?? '').trim().isNotEmpty;

  List<String> get _knownAreas => PlacesCatalog.shared.areas;
  List<String> get _knownDestinations => PlacesCatalog.shared.destinations;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _area = TextEditingController(text: initial?.area ?? '');
    _destination = TextEditingController(text: initial?.destination ?? '');
    _originSubInput = TextEditingController();
    _destinationSubInput = TextEditingController();
    _details = TextEditingController(text: initial?.routeDetails ?? '');
    _seats = TextEditingController(
      text: initial?.seatsCount?.toString() ?? '',
    );
    _departureTime = TextEditingController(text: initial?.departureTime ?? '');
    _returnTime = TextEditingController(text: initial?.returnTime ?? '');
    _phone = TextEditingController(
      text: PhoneDigits.iraqLocal(initial?.contactPhone) ??
          (initial?.contactPhone ?? ''),
    );
    _telegram = TextEditingController(text: initial?.contactTelegram ?? '');
    _originSubs = List<String>.from(initial?.originSubs ?? const []);
    _destinationSubs = List<String>.from(initial?.destinationSubs ?? const []);
    _gender = initial?.genderRequirement ?? GenderRequirement.mixed;
    _timePeriod = initial?.timePeriod;
    PlacesCatalog.shared.addListener(_onPlaces);
    unawaited(PlacesCatalog.shared.refresh());
    if (!_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_restoreDraft());
      });
    }
    if (!widget.asAdminDirect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_ensureAccount());
      });
    }
  }

  void _onPlaces() {
    if (mounted) setState(() {});
  }

  Future<void> _restoreDraft() async {
    final data = await PublishDraftStore.load(PublishDraftStore.riderKey);
    if (!mounted || data == null || data.isEmpty) return;
    final resume = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسودة غير مكتملة'),
        content: const Text('لديك منشور غير مكتمل. هل تريد المتابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تجاهل'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (resume != true) {
      await PublishDraftStore.clear(PublishDraftStore.riderKey);
      return;
    }
    setState(() {
      _area.text = data['area'] ?? _area.text;
      _destination.text = data['dest'] ?? _destination.text;
      _seats.text = data['seats'] ?? _seats.text;
      _phone.text = data['phone'] ?? _phone.text;
      _telegram.text = data['tg'] ?? _telegram.text;
      _details.text = data['details'] ?? _details.text;
    });
  }

  void _nextStep() {
    if (_step == 0) {
      if (_area.text.trim().isEmpty || _destination.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل منطقة الانطلاق والوجهة أولاً')),
        );
        return;
      }
    } else if (_step == 1) {
      if (_timePeriod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اختر التوقيت')),
        );
        return;
      }
    }
    unawaited(
      PublishDraftStore.save(PublishDraftStore.riderKey, {
        'area': _area.text,
        'dest': _destination.text,
        'seats': _seats.text,
        'phone': _phone.text,
        'tg': _telegram.text,
        'details': _details.text,
      }),
    );
    setState(() => _step++);
  }

  Future<void> _ensureAccount() async {
    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!mounted) return;
    if (auth.isLoggedIn) return;
    final ok = await showPublisherAuthSheet(
      context,
      title: 'إنشاء حساب مطلوب لإضافة طلب راكب',
      requiredToContinue: true,
    );
    if (!mounted) return;
    if (!ok || !PublisherAuthController.shared.isLoggedIn) {
      if (!mounted) return;
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    PlacesCatalog.shared.removeListener(_onPlaces);
    _area.dispose();
    _destination.dispose();
    _originSubInput.dispose();
    _destinationSubInput.dispose();
    _details.dispose();
    _seats.dispose();
    _departureTime.dispose();
    _returnTime.dispose();
    _phone.dispose();
    _telegram.dispose();
    super.dispose();
  }

  SnackBar _toast(String msg) => SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg, style: GoogleFonts.ibmPlexSansArabic()),
      );

  TextStyle _sectionLabel(MasaratColors c) => GoogleFonts.ibmPlexSansArabic(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        color: c.text.withValues(alpha: 0.5),
      );

  void _addToList(
    TextEditingController input,
    List<String> list,
    void Function(List<String>) assign,
  ) {
    final value = input.text.trim();
    if (value.isEmpty) return;
    final err = PlaceTextRules.validate(
      value,
      maxLength: PlaceTextRules.subMaxLength,
    );
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(_toast(err));
      return;
    }
    if (list.contains(value)) {
      input.clear();
      return;
    }
    setState(() {
      assign([...list, value]);
      input.clear();
    });
  }

  void _flushPendingSubs() {
    final originPending = _originSubInput.text.trim();
    if (originPending.isNotEmpty &&
        PlaceTextRules.isAllowed(
          originPending,
          maxLength: PlaceTextRules.subMaxLength,
        ) &&
        !_originSubs.contains(originPending)) {
      _originSubs = [..._originSubs, originPending];
      _originSubInput.clear();
    }
    final destPending = _destinationSubInput.text.trim();
    if (destPending.isNotEmpty &&
        PlaceTextRules.isAllowed(
          destPending,
          maxLength: PlaceTextRules.subMaxLength,
        ) &&
        !_destinationSubs.contains(destPending)) {
      _destinationSubs = [..._destinationSubs, destPending];
      _destinationSubInput.clear();
    }
  }

  String? _normalizeTelegram(String raw) {
    var v = raw.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('@')) v = v.substring(1);
    if (v.contains('t.me/')) {
      v = v.split('t.me/').last.split(RegExp(r'[/?#]')).first;
    }
    if (v.isEmpty) return null;
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]{2,31}$').hasMatch(v)) {
      throw FormatException('يوزر تلغرام غير صالح (مثال: username)');
    }
    return '@$v';
  }

  Future<bool> _allowDespiteDuplicate({
    required String area,
    required String dest,
    required String? phone,
  }) async {
    if (_isEditing) return true;
    final similar = DuplicateListing.similar(
      mine: await PublisherRepository.shared.myListings(),
      type: ListingType.rider,
      area: area,
      destination: dest,
      time: _timePeriod,
      phone: phone,
      excludeId: widget.initial?.id,
    );
    if (similar == null || !mounted) return true;
    final skip = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('منشور مشابه'),
        content: Text(
          'لديك طلب مشابه نشط. هل تريد تعديله بدل إنشاء طلب جديد؟\n'
          '${similar.area} ← ${similar.destination}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('متابعة للنشر'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
    return skip == true;
  }

  Future<void> _submit() async {
    if (_saving) return;
    final listedOnly = !widget.allowFreeTextPlaces;
    final area = PlaceTextRules.canonicalizeMain(
      _area.text,
      _knownAreas,
      listedOnly: listedOnly,
    );
    final dest = PlaceTextRules.canonicalizeMain(
      _destination.text,
      _knownDestinations,
      listedOnly: listedOnly,
    );
    if (area == null || dest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _toast('اختر المنطقة والوجهة من القائمة'),
      );
      return;
    }
    if (_timePeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _toast('اختر التوقيت: صباحي أو مسائي'),
      );
      return;
    }
    final seats = int.tryParse(_seats.text.trim());
    if (seats == null || seats < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        _toast('أدخل كم مقعداً تحتاج'),
      );
      return;
    }
    final localPhone = PhoneDigits.iraqLocal(_phone.text);
    String? telegram;
    try {
      telegram = _normalizeTelegram(_telegram.text);
    } on FormatException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(_toast(e.message));
      return;
    }
    _flushPendingSubs();
    if (localPhone == null && telegram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _toast('أدخل واتساب أو تلغرام'),
      );
      return;
    }
    if (_phone.text.trim().isNotEmpty && localPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _toast('رقم عراقي غير صالح (مثال: 07XXXXXXXXX)'),
      );
      return;
    }
    final details = _details.text.trim();
    if (details.length > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        _toast('التفاصيل حتى 200 حرف'),
      );
      return;
    }
    if (!await _allowDespiteDuplicate(
      area: area,
      dest: dest,
      phone: localPhone,
    )) {
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.asAdminDirect) {
        final draft = Listing(
          id: widget.initial?.id ?? '',
          type: ListingType.rider,
          area: area,
          destination: dest,
          originSubs: List<String>.from(_originSubs),
          destinationSubs: List<String>.from(_destinationSubs),
          timePeriod: _timePeriod!,
          departureTime: _departureTime.text.trim().isEmpty
              ? null
              : _departureTime.text.trim(),
          returnTime: _returnTime.text.trim().isEmpty
              ? null
              : _returnTime.text.trim(),
          genderRequirement: _gender,
          seatsCount: seats,
          vehicleType: details.isEmpty ? null : details,
          contactPhone: localPhone,
          contactTelegram: telegram,
          status: widget.asAdminDirect
              ? (_isEditing
                  ? (widget.initial?.status ?? ListingStatus.published)
                  : ListingStatus.published)
              : ListingStatus.pendingReview,
        );
        final repo = ListingsRepository.shared;
        final created = _isEditing
            ? await repo.update(draft)
            : await repo.insert(draft);
        if (!mounted) return;
        unawaited(PublishDraftStore.clear(PublishDraftStore.riderKey));
        Navigator.of(context).pop(created);
        return;
      }

      final auth = PublisherAuthController.shared;
      if (!auth.isLoaded) await auth.load();
      if (!auth.isLoggedIn) {
        if (!mounted) return;
        setState(() => _saving = false);
        await _ensureAccount();
        return;
      }
      final draft = Listing(
        id: widget.initial?.id ?? '',
        type: ListingType.rider,
        area: area,
        destination: dest,
        originSubs: List<String>.from(_originSubs),
        destinationSubs: List<String>.from(_destinationSubs),
        timePeriod: _timePeriod!,
        departureTime: _departureTime.text.trim().isEmpty
            ? null
            : _departureTime.text.trim(),
        returnTime:
            _returnTime.text.trim().isEmpty ? null : _returnTime.text.trim(),
        genderRequirement: _gender,
        seatsCount: seats,
        vehicleType: details.isEmpty ? null : details,
        contactPhone: localPhone,
        contactTelegram: telegram,
        status: ListingStatus.pendingReview,
        ownerAccountId: auth.accountId,
      );
      final repo = ListingsRepository.shared;
      Listing created;
      if (_isEditing) {
        created = await PublisherRepository.shared.updateListing(draft);
      } else {
        created = await repo.submitRequest(draft);
        try {
          created = await PublisherRepository.shared.claimListing(created.id);
        } on PostgrestException catch (e) {
          if (e.message.toUpperCase().contains('LISTING_LIMIT')) {
            try {
              await repo.deleteById(created.id);
            } catch (_) {}
            if (mounted) {
              await showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('وصلت للحد الأقصى'),
                  content: Text(PublisherLimits.limitReachedMessage),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('حسناً'),
                    ),
                  ],
                ),
              );
            }
            return;
          }
        } catch (_) {}
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            _isEditing ? 'تم حفظ الطلب' : 'أُرسل الطلب للمراجعة',
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'رقم الطلب: ${created.referenceCode ?? created.id}\n'
            '${created.area} ← ${created.destination}',
            style: GoogleFonts.ibmPlexSansArabic(height: 1.45),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      unawaited(PublishDraftStore.clear(PublishDraftStore.riderKey));
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _toast('تعذر إرسال الطلب. تحقق من الاتصال وأعد المحاولة.'),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const mainMax = PlaceTextRules.listedMaxLength;
    final listedOnly = !widget.allowFreeTextPlaces;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'تعديل طلب راكب'
              : (widget.asAdminDirect ? 'نشر طلب راكب' : 'أضف طلب راكب'),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 14, 28),
              children: [
                if (_step == 0) ...[
                SuggestibleTextField(
                  fieldKey: const Key('rider_area'),
                  label: 'من أين تريد الركوب؟',
                  controller: _area,
                  options: _knownAreas,
                  addMissingLabel: BaghdadPlaces.addMissingArea,
                  hint: 'مثال: الدورة',
                  listedOnly: listedOnly,
                  maxLength: mainMax,
                  inputFormatters: const [
                    PlaceTextInputFormatter(
                      maxLength: mainMax,
                      singleOnly: true,
                      maxWords: PlaceTextRules.maxCustomWords,
                      lettersWordsOnly: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SuggestibleTextField(
                  fieldKey: const Key('rider_dest'),
                  label: 'إلى أين تريد الذهاب؟',
                  controller: _destination,
                  options: _knownDestinations,
                  addMissingLabel: BaghdadPlaces.addMissingDestination,
                  hint: 'مثال: الجادرية',
                  listedOnly: listedOnly,
                  maxLength: mainMax,
                  inputFormatters: const [
                    PlaceTextInputFormatter(
                      maxLength: mainMax,
                      singleOnly: true,
                      maxWords: PlaceTextRules.maxCustomWords,
                      lettersWordsOnly: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RiderSubBlock(
                  title: 'الشارع او الحي الذي تسكن فيه',
                  hint: 'نقطة الانطلاق',
                  field: SuggestibleTextField(
                    fieldKey: const Key('rider_origin_sub'),
                    label: '',
                    controller: _originSubInput,
                    hint: 'مثال: شارع ابو طيارة',
                    options: _knownAreas,
                    addMissingLabel: BaghdadPlaces.addMissingArea,
                    maxLength: PlaceTextRules.subMaxLength,
                    subordinate: true,
                    onCommitted: (_) => _addToList(
                      _originSubInput,
                      _originSubs,
                      (next) => _originSubs = next,
                    ),
                    inputFormatters: const [
                      PlaceTextInputFormatter(
                        maxLength: PlaceTextRules.subMaxLength,
                      ),
                    ],
                  ),
                  chips: _originSubs.isEmpty
                      ? null
                      : _RiderSubChips(
                          items: _originSubs,
                          onRemove: (v) => setState(
                            () => _originSubs =
                                _originSubs.where((e) => e != v).toList(),
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                _RiderSubBlock(
                  title: 'الشارع او الحي او الدائرة التي تريد الوصول اليها',
                  hint: 'نقطة الوصول',
                  field: SuggestibleTextField(
                    fieldKey: const Key('rider_dest_sub'),
                    label: '',
                    controller: _destinationSubInput,
                    hint: 'مثال: جامعة بغداد',
                    options: _knownDestinations,
                    addMissingLabel: BaghdadPlaces.addMissingDestination,
                    maxLength: PlaceTextRules.subMaxLength,
                    subordinate: true,
                    onCommitted: (_) => _addToList(
                      _destinationSubInput,
                      _destinationSubs,
                      (next) => _destinationSubs = next,
                    ),
                    inputFormatters: const [
                      PlaceTextInputFormatter(
                        maxLength: PlaceTextRules.subMaxLength,
                      ),
                    ],
                  ),
                  chips: _destinationSubs.isEmpty
                      ? null
                      : _RiderSubChips(
                          items: _destinationSubs,
                          onRemove: (v) => setState(
                            () => _destinationSubs =
                                _destinationSubs.where((e) => e != v).toList(),
                          ),
                        ),
                ),
                ],
                if (_step == 1) ...[
                const SizedBox(height: 12),
                _RiderField(
                  fieldKey: const Key('rider_seats'),
                  label: 'كم مقعداً تحتاج؟',
                  controller: _seats,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTheme.manrope(fontSize: 14, color: c.text),
                ),
                const SizedBox(height: 10),
                Text('متى تريد الذهاب؟', style: _sectionLabel(c)),
                const SizedBox(height: 2),
                Text(
                  'صباحي أو مسائي — حسب موعدك أنت كراكب',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    color: c.text.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _RiderChoiceChip(
                        label: 'صباحي',
                        selected: _timePeriod == TimePeriod.morning,
                        onTap: () => setState(
                          () => _timePeriod = TimePeriod.morning,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _RiderChoiceChip(
                        label: 'مسائي',
                        selected: _timePeriod == TimePeriod.evening,
                        onTap: () => setState(
                          () => _timePeriod = TimePeriod.evening,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    leading: Icon(Icons.hail_rounded, color: c.opportunity, size: 22),
                    title: Text('تفضيلات طلبك', style: _sectionLabel(c)),
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text('الجنس', style: _sectionLabel(c)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (final option in GenderRequirement.values) ...[
                            if (option != GenderRequirement.values.first)
                              const SizedBox(width: 6),
                            Expanded(
                              child: _RiderChoiceChip(
                                label: switch (option) {
                                  GenderRequirement.femaleOnly => 'اناث',
                                  GenderRequirement.maleOnly => 'ذكور',
                                  GenderRequirement.mixed => 'الكل',
                                },
                                selected: _gender == option,
                                onTap: () => setState(() => _gender = option),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _RiderField(
                              fieldKey: const Key('rider_departure'),
                              label: 'ساعة ذهابك (اختياري)',
                              controller: _departureTime,
                              hint: '7:30',
                              style: AppTheme.manrope(fontSize: 14, color: c.text),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RiderField(
                              fieldKey: const Key('rider_return'),
                              label: 'ساعة عودتك (اختياري)',
                              controller: _returnTime,
                              hint: '2:00',
                              style: AppTheme.manrope(fontSize: 14, color: c.text),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ],
                if (_step == 2) ...[
                const SizedBox(height: 12),
                _RiderField(
                  fieldKey: const Key('rider_details'),
                  label: 'تفاصيل اخرى (اختياري)',
                  controller: _details,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 200,
                ),
                const SizedBox(height: 14),
                _RiderField(
                  fieldKey: const Key('rider_phone'),
                  label: 'واتساب (ليتواصل معك السائقون)',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  hint: '07XXXXXXXXX',
                  style: AppTheme.manrope(fontSize: 14, color: c.text),
                ),
                const SizedBox(height: 10),
                _RiderField(
                  fieldKey: const Key('rider_telegram'),
                  label: 'تلغرام',
                  controller: _telegram,
                  hint: 'username',
                ),
                const SizedBox(height: 14),
                Text('معاينة المنشور', style: _sectionLabel(c)),
                const SizedBox(height: 8),
                ListingCard(
                  listing: Listing(
                    id: 'preview',
                    type: ListingType.rider,
                    area: _area.text.trim().isEmpty ? '—' : _area.text.trim(),
                    destination: _destination.text.trim().isEmpty
                        ? '—'
                        : _destination.text.trim(),
                    timePeriod: _timePeriod ?? TimePeriod.morning,
                    genderRequirement: _gender,
                    originSubs: List<String>.from(_originSubs),
                    destinationSubs: List<String>.from(_destinationSubs),
                    departureTime: _departureTime.text.trim().isEmpty
                        ? null
                        : _departureTime.text.trim(),
                    returnTime: _returnTime.text.trim().isEmpty
                        ? null
                        : _returnTime.text.trim(),
                    seatsCount: int.tryParse(_seats.text.trim()),
                    vehicleType: _details.text.trim().isEmpty
                        ? null
                        : _details.text.trim(),
                    contactPhone: _phone.text.trim().isEmpty
                        ? null
                        : _phone.text.trim(),
                    contactTelegram: _telegram.text.trim().isEmpty
                        ? null
                        : _telegram.text.trim(),
                    status: ListingStatus.published,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    bumpedAt: DateTime.now(),
                  ),
                  onContact: () {},
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.opportunity,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isEditing
                              ? 'حفظ'
                              : (widget.asAdminDirect
                                  ? 'نشر'
                                  : 'ارسال المنشور للمراجعة'),
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                ],
                const SizedBox(height: 16),
                if (_step > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('رجوع'),
                  ),
                if (_step < 2) ...[
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _nextStep,
                    style: FilledButton.styleFrom(
                      backgroundColor: c.opportunity,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('التالي'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RiderField extends StatelessWidget {
  const _RiderField({
    this.fieldKey,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.style,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
  });

  final Key? fieldKey;
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;
  final int? minLines;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(8);
    final base = style ??
        GoogleFonts.ibmPlexSansArabic(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        );
    final textStyle = base.copyWith(color: style?.color ?? c.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 10,
            color: c.text.withValues(alpha: 0.48),
          ),
        ),
        const SizedBox(height: 3),
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
          style: textStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w400,
              fontSize: 11,
              color: c.text.withValues(alpha: 0.35),
            ),
            isDense: true,
            filled: true,
            fillColor: c.surface.withValues(alpha: 0.92),
            contentPadding: const EdgeInsetsDirectional.fromSTEB(8, 6, 8, 6),
            alignLabelWithHint: minLines != null,
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.border.withValues(alpha: 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.border.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.opportunity.withValues(alpha: 0.8)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.riderAccent),
            ),
          ),
        ),
      ],
    );
  }
}

class _RiderChoiceChip extends StatelessWidget {
  const _RiderChoiceChip({
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
    return Material(
      color: selected
          ? c.opportunity.withValues(alpha: 0.12)
          : c.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? c.opportunity.withValues(alpha: 0.7)
                  : c.border.withValues(alpha: 0.85),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
              color: selected ? c.opportunity : c.text.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

class _RiderSubBlock extends StatelessWidget {
  const _RiderSubBlock({
    required this.title,
    required this.hint,
    required this.field,
    this.chips,
  });

  final String title;
  final String hint;
  final Widget field;
  final Widget? chips;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 10),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.text.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(8),
        border: BorderDirectional(
          start: BorderSide(
            color: c.opportunity.withValues(alpha: 0.28),
            width: 2.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: c.text.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 3),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Text(
                hint,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  height: 1.35,
                  color: c.text.withValues(alpha: 0.62),
                ),
              ),
              CustomPaint(
                size: const Size(12, 15),
                painter: _MapPinPainter(c.opportunity),
              ),
            ],
          ),
          const SizedBox(height: 6),
          field,
          if (chips != null) ...[
            const SizedBox(height: 4),
            chips!,
          ],
        ],
      ),
    );
  }
}

class _MapPinPainter extends CustomPainter {
  const _MapPinPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pin = Path()
      ..moveTo(w / 2, h)
      ..cubicTo(w * 0.08, h * 0.62, 0, h * 0.48, 0, h * 0.36)
      ..arcToPoint(
        Offset(w, h * 0.36),
        radius: Radius.circular(w / 2),
        clockwise: true,
      )
      ..cubicTo(w, h * 0.48, w * 0.92, h * 0.62, w / 2, h)
      ..close();
    canvas.drawPath(
      pin,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(w / 2, h * 0.34),
      w * 0.2,
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _MapPinPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _RiderSubChips extends StatelessWidget {
  const _RiderSubChips({
    required this.items,
    required this.onRemove,
  });

  final List<String> items;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final item in items)
            InputChip(
              label: Text(
                item,
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
              ),
              onDeleted: () => onRemove(item),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              deleteIconColor: c.text.withValues(alpha: 0.5),
              side: BorderSide(color: c.border.withValues(alpha: 0.85)),
              backgroundColor: c.surface.withValues(alpha: 0.92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }
}
