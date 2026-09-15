import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/baghdad_places.dart';
import '../../../core/theme/app_colors.dart';

/// Text field with suggestion list. Free typing is always allowed.
/// The options menu opens/closes only via the arrow — never on tap/type alone.
class SuggestibleTextField extends StatefulWidget {
  const SuggestibleTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.options,
    this.fieldKey,
    this.hint,
    this.validator,
    this.addMissingLabel,
    this.helperText,
    this.maxLength,
    this.inputFormatters,
    this.onCommitted,
    this.subordinate = false,
  });

  final Key? fieldKey;
  final String label;
  final TextEditingController controller;
  final List<String> options;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final String? addMissingLabel;
  final String? helperText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  /// Fires after Done / suggestion pick / blur when the field has text.
  final ValueChanged<String>? onCommitted;
  /// Visually secondary (smaller, quieter) vs main place fields.
  final bool subordinate;

  @override
  State<SuggestibleTextField> createState() => _SuggestibleTextFieldState();
}

class _SuggestibleTextFieldState extends State<SuggestibleTextField> {
  late final FocusNode _focusNode;
  bool _menuOpen = false;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      if (_menuOpen) {
        setState(() {
          _menuOpen = false;
          _showAll = false;
        });
      }
      _emitCommitted(unfocus: false);
    }
  }

  void _closeMenu({bool unfocus = true}) {
    setState(() {
      _menuOpen = false;
      _showAll = false;
    });
    if (unfocus) _focusNode.unfocus();
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

  Iterable<String> _optionsFor(TextEditingValue value) {
    if (!_menuOpen) return const Iterable<String>.empty();

    final q = value.text.trim();
    final seen = <String>{};
    final pool = <String>[];
    for (final o in widget.options) {
      if (seen.add(o)) pool.add(o);
    }
    if (_showAll || q.isEmpty) return pool;
    return pool.where((o) => BaghdadPlaces.matchesQuery(o, q));
  }

  void _emitCommitted({required bool unfocus}) {
    final text = widget.controller.text.trim();
    if (widget.controller.text != text) {
      widget.controller.text = text;
      widget.controller.selection =
          TextSelection.collapsed(offset: text.length);
    }
    if (text.isNotEmpty) {
      widget.onCommitted?.call(text);
    }
    if (unfocus) _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sub = widget.subordinate;
    final radius = BorderRadius.circular(sub ? 6 : 8);
    final textStyle = GoogleFonts.ibmPlexSansArabic(
      fontWeight: FontWeight.w400,
      fontSize: sub ? 11 : 12,
      color: c.text.withValues(alpha: sub ? 0.88 : 1),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label.isNotEmpty)
          Text(
            widget.label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w600,
              fontSize: sub ? 9 : 10,
              color: c.text.withValues(alpha: sub ? 0.38 : 0.48),
            ),
          ),
        if (widget.helperText != null) ...[
          if (widget.label.isNotEmpty) const SizedBox(height: 2),
          Text(
            widget.helperText!,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w400,
              fontSize: 10,
              color: c.text.withValues(alpha: 0.42),
              height: 1.35,
            ),
          ),
        ],
        if (widget.label.isNotEmpty || widget.helperText != null)
          const SizedBox(height: 3),
        LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth;
            return RawAutocomplete<String>(
              textEditingController: widget.controller,
              focusNode: _focusNode,
              optionsBuilder: _optionsFor,
              onSelected: (value) {
                setState(() {
                  _menuOpen = false;
                  _showAll = false;
                });
                widget.controller.text = value;
                widget.controller.selection =
                    TextSelection.collapsed(offset: value.length);
                _emitCommitted(unfocus: true);
              },
              fieldViewBuilder:
                  (context, textController, focusNode, onFieldSubmitted) {
                return TextFormField(
                  key: widget.fieldKey,
                  controller: textController,
                  focusNode: focusNode,
                  validator: widget.validator,
                  style: textStyle,
                  maxLength: widget.maxLength,
                  inputFormatters: widget.inputFormatters,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    setState(() {
                      _menuOpen = false;
                      _showAll = false;
                    });
                    _emitCommitted(unfocus: true);
                    onFieldSubmitted();
                  },
                  onChanged: (_) {
                    if (_menuOpen) {
                      setState(() => _showAll = false);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: widget.hint ?? 'اكتب يدوياً أو اختر',
                    counterText: '',
                    hintStyle: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w400,
                      fontSize: sub ? 10 : 11,
                      color: c.text.withValues(alpha: 0.35),
                    ),
                    isDense: true,
                    suffixIcon: IconButton(
                      tooltip: _menuOpen ? 'إغلاق' : 'القائمة',
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: BoxConstraints(
                        minWidth: sub ? 28 : 32,
                        minHeight: sub ? 28 : 32,
                      ),
                      icon: Icon(
                        _menuOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: sub ? 16 : 18,
                        color: c.text.withValues(alpha: sub ? 0.28 : 0.38),
                      ),
                      onPressed: _toggleDropdown,
                    ),
                    filled: true,
                    fillColor: sub
                        ? c.surface.withValues(alpha: 0.55)
                        : c.surface.withValues(alpha: 0.92),
                    contentPadding: EdgeInsetsDirectional.fromSTEB(
                      sub ? 7 : 8,
                      sub ? 5 : 6,
                      4,
                      sub ? 5 : 6,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: radius,
                      borderSide: BorderSide(
                        color: c.border.withValues(alpha: sub ? 0.45 : 0.8),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: radius,
                      borderSide: BorderSide(
                        color: c.border.withValues(alpha: sub ? 0.45 : 0.8),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: radius,
                      borderSide: BorderSide(
                        color: c.primary.withValues(alpha: sub ? 0.55 : 0.8),
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: radius,
                      borderSide: BorderSide(color: c.riderAccent),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, optionsIterable) {
                if (!_menuOpen) return const SizedBox.shrink();
                final opts = optionsIterable.toList();
                if (opts.isEmpty) return const SizedBox.shrink();
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
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    color: c.text,
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
