import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/baghdad_places.dart';
import '../../core/theme/app_colors.dart';

class PlaceSuggestField extends StatelessWidget {
  const PlaceSuggestField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.options,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.text.withValues(alpha: 0.28);
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (value) {
        final q = value.text.trim();
        if (q.isEmpty) return options.take(12);
        return BaghdadPlaces.match(q, options).take(20);
      },
      onSelected: (v) {
        controller.value = TextEditingValue(
          text: v,
          selection: TextSelection.collapsed(offset: v.length),
        );
      },
      fieldViewBuilder: (context, textController, focus, onSubmit) {
        return TextField(
          controller: textController,
          focusNode: focus,
          onSubmitted: (_) => onSubmit(),
          onChanged: (v) => controller.text = v,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            suffixIcon: Icon(
              Icons.location_on_rounded,
              size: 22,
              color: context.colors.primary.withValues(alpha: 0.9),
            ),
            hintStyle: GoogleFonts.ibmPlexSansArabic(
              color: muted,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      },
    );
  }
}
