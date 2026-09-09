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
    ('female_only', 'بنات'),
    ('male_only', 'ذكور'),
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
          hint: 'منطقة',
          options: areaOptions,
          addMissingLabel: BaghdadPlaces.addMissingArea,
          onChanged: onAreaQueryChanged,
        ),
        const SizedBox(height: 6),
        _DropdownSearchField(
          label: 'الوجهة',
          value: destinationQuery,
          hint: 'وجهة',
          options: destinationOptions,
          addMissingLabel: BaghdadPlaces.addMissingDestination,
          onChanged: onDestinationQueryChanged,
        ),
        const SizedBox(height: 6),
        _SegmentRow(
          label: 'التوقيت',
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
        const SizedBox(height: 6),
        _SegmentRow(
          label: 'الجنس',
          children: [
            _Seg(
              label: 'الكل',
              selected: selectedGender == null,
              onTap: () => onGenderChanged(null),
            ),
            ...genderOptions.map(
              (g) => _Seg(
                label: g.$2,
                selected: selectedGender == g.$1,
                onTap: () => onGenderChanged(g.$1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({
    required this.label,
    required this.children,
  });

  final String label;
  final List<_Seg> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.border.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 22,
                    color: c.border.withValues(alpha: 0.7),
                  ),
                Expanded(child: children[i]),
              ],
            ],
          ),
        ),
      ],
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
      color: selected ? c.primary.withValues(alpha: 0.12) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 30,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
                color: selected ? c.primary : c.text.withValues(alpha: 0.8),
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
      ...matched.where(
        (o) => o != _clearOption && o != widget.addMissingLabel,
      ),
      widget.addMissingLabel,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(8);
    final textStyle = GoogleFonts.ibmPlexSansArabic(
      fontWeight: FontWeight.w400,
      fontSize: 12,
      color: c.text,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 10,
            color: c.text.withValues(alpha: 0.48),
          ),
        ),
        const SizedBox(height: 3),
        LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth;
            return RawAutocomplete<String>(
              textEditingController: _controller,
              focusNode: _focusNode,
              optionsBuilder: _buildOptions,
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
                        _menuOpen = true;
                      });
                    }
                  },
                  onTap: () {
                    if (_menuOpen) _closeMenu();
                  },
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      color: c.text.withValues(alpha: 0.35),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: c.surface.withValues(alpha: 0.92),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 15,
                      color: c.text.withValues(alpha: 0.38),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 30,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (textController.text.isNotEmpty)
                          IconButton(
                            tooltip: 'مسح',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 26,
                              minHeight: 26,
                            ),
                            icon: Icon(
                              Icons.close,
                              size: 14,
                              color: c.text.withValues(alpha: 0.38),
                            ),
                            onPressed: () {
                              textController.clear();
                              widget.onChanged('');
                              _closeMenu();
                            },
                          ),
                        IconButton(
                          tooltip: _menuOpen ? 'إغلاق' : 'القائمة',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: Icon(
                            _menuOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: c.text.withValues(alpha: 0.42),
                          ),
                          onPressed: _toggleDropdown,
                        ),
                      ],
                    ),
                    contentPadding:
                        const EdgeInsetsDirectional.fromSTEB(6, 6, 2, 6),
                    border: OutlineInputBorder(
                      borderRadius: radius,
                      borderSide:
                          BorderSide(color: c.border.withValues(alpha: 0.8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: radius,
                      borderSide:
                          BorderSide(color: c.border.withValues(alpha: 0.8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: radius,
                      borderSide: BorderSide(
                        color: c.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, optionsIterable) {
                final opts = optionsIterable.toList();
                if (opts.isEmpty) return const SizedBox.shrink();
                // Match field width exactly — avoids RTL horizontal overflow.
                return Align(
                  alignment: AlignmentDirectional.topStart,
                  child: SizedBox(
                    width: fieldWidth,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(8),
                      color: c.surface,
                      clipBehavior: Clip.antiAlias,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: opts.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: c.border.withValues(alpha: 0.65),
                          ),
                          itemBuilder: (context, index) {
                            final option = opts[index];
                            final isClear = option == _clearOption;
                            final isAdd = option == widget.addMissingLabel;
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Text(
                                  option,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontWeight: (isClear || isAdd)
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: 12,
                                    color: (isClear || isAdd)
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
