import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/baghdad_places.dart';
import '../../../core/theme/app_colors.dart';

/// Text field with suggestion list: type to match, or tap to select.
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
              textEditingController: widget.controller,
              focusNode: _focusNode,
              optionsBuilder: _optionsFor,
              onSelected: (value) {
                if (value == widget.addMissingLabel) {
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
                    hintText: widget.hint ?? 'اكتب أو اختر',
                    hintStyle: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      color: c.text.withValues(alpha: 0.35),
                    ),
                    isDense: true,
                    suffixIcon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: c.text.withValues(alpha: 0.38),
                    ),
                    filled: true,
                    fillColor: c.surface.withValues(alpha: 0.92),
                    contentPadding:
                        const EdgeInsetsDirectional.fromSTEB(8, 6, 4, 6),
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: radius,
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
                                    fontWeight: isAdd
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: 12,
                                    color: isAdd ? c.primary : c.text,
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
