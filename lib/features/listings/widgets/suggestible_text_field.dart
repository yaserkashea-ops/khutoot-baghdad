import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/baghdad_places.dart';
import '../../../core/theme/app_colors.dart';

/// Text field with suggestion list: type to match, or tap to select.
/// Custom values via [addMissingLabel] at the bottom of results.
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
  });

  final Key? fieldKey;
  final String label;
  final TextEditingController controller;
  final List<String> options;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final String? addMissingLabel;

  @override
  State<SuggestibleTextField> createState() => _SuggestibleTextFieldState();
}

class _SuggestibleTextFieldState extends State<SuggestibleTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Iterable<String> _optionsFor(TextEditingValue value) {
    final q = value.text.trim();
    final seen = <String>{};
    final pool = <String>[];
    for (final o in widget.options) {
      if (seen.add(o)) pool.add(o);
    }
    final matched = q.isEmpty
        ? pool
        : pool.where((o) => BaghdadPlaces.matchesQuery(o, q)).toList();
    final add = widget.addMissingLabel;
    if (add == null) return matched;
    return [...matched.where((o) => o != add), add];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
            color: c.text.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        RawAutocomplete<String>(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          optionsBuilder: _optionsFor,
          onSelected: (value) {
            if (value == widget.addMissingLabel) {
              // Keep typed custom name; do not replace with the action label.
              _focusNode.unfocus();
              return;
            }
            widget.controller.text = value;
            widget.controller.selection =
                TextSelection.collapsed(offset: value.length);
            _focusNode.unfocus();
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            return TextFormField(
              key: widget.fieldKey,
              controller: textController,
              focusNode: focusNode,
              validator: widget.validator,
              style: textStyle,
              onFieldSubmitted: (_) => onFieldSubmitted(),
              decoration: InputDecoration(
                hintText: widget.hint ?? 'اكتب للبحث أو اختر من القائمة',
                hintStyle: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: c.text.withValues(alpha: 0.4),
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: c.text.withValues(alpha: 0.45),
                ),
                filled: true,
                fillColor: c.surface,
                contentPadding:
                    const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: c.riderAccent),
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
                elevation: 2,
                color: c.surface,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 240, minWidth: 280),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: opts.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: c.border),
                    itemBuilder: (context, index) {
                      final option = opts[index];
                      final isAdd = option == widget.addMissingLabel;
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
                              fontWeight:
                                  isAdd ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 14,
                              color: isAdd ? c.primary : c.text,
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
