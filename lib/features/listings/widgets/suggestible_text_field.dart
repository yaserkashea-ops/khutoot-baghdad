import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import 'place_options_menu.dart';

/// Text field with suggestion list. Free typing is always allowed.
/// The options menu opens/closes only via the arrow — without opening the keyboard.
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
  late final PlaceOptionsMenuController _menu;
  double _fieldWidth = 280;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _menu = PlaceOptionsMenuController();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant SuggestibleTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    _menu.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_menu.isOpen) _menu.refilter();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _emitCommitted(unfocus: false);
    }
  }

  void _toggleDropdown() {
    _menu.toggle(
      context: context,
      width: _fieldWidth,
      optionsOf: () => widget.options,
      queryOf: () => widget.controller.text,
      maxHeight: widget.subordinate ? 160 : 200,
      onSelected: (value) {
        widget.controller.text = value;
        widget.controller.selection =
            TextSelection.collapsed(offset: value.length);
        _emitCommitted(unfocus: true);
        if (mounted) setState(() {});
      },
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
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
    final menuOpen = _menu.isOpen;

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
            _fieldWidth = constraints.maxWidth;
            return CompositedTransformTarget(
              link: _menu.layerLink,
              child: TextFormField(
                key: widget.fieldKey,
                controller: widget.controller,
                focusNode: _focusNode,
                validator: widget.validator,
                style: textStyle,
                maxLength: widget.maxLength,
                inputFormatters: widget.inputFormatters,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  _menu.close();
                  _emitCommitted(unfocus: true);
                  if (mounted) setState(() {});
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
                    tooltip: menuOpen ? 'إغلاق' : 'القائمة',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: BoxConstraints(
                      minWidth: sub ? 28 : 32,
                      minHeight: sub ? 28 : 32,
                    ),
                    icon: Icon(
                      menuOpen
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
              ),
            );
          },
        ),
      ],
    );
  }
}
