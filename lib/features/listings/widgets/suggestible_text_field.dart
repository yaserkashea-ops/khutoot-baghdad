import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/admin_contact.dart';
import '../../../core/data/baghdad_places.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/place_text_rules.dart';
import '../../support/contact_admin_sheet.dart';
import 'place_options_menu.dart';

/// Text field with suggestion list.
/// When [listedOnly] is true, only catalog options may be committed.
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
    this.listedOnly = false,
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
  /// Reject free text; only values from [options] are accepted.
  final bool listedOnly;

  @override
  State<SuggestibleTextField> createState() => _SuggestibleTextFieldState();
}

class _SuggestibleTextFieldState extends State<SuggestibleTextField> {
  late final FocusNode _focusNode;
  late final PlaceOptionsMenuController _menu;
  final Object _tapGroup = Object();
  double _fieldWidth = 280;
  bool _applyingSuggestion = false;
  String? _typedBeforeArm;
  String _committedListed = '';

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _menu = PlaceOptionsMenuController();
    _committedListed =
        PlaceTextRules.resolveListed(widget.controller.text, widget.options) ??
            '';
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
    if (_applyingSuggestion) return;
    _syncSuggestionsWhileTyping();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      if (_applyingSuggestion || _menu.isOpen) return;
      _emitCommitted(unfocus: false);
    }
  }

  void _setControllerText(String value) {
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _armSelect(String value) {
    if (widget.addMissingLabel != null && value == widget.addMissingLabel) {
      return;
    }
    _applyingSuggestion = true;
    _typedBeforeArm ??= widget.controller.text;
    _setControllerText(value);
  }

  void _cancelArm() {
    final restore = _typedBeforeArm;
    _typedBeforeArm = null;
    if (restore != null) {
      _setControllerText(restore);
    }
    _applyingSuggestion = false;
  }

  Future<void> _openAddPlaceRequest(String typed) async {
    final isDestination =
        widget.addMissingLabel == BaghdadPlaces.addMissingDestination;
    final placeHint = typed.isEmpty ? '……' : typed;
    final message = isDestination
        ? 'أرغب بإضافة الوجهة التالية إلى قائمة النشر: $placeHint'
        : 'أرغب بإضافة المنطقة التالية إلى قائمة النشر: $placeHint';
    if (!mounted) return;
    await showContactAdminSheet(
      context,
      initialKind: AdminContactKind.problem,
      initialMessage: message,
    );
  }

  void _syncSuggestionsWhileTyping() {
    if (_applyingSuggestion) return;
    if (!_focusNode.hasFocus) return;
    final q = widget.controller.text.trim();
    if (q.isEmpty) {
      if (_menu.isOpen) {
        _menu.close();
        if (mounted) setState(() {});
      }
      return;
    }
    if (_menu.isOpen) {
      _menu.refilter();
      return;
    }
    if (!mounted) return;
    _menu.open(
      context: context,
      width: _fieldWidth,
      optionsOf: () => widget.options,
      queryOf: () => widget.controller.text,
      maxHeight: widget.subordinate ? 160 : 200,
      tapRegionGroupId: _tapGroup,
      keepFocus: true,
      showAll: false,
      trailingOption: widget.listedOnly ? widget.addMissingLabel : null,
      onSelected: _selectOption,
      onArmSelect: _armSelect,
      onCancelArm: _cancelArm,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _selectOption(String value) {
    if (widget.addMissingLabel != null && value == widget.addMissingLabel) {
      final typed = (_typedBeforeArm ?? widget.controller.text).trim();
      _cancelArm();
      _menu.close();
      _focusNode.unfocus();
      unawaited(_openAddPlaceRequest(typed));
      return;
    }
    _applyingSuggestion = true;
    _typedBeforeArm = null;
    _committedListed = value;
    _setControllerText(value);
    _menu.close();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setControllerText(value);
      _applyingSuggestion = false;
      widget.onCommitted?.call(value);
      _focusNode.unfocus();
      if (mounted) setState(() {});
    });
  }

  void _toggleDropdown() {
    _menu.toggle(
      context: context,
      width: _fieldWidth,
      optionsOf: () => widget.options,
      queryOf: () => widget.controller.text,
      maxHeight: widget.subordinate ? 160 : 200,
      tapRegionGroupId: _tapGroup,
      keepFocus: false,
      trailingOption: widget.listedOnly ? widget.addMissingLabel : null,
      onSelected: _selectOption,
      onArmSelect: _armSelect,
      onCancelArm: _cancelArm,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _emitCommitted({required bool unfocus}) {
    final text = widget.controller.text.trim();
    if (widget.listedOnly) {
      if (text.isEmpty) {
        if (unfocus) _focusNode.unfocus();
        return;
      }
      final listed = PlaceTextRules.resolveListed(text, widget.options);
      if (listed != null) {
        _committedListed = listed;
        if (widget.controller.text != listed) {
          _setControllerText(listed);
        }
        widget.onCommitted?.call(listed);
        if (unfocus) _focusNode.unfocus();
        return;
      }
      // Free text rejected — restore last listed (or clear) and ask admin.
      final typed = text;
      _applyingSuggestion = true;
      _setControllerText(_committedListed);
      _applyingSuggestion = false;
      if (mounted) setState(() {});
      unawaited(_openAddPlaceRequest(typed));
      if (unfocus) _focusNode.unfocus();
      return;
    }

    if (widget.controller.text != text) {
      _setControllerText(text);
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
            return TapRegion(
              groupId: _tapGroup,
              onTapOutside: (_) {
                if (_menu.isOpen) {
                  _menu.close();
                  _applyingSuggestion = false;
                  _typedBeforeArm = null;
                  setState(() {});
                  _emitCommitted(unfocus: false);
                }
              },
              child: KeyedSubtree(
                key: _menu.targetKey,
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
                    hintText: widget.hint ??
                        (widget.listedOnly
                            ? 'اختر من القائمة'
                            : 'اكتب يدوياً أو اختر'),
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
              ),
            );
          },
        ),
      ],
    );
  }
}
