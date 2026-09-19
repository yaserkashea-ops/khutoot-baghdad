import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/admin_contact.dart';
import '../../../core/data/baghdad_places.dart';
import '../../../core/data/places_catalog.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/place_text_rules.dart';
import '../../support/contact_admin_sheet.dart';
import 'place_options_menu.dart';

/// Mobile-first search panel for transit listings.
class FilterChipsBar extends StatelessWidget {
  const FilterChipsBar({
    super.key,
    required this.timeSlots,
    required this.areaQuery,
    required this.destinationQuery,
    required this.selectedTimeSlot,
    required this.selectedGender,
    required this.departureQuery,
    required this.returnQuery,
    required this.onAreaQueryChanged,
    required this.onDestinationQueryChanged,
    required this.onTimeSlotChanged,
    required this.onGenderChanged,
    required this.onDepartureQueryChanged,
    required this.onReturnQueryChanged,
    this.extraAreaOptions = const [],
    this.extraDestinationOptions = const [],
  });

  final List<String> timeSlots;
  final String areaQuery;
  final String destinationQuery;
  final String? selectedTimeSlot;
  final String? selectedGender;
  final String departureQuery;
  final String returnQuery;
  final ValueChanged<String> onAreaQueryChanged;
  final ValueChanged<String> onDestinationQueryChanged;
  final ValueChanged<String?> onTimeSlotChanged;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String> onDepartureQueryChanged;
  final ValueChanged<String> onReturnQueryChanged;

  /// Sub-places (and listing mains) merged into the from/to search lists.
  final List<String> extraAreaOptions;
  final List<String> extraDestinationOptions;

  static const genderOptions = <(String key, String label)>[
    ('female_only', 'بنات'),
    ('male_only', 'ذكور'),
    ('mixed', 'مختلط'),
  ];

  String? get _genderLabel {
    if (selectedGender == null) return null;
    for (final g in genderOptions) {
      if (g.$1 == selectedGender) return g.$2;
    }
    return null;
  }

  bool get _hasExtraFilters =>
      selectedGender != null ||
      departureQuery.trim().isNotEmpty ||
      returnQuery.trim().isNotEmpty;

  Future<void> _openExtraFilters(BuildContext context) async {
    final c = context.colors;
    var gender = selectedGender;
    final depCtrl = TextEditingController(text: departureQuery);
    final retCtrl = TextEditingController(text: returnQuery);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SafeArea(
            child: StatefulBuilder(
              builder: (ctx, setModal) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'فلاتر إضافية',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'الجنس',
                        style: Theme.of(ctx).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChipChoice(
                            label: 'الكل',
                            selected: gender == null,
                            onTap: () => setModal(() => gender = null),
                          ),
                          ...genderOptions.map(
                            (g) => _FilterChipChoice(
                              label: g.$2,
                              selected: gender == g.$1,
                              onTap: () => setModal(() => gender = g.$1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'ساعات الانطلاق والعودة',
                        style: Theme.of(ctx).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اختياري — اتركه فارغاً إن لم ترد التصفية بالساعة',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: c.text.withValues(alpha: 0.55),
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: depCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ساعة الانطلاق (اختياري)',
                          hintText: '7:30',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: retCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ساعة العودة (اختياري)',
                          hintText: '2:00',
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: () {
                          onGenderChanged(gender);
                          onDepartureQueryChanged(depCtrl.text.trim());
                          onReturnQueryChanged(retCtrl.text.trim());
                          Navigator.pop(ctx);
                        },
                        child: const Text('تطبيق'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    depCtrl.dispose();
    retCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlacesCatalog.shared,
      builder: (context, _) {
        final c = context.colors;
        final theme = Theme.of(context);
        final areaOptions = BaghdadPlaces.prioritize({
          ...PlacesCatalog.shared.areas,
          ...extraAreaOptions,
        });
        final destinationOptions = BaghdadPlaces.prioritize({
          ...PlacesCatalog.shared.destinations,
          ...extraDestinationOptions,
        });
        final genderHint = _genderLabel;
        final extraActive = _hasExtraFilters;

        return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ابحث عن خطك',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'اختر نقطة الانطلاق والوجهة للعثور على الخط المناسب',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: c.text.withValues(alpha: 0.62),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        _DropdownSearchField(
          label: 'من أين؟',
          value: areaQuery,
          hint: 'اكتب او اختر من القائمة',
          options: areaOptions,
          addMissingLabel: BaghdadPlaces.addMissingArea,
          onChanged: onAreaQueryChanged,
        ),
        const SizedBox(height: 10),
        _DropdownSearchField(
          label: 'إلى أين؟',
          value: destinationQuery,
          hint: 'اكتب او اختر من القائمة',
          options: destinationOptions,
          addMissingLabel: BaghdadPlaces.addMissingDestination,
          onChanged: onDestinationQueryChanged,
        ),
        const SizedBox(height: 12),
        Text(
          'التوقيت',
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 12,
            color: c.text.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 6),
        _SegmentRow(
          children: [
            _Seg(
              label: 'الكل',
              selected: selectedTimeSlot == null,
              onTap: () => onTimeSlotChanged(null),
            ),
            ...timeSlots.map(
              (t) => _Seg(
                label: t,
                selected: selectedTimeSlot == t,
                onTap: () => onTimeSlotChanged(t),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => _openExtraFilters(context),
            icon: Icon(
              Icons.tune_rounded,
              size: 18,
              color: extraActive ? c.primary : c.text.withValues(alpha: 0.7),
            ),
            label: Text(
              genderHint == null
                  ? 'فلاتر إضافية'
                  : 'فلاتر إضافية · $genderHint',
            ),
            style: TextButton.styleFrom(
              foregroundColor:
                  extraActive ? c.primary : c.text.withValues(alpha: 0.85),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ),
      ],
    );
      },
    );
  }
}

class _FilterChipChoice extends StatelessWidget {
  const _FilterChipChoice({
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
      color: selected ? c.primary.withValues(alpha: 0.16) : c.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? c.primary : c.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? c.primary : c.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({required this.children});

  final List<_Seg> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 28,
                color: c.border,
              ),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
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
      color: selected ? c.primary.withValues(alpha: 0.14) : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
                color: selected ? c.primary : c.text.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownSearchField extends StatefulWidget {
  const _DropdownSearchField({
    required this.label,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
    required this.addMissingLabel,
    this.requiredField = false,
  });

  final String label;
  final String value;
  final String hint;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String addMissingLabel;
  final bool requiredField;

  @override
  State<_DropdownSearchField> createState() => _DropdownSearchFieldState();
}

class _DropdownSearchFieldState extends State<_DropdownSearchField> {
  static const _clearOption = 'الكل';

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final PlaceOptionsMenuController _menu;
  final Object _tapGroup = Object();
  double _fieldWidth = 280;
  bool _applyingSuggestion = false;
  /// Last value accepted into the filter (listed only, or empty).
  String _committed = '';
  String? _typedBeforeArm;

  @override
  void initState() {
    super.initState();
    _committed = widget.value.trim();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _menu = PlaceOptionsMenuController();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _DropdownSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _committed) {
      _committed = widget.value.trim();
    }
    if (widget.value != _controller.text && !_focusNode.hasFocus) {
      _controller.text = widget.value;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    _menu.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      if (_applyingSuggestion || _menu.isOpen) return;
      _finalizeListedOrReject();
    }
  }

  void _onTextChanged() {
    if (_applyingSuggestion) return;
    // Typing only drives suggestions — never pushes free text into the filter.
    if (mounted) setState(() {});
    _syncSuggestionsWhileTyping();
  }

  void _armSelect(String value) {
    _applyingSuggestion = true;
    _typedBeforeArm ??= _controller.text;
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _cancelArm() {
    final restore = _typedBeforeArm;
    _typedBeforeArm = null;
    if (restore != null) {
      _controller.value = TextEditingValue(
        text: restore,
        selection: TextSelection.collapsed(offset: restore.length),
      );
    }
    _applyingSuggestion = false;
  }

  void _syncSuggestionsWhileTyping() {
    if (_applyingSuggestion) return;
    if (!_focusNode.hasFocus) return;
    final q = _controller.text.trim();
    if (q.isEmpty) {
      if (_menu.isOpen) _closeMenu();
      return;
    }
    if (_menu.isOpen) {
      _menu.refilter();
      return;
    }
    _menu.open(
      context: context,
      width: _fieldWidth,
      optionsOf: () => widget.options,
      queryOf: () => _controller.text,
      leadingOption: widget.requiredField ? null : _clearOption,
      trailingOption: widget.addMissingLabel,
      onSelected: _onOptionSelected,
      onArmSelect: _armSelect,
      onCancelArm: _cancelArm,
      tapRegionGroupId: _tapGroup,
      keepFocus: true,
      showAll: false,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _closeMenu() {
    if (!_menu.isOpen) return;
    _menu.close();
    if (mounted) setState(() {});
  }

  void _toggleDropdown() {
    _menu.toggle(
      context: context,
      width: _fieldWidth,
      optionsOf: () => widget.options,
      queryOf: () => _controller.text,
      leadingOption: widget.requiredField ? null : _clearOption,
      trailingOption: widget.addMissingLabel,
      onSelected: _onOptionSelected,
      onArmSelect: _armSelect,
      onCancelArm: _cancelArm,
      tapRegionGroupId: _tapGroup,
      keepFocus: false,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _openAddPlaceRequest(String typed) async {
    final isDestination =
        widget.addMissingLabel == BaghdadPlaces.addMissingDestination;
    final placeHint = typed.isEmpty ? '……' : typed;
    final message = isDestination
        ? 'أرغب بإضافة الوجهة التالية إلى الفلتر: $placeHint'
        : 'أرغب بإضافة المنطقة التالية إلى الفلتر: $placeHint';
    if (!mounted) return;
    await showContactAdminSheet(
      context,
      initialKind: AdminContactKind.problem,
      initialMessage: message,
    );
  }

  void _setFieldText(String text) {
    _applyingSuggestion = true;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _applyingSuggestion = false;
  }

  void _applyListed(String listed) {
    _applyingSuggestion = true;
    _typedBeforeArm = null;
    _committed = listed;
    _controller.value = TextEditingValue(
      text: listed,
      selection: TextSelection.collapsed(offset: listed.length),
    );
    _closeMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.value = TextEditingValue(
        text: listed,
        selection: TextSelection.collapsed(offset: listed.length),
      );
      _applyingSuggestion = false;
      _focusNode.unfocus();
      widget.onChanged(listed);
      if (mounted) setState(() {});
    });
  }

  void _clearFilter() {
    if (widget.requiredField && _committed.isNotEmpty) {
      // Required main fields cannot be left empty once set — pick another place instead.
      _setFieldText(_committed);
      _closeMenu();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'لا يمكن ترك هذا الحقل فارغاً — اختر منطقة من القائمة',
              style: GoogleFonts.ibmPlexSansArabic(),
            ),
          ),
        );
      }
      return;
    }
    _committed = '';
    _setFieldText('');
    _closeMenu();
    _focusNode.unfocus();
    widget.onChanged('');
    if (mounted) setState(() {});
  }

  /// Accept only a catalog place; otherwise revert and offer admin contact.
  void _finalizeListedOrReject() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      if (widget.requiredField) {
        _setFieldText(_committed);
        _closeMenu();
        if (_committed.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                'هذا الحقل مطلوب',
                style: GoogleFonts.ibmPlexSansArabic(),
              ),
            ),
          );
        }
        return;
      }
      if (_committed.isNotEmpty) {
        _clearFilter();
      } else {
        _closeMenu();
      }
      return;
    }
    if (raw == widget.addMissingLabel) {
      _setFieldText(_committed);
      _closeMenu();
      return;
    }
    final listed = PlaceTextRules.resolveListed(raw, widget.options);
    if (listed != null) {
      if (listed != _committed || _controller.text != listed) {
        _applyListed(listed);
      } else {
        _closeMenu();
      }
      return;
    }
    // Free text / unknown place — do not filter with it.
    final typed = raw;
    _setFieldText(_committed);
    _closeMenu();
    if (mounted) setState(() {});
    unawaited(_openAddPlaceRequest(typed));
  }

  void _onOptionSelected(String selection) {
    if (selection == _clearOption) {
      if (widget.requiredField) return;
      _clearFilter();
      return;
    }
    if (selection == widget.addMissingLabel) {
      final typed = _controller.text.trim();
      _setFieldText(_committed);
      _closeMenu();
      _focusNode.unfocus();
      unawaited(_openAddPlaceRequest(typed));
      return;
    }
    final listed = PlaceTextRules.resolveListed(selection, widget.options);
    if (listed == null) return;
    _applyListed(listed);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(12);
    final textStyle = GoogleFonts.ibmPlexSansArabic(
      fontWeight: FontWeight.w400,
      fontSize: 15,
      color: c.text,
    );
    final menuOpen = _menu.isOpen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: c.text.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            _fieldWidth = constraints.maxWidth;
            return TapRegion(
              groupId: _tapGroup,
              onTapOutside: (_) {
                if (_menu.isOpen) {
                  _closeMenu();
                  _applyingSuggestion = false;
                  _typedBeforeArm = null;
                  _finalizeListedOrReject();
                }
              },
              child: KeyedSubtree(
                key: _menu.targetKey,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: textStyle,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _finalizeListedOrReject(),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: c.text.withValues(alpha: 0.38),
                    ),
                    isDense: false,
                    filled: true,
                    fillColor: c.surface,
                    prefixIcon: Icon(
                      Icons.place_outlined,
                      size: 20,
                      color: c.text.withValues(alpha: 0.45),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_controller.text.isNotEmpty && !widget.requiredField)
                          IconButton(
                            tooltip: 'مسح',
                            style: IconButton.styleFrom(
                              minimumSize: const Size(44, 44),
                            ),
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: c.text.withValues(alpha: 0.45),
                            ),
                            onPressed: _clearFilter,
                          ),
                        IconButton(
                          tooltip: menuOpen ? 'إغلاق' : 'القائمة',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(44, 44),
                          ),
                          icon: Icon(
                            menuOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: c.text.withValues(alpha: 0.5),
                          ),
                          onPressed: _toggleDropdown,
                        ),
                      ],
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: radius,
                      borderSide: BorderSide(color: c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: radius,
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: radius,
                      borderSide: BorderSide(color: c.primary, width: 1.4),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
