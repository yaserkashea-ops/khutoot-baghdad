import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/baghdad_places.dart';
import '../../core/models/listing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/listings_repository.dart';
import 'widgets/suggestible_text_field.dart';

/// Publish / edit form. One listing per phone → duplicate opens edit mode.
class PublishListingPage extends StatefulWidget {
  const PublishListingPage({
    super.key,
    required this.repository,
    this.initial,
    this.draftOnly = false,
  });

  final ListingsRepository repository;
  final Listing? initial;

  /// When true, save returns the [Listing] via `Navigator.pop` without writing to the repo.
  final bool draftOnly;

  @override
  State<PublishListingPage> createState() => _PublishListingPageState();
}

class _PublishListingPageState extends State<PublishListingPage> {
  final _formKey = GlobalKey<FormState>();

  late ListingType _type;
  late GenderRequirement _gender;
  TimePeriod? _timePeriod;
  late final TextEditingController _area;
  late final TextEditingController _destination;
  late final TextEditingController _originSubInput;
  late final TextEditingController _destinationSubInput;
  late final TextEditingController _departureTime;
  late final TextEditingController _returnTime;
  late final TextEditingController _vehicle;
  late final TextEditingController _seats;
  late final TextEditingController _phone;
  late final TextEditingController _telegram;

  String? _editingId;
  bool _saving = false;
  List<String> _originSubs = [];
  List<String> _destinationSubs = [];
  List<String> _knownAreas = BaghdadPlaces.areas;
  List<String> _knownDestinations = BaghdadPlaces.destinations;

  bool get _isEditing => _editingId != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.type ?? ListingType.driver;
    _gender = initial?.genderRequirement ?? GenderRequirement.mixed;
    _timePeriod = initial?.timePeriod;
    _editingId = widget.draftOnly ? null : initial?.id;
    _originSubs = List<String>.from(initial?.originSubs ?? const []);
    _destinationSubs = List<String>.from(initial?.destinationSubs ?? const []);
    _area = TextEditingController(text: initial?.area ?? '');
    _destination = TextEditingController(text: initial?.destination ?? '');
    _originSubInput = TextEditingController();
    _destinationSubInput = TextEditingController();
    _departureTime = TextEditingController(text: initial?.departureTime ?? '');
    _returnTime = TextEditingController(text: initial?.returnTime ?? '');
    _vehicle = TextEditingController(text: initial?.vehicleType ?? '');
    _seats = TextEditingController(
      text: initial?.seatsCount?.toString() ?? '',
    );
    _phone = TextEditingController(text: initial?.contactPhone ?? '');
    _telegram = TextEditingController(text: initial?.contactTelegram ?? '');
    _loadPlaceOptions();
  }

  Future<void> _loadPlaceOptions() async {
    final items = await widget.repository.fetchAll();
    if (!mounted) return;
    setState(() {
      _knownAreas = BaghdadPlaces.areasWith([
        ...items.map((e) => e.area),
        ...items.expand((e) => e.originSubs),
      ]);
      _knownDestinations = BaghdadPlaces.destinationsWith([
        ...items.map((e) => e.destination),
        ...items.expand((e) => e.destinationSubs),
      ]);
    });
  }

  @override
  void dispose() {
    _area.dispose();
    _destination.dispose();
    _originSubInput.dispose();
    _destinationSubInput.dispose();
    _departureTime.dispose();
    _returnTime.dispose();
    _vehicle.dispose();
    _seats.dispose();
    _phone.dispose();
    _telegram.dispose();
    super.dispose();
  }

  void _fillFrom(Listing listing) {
    setState(() {
      _editingId = listing.id;
      _type = listing.type;
      _gender = listing.genderRequirement;
      _timePeriod = listing.timePeriod;
      _originSubs = List<String>.from(listing.originSubs);
      _destinationSubs = List<String>.from(listing.destinationSubs);
      _area.text = listing.area;
      _destination.text = listing.destination;
      _departureTime.text = listing.departureTime ?? '';
      _returnTime.text = listing.returnTime ?? '';
      _vehicle.text = listing.vehicleType ?? '';
      _seats.text = listing.seatsCount?.toString() ?? '';
      _phone.text = listing.contactPhone ?? '';
      _telegram.text = listing.contactTelegram ?? '';
    });
  }

  void _addToList(TextEditingController input, List<String> list, void Function(List<String>) assign) {
    final value = input.text.trim();
    if (value.isEmpty) return;
    if (list.contains(value)) {
      input.clear();
      return;
    }
    setState(() {
      assign([...list, value]);
      input.clear();
    });
  }

  void _removeFromList(String value, List<String> list, void Function(List<String>) assign) {
    setState(() => assign(list.where((e) => e != value).toList()));
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'مطلوب';
    return null;
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final phone = _phone.text.trim();
    final telegram = _telegram.text.trim();
    if (phone.isEmpty && telegram.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _toast('أدخل رقم هاتف أو رابط/يوزر تلغرام على الأقل'),
      );
      return;
    }

    if (_timePeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _toast('اختر التوقيت: صباحي أو مسائي'),
      );
      return;
    }

    if (_type == ListingType.driver) {
      if (_vehicle.text.trim().isEmpty || _seats.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          _toast('نوع السيارة وعدد المقاعد مطلوبان للسائق'),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      // One listing per phone: if another record exists, switch to edit mode.
      if (!widget.draftOnly && phone.isNotEmpty && !_isEditing) {
        final existing = await widget.repository.findByPhone(phone);
        if (existing != null) {
          if (!mounted) return;
          _fillFrom(existing);
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            _toast(
              'لديك إعلان سابق بنفس الرقم — عدّل البيانات ثم احفظ',
            ),
          );
          return;
        }
      }

      if (!widget.draftOnly && phone.isNotEmpty && _isEditing) {
        final existing = await widget.repository.findByPhone(phone);
        if (existing != null && existing.id != _editingId) {
          if (!mounted) return;
          setState(() => _saving = false);
          _fillFrom(existing);
          ScaffoldMessenger.of(context).showSnackBar(
            _toast(
              'هذا الرقم مرتبط بإعلان آخر — تم فتحه للتعديل',
            ),
          );
          return;
        }
      }

      final seats = int.tryParse(_seats.text.trim());
      final draft = Listing(
        id: _editingId ?? '',
        type: _type,
        area: _area.text.trim(),
        destination: _destination.text.trim(),
        originSubs: List<String>.from(_originSubs),
        destinationSubs: List<String>.from(_destinationSubs),
        timePeriod: _timePeriod!,
        departureTime: _departureTime.text.trim().isEmpty
            ? null
            : _departureTime.text.trim(),
        returnTime:
            _returnTime.text.trim().isEmpty ? null : _returnTime.text.trim(),
        genderRequirement: _gender,
        vehicleType:
            _type == ListingType.driver ? _vehicle.text.trim() : null,
        seatsCount: _type == ListingType.driver ? seats : null,
        contactPhone: phone.isEmpty ? null : phone,
        contactTelegram: telegram.isEmpty ? null : telegram,
      );

      if (widget.draftOnly) {
        if (!mounted) return;
        Navigator.of(context).pop(draft);
        return;
      }

      if (_isEditing) {
        await widget.repository.update(draft);
      } else {
        await widget.repository.insert(draft);
      }

      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  SnackBar _toast(String message) {
    final c = context.colors;
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.primary,
      content: Text(
        message,
        style: GoogleFonts.ibmPlexSansArabic(
          fontWeight: FontWeight.w400,
          color: c.onPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.draftOnly
              ? 'تعديل المسودة'
              : (_isEditing ? 'تعديل الإعلان' : 'نشر إعلان'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 14, 28),
              children: [
            Text(
              'نوع الإعلان',
              style: _sectionLabel(c),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _TypeToggle(
                    label: 'سائق يعرض خطاً',
                    selected: _type == ListingType.driver,
                    accent: c.accent,
                    onTap: () => setState(() => _type = ListingType.driver),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TypeToggle(
                    label: 'راكب يطلب خطاً',
                    selected: _type == ListingType.rider,
                    accent: c.riderAccent,
                    onTap: () => setState(() => _type = ListingType.rider),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SuggestibleTextField(
              fieldKey: const Key('field_area'),
              label: 'المنطقة',
              controller: _area,
              validator: _required,
              options: _knownAreas,
              addMissingLabel: BaghdadPlaces.addMissingArea,
            ),
            const SizedBox(height: 10),
            SuggestibleTextField(
              fieldKey: const Key('field_destination'),
              label: 'الوجهة',
              controller: _destination,
              hint: 'مثال: اسم الجامعة أو جهة العمل',
              validator: _required,
              options: _knownDestinations,
              addMissingLabel: BaghdadPlaces.addMissingDestination,
            ),
            const SizedBox(height: 12),
            Text('نقاط فرعية داخل المنطقة (من)', style: _sectionLabel(c)),
            const SizedBox(height: 2),
            Text(
              'اختياري — أكثر من نقطة انطلاق داخل المنطقة',
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: c.text.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            SuggestibleTextField(
              fieldKey: const Key('field_origin_sub'),
              label: 'أضف نقطة انطلاق فرعية',
              controller: _originSubInput,
              hint: 'مثال: شارع الرواد أو حي دراغ',
              options: _knownAreas,
              addMissingLabel: BaghdadPlaces.addMissingArea,
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => _addToList(
                  _originSubInput,
                  _originSubs,
                  (next) => _originSubs = next,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('إضافة نقطة من'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: c.primary,
                  textStyle: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (_originSubs.isNotEmpty)
              _SubChips(
                items: _originSubs,
                onRemove: (v) => _removeFromList(
                  v,
                  _originSubs,
                  (next) => _originSubs = next,
                ),
              ),
            const SizedBox(height: 10),
            Text('نقاط فرعية داخل الوجهة (إلى)', style: _sectionLabel(c)),
            const SizedBox(height: 2),
            Text(
              'اختياري — أكثر من نقطة وصول داخل الوجهة',
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: c.text.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            SuggestibleTextField(
              fieldKey: const Key('field_destination_sub'),
              label: 'أضف نقطة وصول فرعية',
              controller: _destinationSubInput,
              hint: 'مثال: جامعة بغداد أو مول الجادرية',
              options: _knownDestinations,
              addMissingLabel: BaghdadPlaces.addMissingDestination,
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => _addToList(
                  _destinationSubInput,
                  _destinationSubs,
                  (next) => _destinationSubs = next,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('إضافة نقطة إلى'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: c.primary,
                  textStyle: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (_destinationSubs.isNotEmpty)
              _SubChips(
                items: _destinationSubs,
                onRemove: (v) => _removeFromList(
                  v,
                  _destinationSubs,
                  (next) => _destinationSubs = next,
                ),
              ),
            if (_originSubs.isNotEmpty || _destinationSubs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${_originSubs.isEmpty ? '—' : _originSubs.join('، ')}  ←  ${_destinationSubs.isEmpty ? '—' : _destinationSubs.join('، ')}',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  height: 1.4,
                  color: c.primary,
                ),
              ),
            ],
            if (_type == ListingType.driver) ...[
              const SizedBox(height: 10),
              _Field(
                fieldKey: const Key('field_vehicle'),
                label: 'نوع السيارة',
                controller: _vehicle,
                validator: _required,
              ),
              const SizedBox(height: 10),
              _Field(
                fieldKey: const Key('field_seats'),
                label: 'عدد المقاعد',
                controller: _seats,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTheme.manrope(fontSize: 14),
                validator: _required,
              ),
            ],
            const SizedBox(height: 10),
            Text('التوقيت', style: _sectionLabel(c)),
            const SizedBox(height: 2),
            Text(
              'صباحي أو مسائي — إلزامي',
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
                  child: _ChoiceChip(
                    label: 'صباحي',
                    selected: _timePeriod == TimePeriod.morning,
                    onTap: () =>
                        setState(() => _timePeriod = TimePeriod.morning),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ChoiceChip(
                    label: 'مسائي',
                    selected: _timePeriod == TimePeriod.evening,
                    onTap: () =>
                        setState(() => _timePeriod = TimePeriod.evening),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('ساعات الانطلاق والعودة', style: _sectionLabel(c)),
            const SizedBox(height: 2),
            Text(
              'اختياري — اذكر الساعة إن رغبت',
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
                  child: _Field(
                    fieldKey: const Key('field_departure'),
                    label: 'ساعة الانطلاق',
                    controller: _departureTime,
                    hint: '7:30',
                    style: AppTheme.manrope(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Field(
                    fieldKey: const Key('field_return'),
                    label: 'ساعة العودة',
                    controller: _returnTime,
                    hint: '2:00',
                    style: AppTheme.manrope(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('الجنس المطلوب', style: _sectionLabel(c)),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final option in GenderRequirement.values) ...[
                  if (option != GenderRequirement.values.first)
                    const SizedBox(width: 6),
                  Expanded(
                    child: _ChoiceChip(
                      label: switch (option) {
                        GenderRequirement.femaleOnly => 'بنات',
                        GenderRequirement.maleOnly => 'ذكور',
                        GenderRequirement.mixed => 'مختلط',
                      },
                      selected: _gender == option,
                      onTap: () => setState(() => _gender = option),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Text('وسيلة التواصل', style: _sectionLabel(c)),
            const SizedBox(height: 2),
            Text(
              'هاتف و/أو تلغرام — واحد منهما على الأقل',
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: c.text.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            _Field(
              fieldKey: const Key('field_phone'),
              label: 'رقم الهاتف',
              controller: _phone,
              keyboardType: TextInputType.phone,
              style: AppTheme.manrope(fontSize: 14),
            ),
            const SizedBox(height: 10),
            _Field(
              fieldKey: const Key('field_telegram'),
              label: 'تلغرام (رابط أو يوزر)',
              controller: _telegram,
              hint: '@user أو https://t.me/...',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.onPrimary,
                        ),
                      )
                    : Text(_isEditing ? 'حفظ التعديل' : 'نشر'),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _sectionLabel(MasaratColors c) {
    return GoogleFonts.ibmPlexSansArabic(
      fontWeight: FontWeight.w600,
      fontSize: 11,
      color: c.text.withValues(alpha: 0.5),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? accent.withValues(alpha: 0.1) : c.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.85) : c.border.withValues(alpha: 0.85),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
              height: 1.25,
              color: selected ? accent : c.text.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
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
          ? c.primary.withValues(alpha: 0.12)
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
                  ? c.primary.withValues(alpha: 0.7)
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
              color: selected ? c.primary : c.text.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    this.fieldKey,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.style,
  });

  final Key? fieldKey;
  final String label;
  final TextEditingController controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(8);
    final textStyle = style ??
        GoogleFonts.ibmPlexSansArabic(
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: c.text,
        );

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
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
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
              borderSide: BorderSide(color: c.primary.withValues(alpha: 0.8)),
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

class _SubChips extends StatelessWidget {
  const _SubChips({
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
