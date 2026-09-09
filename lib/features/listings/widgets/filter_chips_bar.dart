import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/baghdad_places.dart';
import '../../../core/theme/app_colors.dart';

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
    required this.onAreaQueryChanged,
    required this.onDestinationQueryChanged,
    required this.onTimeSlotChanged,
    required this.onGenderChanged,
  });

  final List<String> areas;
  final List<String> destinations;
  final List<String> timeSlots;
  final String areaQuery;
  final String destinationQuery;
  final String? selectedTimeSlot;
  final String? selectedGender;
  final ValueChanged<String> onAreaQueryChanged;
  final ValueChanged<String> onDestinationQueryChanged;
  final ValueChanged<String?> onTimeSlotChanged;
  final ValueChanged<String?> onGenderChanged;

  static const genderOptions = <(String key, String label)>[
    ('female_only', 'بنات فقط'),
    ('male_only', 'ذكور فقط'),
    ('mixed', 'مختلط'),
  ];

  @override
  Widget build(BuildContext context) {
    final areaOptions = BaghdadPlaces.areasWith(areas);
    final destinationOptions = BaghdadPlaces.destinationsWith(destinations);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DropdownSearchField(
          label: 'المنطقة',
          value: areaQuery,
          hint: 'ابحث بكتابة اسم المنطقة',
          options: areaOptions,
          addMissingLabel: BaghdadPlaces.addMissingArea,
          onChanged: onAreaQueryChanged,
        ),
        const SizedBox(height: 12),
        _DropdownSearchField(
          label: 'الوجهة',
          value: destinationQuery,
          hint: 'ابحث بكتابة اسم الوجهة',
          options: destinationOptions,
          addMissingLabel: BaghdadPlaces.addMissingDestination,
          onChanged: onDestinationQueryChanged,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ChipRow(
                label: 'التوقيت',
                child: _scrollable(
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      selected: selectedTimeSlot == null,
                      onSelected: () => onTimeSlotChanged(null),
                    ),
                    ...timeSlots.map(
                      (t) => _FilterChip(
                        label: t,
                        selected: selectedTimeSlot == t,
                        onSelected: () => onTimeSlotChanged(t),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChipRow(
                label: 'الجنس',
                alignEnd: true,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _scrollable(
                    children: [
                      _FilterChip(
                        label: 'الكل',
                        selected: selectedGender == null,
                        onSelected: () => onGenderChanged(null),
                      ),
                      ...genderOptions.map(
                        (g) => _FilterChip(
                          label: g.$2,
                          selected: selectedGender == g.$1,
                          onSelected: () => onGenderChanged(g.$1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _scrollable({required List<Widget> children}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Search + dropdown in one control: type to match, or open list and pick.
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

  void _onTextChanged() {
    widget.onChanged(_controller.text);
  }

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
    final text = _controller.text;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Iterable<String> _buildOptions(TextEditingValue value) {
    // Preserve prioritized order from BaghdadPlaces.areasWith / destinationsWith.
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
      ...matched.where(
        (o) => o != _clearOption && o != widget.addMissingLabel,
      ),
      widget.addMissingLabel,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final textStyle = GoogleFonts.ibmPlexSansArabic(
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: c.text,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: c.text.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 6),
        RawAutocomplete<String>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (textEditingValue) => _buildOptions(textEditingValue),
          onSelected: (selection) {
            setState(() {
              _menuOpen = false;
              _showAll = false;
            });
            if (selection == _clearOption) {
              _controller.clear();
              widget.onChanged('');
              _focusNode.unfocus();
              return;
            }
            if (selection == widget.addMissingLabel) {
              // Keep whatever the user typed as a custom place name.
              widget.onChanged(_controller.text.trim());
              _focusNode.unfocus();
              return;
            }
            _controller.text = selection;
            _controller.selection =
                TextSelection.collapsed(offset: selection.length);
            widget.onChanged(selection);
            _focusNode.unfocus();
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textController,
              focusNode: focusNode,
              style: textStyle,
              onChanged: (_) {
                if (_showAll || _menuOpen) {
                  setState(() {
                    _showAll = false;
                    // Keep menu conceptually open while typing with focus.
                    _menuOpen = true;
                  });
                }
              },
              onTap: () {
                if (_menuOpen) {
                  _closeMenu();
                }
              },
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: c.text.withValues(alpha: 0.4),
                ),
                isDense: true,
                filled: true,
                fillColor: c.surface,
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: c.text.withValues(alpha: 0.45),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (textController.text.isNotEmpty)
                      IconButton(
                        tooltip: 'مسح',
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
                      tooltip: _menuOpen ? 'إغلاق القائمة' : 'عرض القائمة',
                      icon: Icon(
                        _menuOpen
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: c.text.withValues(alpha: 0.55),
                      ),
                      onPressed: _toggleDropdown,
                    ),
                  ],
                ),
                contentPadding:
                    const EdgeInsetsDirectional.fromSTEB(10, 10, 4, 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
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
              child: Material(
                elevation: 3,
                color: c.surface,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 240,
                    // Match field width approximately via media query.
                    minWidth: MediaQuery.sizeOf(context).width - 32,
                    maxWidth: MediaQuery.sizeOf(context).width - 32,
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: opts.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: c.border),
                    itemBuilder: (context, index) {
                      final option = opts[index];
                      final isClear = option == _clearOption;
                      final isAddMissing = option == widget.addMissingLabel;
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            12,
                            12,
                            12,
                            12,
                          ),
                          child: Text(
                            option,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontWeight: (isClear || isAddMissing)
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 14,
                              color: (isClear || isAddMissing)
                                  ? c.primary
                                  : c.text,
                            ),
                          ),
                        ),
                      );
                    },
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

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.label,
    required this.child,
    this.alignEnd = false,
  });

  final String label;
  final Widget child;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: c.text.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.primary.withValues(alpha: 0.12) : c.surface,
      child: InkWell(
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? c.primary : c.border,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
              color: selected ? c.primary : c.text,
            ),
          ),
        ),
      ),
    );
  }
}
