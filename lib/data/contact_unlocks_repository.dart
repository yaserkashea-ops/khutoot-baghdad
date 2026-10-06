import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/publisher_auth_controller.dart';
import '../core/config/preview_mode.dart';
import '../core/models/contact_unlock.dart';
import '../core/models/listing.dart';
import 'listings_repository.dart';

class ContactUnlocksTableMissing implements Exception {}

class RequestAlreadyBooked implements Exception {}

class ContactUnlocksRepository {
  ContactUnlocksRepository({SupabaseClient? client}) : _client = client;

  static ContactUnlocksRepository? _shared;
  static ContactUnlocksRepository get shared =>
      _shared ?? ContactUnlocksRepository(client: _tryClient());

  static void bindShared(SupabaseClient client) {
    if (PreviewMode.enabled) return;
    _shared = ContactUnlocksRepository(client: client);
  }

  final SupabaseClient? _client;

  static SupabaseClient? _tryClient() {
    if (PreviewMode.enabled) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String get _driverKey {
    final auth = PublisherAuthController.shared;
    final login = (auth.login ?? '').trim();
    if (login.isNotEmpty) return login;
    final id = (auth.accountId ?? '').trim();
    if (id.isNotEmpty) return id;
    throw StateError('NO_DRIVER_SESSION');
  }

  bool _tableMissing(Object e) {
    final m = e.toString().toLowerCase();
    return m.contains('contact_unlocks') &&
        (m.contains('does not exist') ||
            m.contains('42p01') ||
            m.contains('schema cache'));
  }

  Future<List<ContactUnlock>> mine() async {
    final client = _client;
    if (client == null) return const [];
    String key;
    try {
      key = _driverKey;
    } catch (_) {
      return const [];
    }
    try {
      var query = client.from('contact_unlocks').select();
      final accountId = PublisherAuthController.shared.accountId;
      if (accountId != null && accountId.isNotEmpty) {
        query = query.or(
          'driver_contact.eq.$key,driver_account_id.eq.$accountId',
        );
      } else {
        query = query.eq('driver_contact', key);
      }
      final rows =
          await query.order('requested_at', ascending: false);
      return await _attachRequests(
        (rows as List)
            .map(
              (e) => ContactUnlock.fromRow(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      );
    } catch (e) {
      if (_tableMissing(e)) return const [];
      rethrow;
    }
  }

  Future<ContactUnlock?> forRequest(String riderRequestId) async {
    final all = await mine();
    for (final u in all) {
      if (u.riderRequestId == riderRequestId) return u;
    }
    return null;
  }

  Future<bool> isRequestBooked(String riderRequestId) async {
    final client = _client;
    if (client == null) return false;
    try {
      final rows = await client
          .from('contact_unlocks')
          .select('id')
          .eq('rider_request_id', riderRequestId)
          .inFilter('status', ['pending', 'approved'])
          .limit(1);
      return (rows as List).isNotEmpty;
    } catch (e) {
      if (_tableMissing(e)) return false;
      return false;
    }
  }

  Future<ContactUnlock> requestUnlock({
    required Listing riderRequest,
  }) async {
    final client = _client;
    if (client == null) throw StateError('NO_CLIENT');
    if (riderRequest.isBooked || await isRequestBooked(riderRequest.id)) {
      throw RequestAlreadyBooked();
    }
    final key = _driverKey;
    final accountId = PublisherAuthController.shared.accountId;
    try {
      final row = await client
          .from('contact_unlocks')
          .insert({
            'rider_request_id': riderRequest.id,
            'driver_contact': key,
            if (accountId != null && accountId.isNotEmpty)
              'driver_account_id': accountId,
            'status': 'pending',
          })
          .select()
          .single();
      unawaited(
        ListingsRepository.shared.setBooked(riderRequest.id, booked: true),
      );
      return ContactUnlock.fromRow(
        Map<String, dynamic>.from(row),
        request: riderRequest.copyWith(isBooked: true),
      );
    } on PostgrestException catch (e) {
      final code = e.code ?? '';
      if (code == '23505' || (e.message.contains('duplicate'))) {
        final existing = await forRequest(riderRequest.id);
        if (existing != null) return existing;
      }
      rethrow;
    }
  }

  Future<List<ContactUnlock>> adminQueue() async {
    final client = _client;
    if (client == null) return const [];
    try {
      final rows = await client
          .from('contact_unlocks')
          .select()
          .order('requested_at', ascending: false);
      final unlocks = (rows as List)
          .map((e) => ContactUnlock.fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();
      return await _attachRequests(unlocks);
    } catch (e) {
      if (_tableMissing(e)) throw ContactUnlocksTableMissing();
      rethrow;
    }
  }

  Future<List<ContactUnlock>> _attachRequests(List<ContactUnlock> unlocks) async {
    if (unlocks.isEmpty) return const [];
    try {
      final listings =
          await ListingsRepository.shared.fetchAll(publishedOnly: false);
      final byId = {for (final l in listings) l.id: l};
      return unlocks
          .map((u) => u.copyWith(request: byId[u.riderRequestId]))
          .toList(growable: false);
    } catch (_) {
      return unlocks;
    }
  }

  Future<void> setStatus({
    required String id,
    required ContactUnlockStatus status,
  }) async {
    final client = _client;
    if (client == null) throw StateError('NO_CLIENT');
    await client.from('contact_unlocks').update({
      'status': ContactUnlock.statusTo(status),
      if (status == ContactUnlockStatus.approved)
        'approved_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
    if (status == ContactUnlockStatus.rejected) {
      try {
        final row = await client
            .from('contact_unlocks')
            .select('rider_request_id')
            .eq('id', id)
            .single();
        final rid = '${row['rider_request_id'] ?? ''}';
        if (rid.isNotEmpty && !await isRequestBooked(rid)) {
          await ListingsRepository.shared.setBooked(
            rid,
            booked: false,
            republish: false,
          );
        }
      } catch (_) {}
    }
  }

  /// Clears every pending/approved hold so the rider request is bookable again.
  Future<void> releaseActiveForRequest(String riderRequestId) async {
    final client = _client;
    if (client == null) throw StateError('NO_CLIENT');
    await client
        .from('contact_unlocks')
        .update({'status': ContactUnlock.statusTo(ContactUnlockStatus.rejected)})
        .eq('rider_request_id', riderRequestId)
        .inFilter('status', ['pending', 'approved']);
    try {
      await ListingsRepository.shared.setBooked(
        riderRequestId,
        booked: false,
      );
    } catch (_) {}
  }
}
