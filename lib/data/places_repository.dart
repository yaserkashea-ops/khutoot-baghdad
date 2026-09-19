import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/models/filter_place_override.dart';
import '../core/models/managed_place.dart';

class PlacesRepository {
  PlacesRepository._();
  static final PlacesRepository shared = PlacesRepository._();

  SupabaseClient? get _client {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<List<ManagedPlace>> fetchActive() async {
    final client = _client;
    if (client == null) return const [];
    try {
      final raw = await client.rpc('list_managed_places');
      return _parseManaged(raw);
    } catch (_) {
      try {
        final rows = await client
            .from('managed_places')
            .select()
            .eq('active', true)
            .order('created_at', ascending: false);
        return _parseManaged(rows);
      } catch (_) {
        return const [];
      }
    }
  }

  Future<List<ManagedPlace>> fetchAllForAdmin() async {
    final client = _client;
    if (client == null) return const [];
    try {
      final raw = await client.rpc('admin_list_managed_places');
      return _parseManaged(raw);
    } catch (_) {
      try {
        final rows = await client
            .from('managed_places')
            .select()
            .order('created_at', ascending: false);
        return _parseManaged(rows);
      } catch (_) {
        return const [];
      }
    }
  }

  Future<List<FilterPlaceOverride>> fetchOverrides() async {
    final client = _client;
    if (client == null) return const [];
    try {
      final raw = await client.rpc('list_filter_place_overrides');
      return _parseOverrides(raw);
    } catch (_) {
      try {
        final rows = await client
            .from('filter_place_overrides')
            .select()
            .order('updated_at', ascending: false);
        return _parseOverrides(rows);
      } catch (_) {
        return const [];
      }
    }
  }

  Future<ManagedPlace> add({
    required String name,
    required String kind,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase غير مُعد');
    final raw = await client.rpc(
      'admin_add_managed_place',
      params: {'p_name': name.trim(), 'p_kind': kind},
    );
    return _asManaged(raw);
  }

  Future<ManagedPlace> updateManaged({
    required String id,
    required String name,
    required String kind,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase غير مُعد');
    final raw = await client.rpc(
      'admin_update_managed_place',
      params: {
        'p_id': id,
        'p_name': name.trim(),
        'p_kind': kind,
      },
    );
    return _asManaged(raw);
  }

  Future<void> delete(String id) async {
    final client = _client;
    if (client == null) return;
    await client.rpc(
      'admin_delete_managed_place',
      params: {'p_id': id},
    );
  }

  Future<void> deactivate(String id) async {
    final client = _client;
    if (client == null) return;
    await client.rpc(
      'admin_deactivate_managed_place',
      params: {'p_id': id},
    );
  }

  Future<FilterPlaceOverride> upsertOverride({
    required String name,
    String? renamedTo,
    bool hidden = false,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase غير مُعد');
    final raw = await client.rpc(
      'admin_upsert_filter_place_override',
      params: {
        'p_name': name.trim(),
        'p_renamed_to': renamedTo?.trim(),
        'p_hidden': hidden,
      },
    );
    if (raw is Map) {
      return FilterPlaceOverride.fromMap(Map<String, dynamic>.from(raw));
    }
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return FilterPlaceOverride.fromMap(
        Map<String, dynamic>.from(raw.first as Map),
      );
    }
    throw StateError('تعذر حفظ التعديل');
  }

  Future<void> clearOverrideByName(String name) async {
    final client = _client;
    if (client == null) return;
    await client.rpc(
      'admin_clear_filter_place_override_by_name',
      params: {'p_name': name.trim()},
    );
  }

  Future<void> deleteOverride(String id) async {
    final client = _client;
    if (client == null) return;
    await client.rpc(
      'admin_delete_filter_place_override',
      params: {'p_id': id},
    );
  }

  ManagedPlace _asManaged(dynamic raw) {
    if (raw is Map) {
      return ManagedPlace.fromMap(Map<String, dynamic>.from(raw));
    }
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return ManagedPlace.fromMap(Map<String, dynamic>.from(raw.first as Map));
    }
    throw StateError('تعذر حفظ المنطقة');
  }

  List<ManagedPlace> _parseManaged(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ManagedPlace.fromMap(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();
  }

  List<FilterPlaceOverride> _parseOverrides(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => FilterPlaceOverride.fromMap(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();
  }
}
