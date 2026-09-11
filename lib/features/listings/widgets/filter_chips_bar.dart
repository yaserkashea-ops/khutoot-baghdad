import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/baghdad_places.dart';
import '../../../core/theme/app_colors.dart';

/// Mobile-first search panel for transit listings.
class FilterChipsBar extends StatelessWidget {
  const FilterChipsBar({
    super.key,
    required this.areas,
    required this.destinations,
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
  });

  final List<String> areas;
  final List<String> destinations;
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
    final c = context.colors;
    final theme = Theme.of(context);
    final areaOptions = BaghdadPlaces.areasWith(areas);
    final destinationOptions = BaghdadPlaces.destinationsWith(destinations);
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
          hint: 'اكتب أي منطقة أو اختر من القائمة',
          options: areaOptions,
          addMissingLabel: BaghdadPlaces.addMissingArea,
          onChanged: onAreaQueryChanged,
        ),
        const SizedBox(height: 10),
        _DropdownSearchField(
          label: 'إلى أين؟',
          value: destinationQuery,
          hint: 'اكتب أي وجهة أو اختر من القائمة',
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
  });

  final String label;
  final String value;
  final String hint;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String addMissingLabel;

  @override
  State<_DropdownSearchField> createState() => _DropdownSearchFieldState();
}

class _DropdownSearchFieldState extends State<_DropdownSearchField> {
  static const _clearOption = 'الكل';

  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _showAll = false;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _DropdownSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() => widget.onChanged(_controller.text);

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _menuOpen) {
      setState(() {
        _menuOpen = false;
        _showAll = false;
      });
    }
  }

  void _closeMenu() {
    setState(() {
      _menuOpen = false;
      _showAll = false;
    });
    _focusNode.unfocus();
  }

  void _toggleDropdown() {
    if (_menuOpen) {
      _closeMenu();
      return;
    }
    setState(() {
      _menuOpen = true;
      _showAll = true;
    });
    _focusNode.requestFocus();
  }

  Iterable<String> _buildOptions(TextEditingValue value) {
    final seen = <String>{};
    final pool = <String>[];
    for (final o in widget.options) {
      if (seen.add(o)) pool.add(o);
    }
    final q = value.text.trim();
    final matched = (_showAll || q.isEmpty)
        ? pool
        : pool.where((o) => BaghdadPlaces.matchesQuery(o, q)).toList();

    return [
      _clearOption,
      ...matched.where((o) => o != _clearOption),
    ];
  }

  void _commitTyped([String? raw]) {
    final text = (raw ?? _controller.text).trim();
    setState(() {
      _menuOpen = false;
      _showAll = false;
    });
    if (_controller.text != text) {
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
    }
    widget.onChanged(text);
    _focusNode.unfocus();
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
            final fieldWidth = constraints.maxWidth;
            return RawAutocomplete<String>(
              textEditingController: _controller,
              focusNode: _focusNode,
              optionsBuilder: _buildOptions,
              onSelected: (selection) {
                if (selection == _clearOption) {
                  setState(() {
                    _menuOpen = false;
                    _showAll = false;
                  });
                  _controller.clear();
                  widget.onChanged('');
                  _focusNode.unfocus();
                  return;
                }
                _commitTyped(selection);
              },
              fieldViewBuilder:
                  (context, textController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textController,
                  focusNode: focusNode,
                  style: textStyle,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _commitTyped(),
                  onChanged: (_) {
                    setState(() {
                      _showAll = false;
                      _menuOpen = true;
                    });
                  },
                  onTap: () {
                    if (!_menuOpen) {
                      setState(() {
                        _menuOpen = true;
                        _showAll = textController.text.trim().isEmpty;
                      });
                    }
                  },
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
                        if (textController.text.isNotEmpty)
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
                            onPressed: () {
                              textController.clear();
                              widget.onChanged('');
                              _closeMenu();
                            },
                          ),
                        IconButton(
                          tooltip: _menuOpen ? 'إغلاق' : 'القائمة',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(44, 44),
                          ),
                          icon: Icon(
                            _menuOpen
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
                );
              },
              optionsViewBuilder: (context, onSelected, optionsIterable) {
                final opts = optionsIterable.toList();
                if (opts.isEmpty) return const SizedBox.shrink();
                return Align(
                  alignment: AlignmentDirectional.topStart,
                  child: SizedBox(
                    width: fieldWidth,
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(12),
                      color: c.surface,
                      clipBehavior: Clip.antiAlias,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: opts.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: c.border.withValues(alpha: 0.8),
                          ),
                          itemBuilder: (context, index) {
                            final option = opts[index];
                            final isClear = option == _clearOption;
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Text(
                                  option,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontWeight: isClear
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: 14,
                                    color: isClear ? c.primary : c.text,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
