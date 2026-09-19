import 'package:flutter/foundation.dart';

@immutable
class FilterPlaceOverride {
  const FilterPlaceOverride({
    required this.id,
    required this.name,
    this.renamedTo,
    required this.hidden,
  });

  final String id;
  final String name;
  final String? renamedTo;
  final bool hidden;

  factory FilterPlaceOverride.fromMap(Map<String, dynamic> map) {
    final renamed = (map['renamed_to'] as String?)?.trim();
    return FilterPlaceOverride(
      id: '${map['id'] ?? ''}',
      name: (map['name'] as String? ?? '').trim(),
      renamedTo: (renamed == null || renamed.isEmpty) ? null : renamed,
      hidden: map['hidden'] as bool? ?? false,
    );
  }
}
