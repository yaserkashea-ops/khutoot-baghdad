import 'package:flutter/foundation.dart';

/// A place added from the admin panel (not in the static Baghdad catalog).
@immutable
class ManagedPlace {
  const ManagedPlace({
    required this.id,
    required this.name,
    required this.kind,
    required this.active,
    this.createdAt,
  });

  final String id;
  final String name;

  /// `area` | `destination` | `both`
  final String kind;
  final bool active;
  final DateTime? createdAt;

  bool get isArea => kind == 'area' || kind == 'both';
  bool get isDestination => kind == 'destination' || kind == 'both';

  String get kindLabel => switch (kind) {
        'area' => 'منطقة انطلاق',
        'destination' => 'وجهة',
        _ => 'منطقة ووجهة',
      };

  factory ManagedPlace.fromMap(Map<String, dynamic> map) {
    return ManagedPlace(
      id: '${map['id'] ?? ''}',
      name: (map['name'] as String? ?? '').trim(),
      kind: (map['kind'] as String? ?? 'both').trim(),
      active: map['active'] as bool? ?? true,
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
    );
  }
}
