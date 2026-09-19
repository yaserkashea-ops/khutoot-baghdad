import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/publisher_auth_controller.dart';
import '../core/data/supabase_mappers.dart';
import '../core/models/listing.dart';
import 'listings_repository.dart';

class PublisherRepository {
  PublisherRepository({SupabaseClient? client}) : _client = client;

  static PublisherRepository get shared =>
      PublisherRepository(client: _tryClient());

  final SupabaseClient? _client;

  static SupabaseClient? _tryClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String get _token {
    final t = PublisherAuthController.shared.token;
    if (t == null || t.isEmpty) {
      throw StateError('SESSION_EXPIRED');
    }
    return t;
  }

  Future<List<Listing>> myListings() async {
    final client = _client;
    if (client == null) {
      final accountId = PublisherAuthController.shared.accountId;
      if (accountId == null || accountId.isEmpty) return const [];
      final all = await ListingsRepository.shared.fetchAll(publishedOnly: false);
      return all
          .where((l) => l.ownerAccountId == accountId)
          .toList(growable: false);
    }
    final rows = await client.rpc(
      'publisher_my_listings',
      params: {'p_token': _token},
    );
    return (rows as List)
        .map((e) => ListingMapper.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  Future<Listing> claimListing(String listingId) async {
    final client = _client;
    if (client == null) {
      throw StateError('NO_CLIENT');
    }
    final row = await client.rpc(
      'publisher_claim_listing',
      params: {
        'p_token': _token,
        'p_listing_id': listingId,
      },
    );
    return ListingMapper.fromRow(Map<String, dynamic>.from(row as Map));
  }

  Future<bool> deleteListing(String listingId) async {
    final client = _client;
    if (client == null) return false;
    final ok = await client.rpc(
      'publisher_delete_listing',
      params: {
        'p_token': _token,
        'p_listing_id': listingId,
      },
    );
    return ok == true;
  }

  Future<Listing> republishListing(String listingId) async {
    final client = _client;
    if (client == null) {
      throw StateError('NO_CLIENT');
    }
    final row = await client.rpc(
      'publisher_republish_listing',
      params: {
        'p_token': _token,
        'p_listing_id': listingId,
      },
    );
    return ListingMapper.fromRow(Map<String, dynamic>.from(row as Map));
  }

  Future<Listing> updateListing(Listing listing) async {
    final client = _client;
    if (client == null) {
      throw StateError('NO_CLIENT');
    }
    final row = await client.rpc(
      'publisher_update_listing',
      params: {
        'p_token': _token,
        'p_listing_id': listing.id,
        'p_data': ListingMapper.toInsert(listing),
      },
    );
    return ListingMapper.fromRow(Map<String, dynamic>.from(row as Map));
  }

  Future<int> incrementViews(String listingId) async {
    final client = _client;
    if (client == null) return 0;
    try {
      final n = await client.rpc(
        'increment_listing_views',
        params: {'p_listing_id': listingId},
      );
      if (n is int) return n;
      return int.tryParse('$n') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Batch bump for visible directory cards (one round-trip).
  /// Duplicate ids in [listingIds] each add one view (repeated impressions).
  Future<int> incrementViewsMany(List<String> listingIds) async {
    final client = _client;
    if (client == null || listingIds.isEmpty) return 0;
    final ids = List<String>.from(listingIds);
    try {
      final n = await client.rpc(
        'increment_listing_views_many',
        params: {'p_ids': ids},
      );
      if (n is int) return n;
      return int.tryParse('$n') ?? 0;
    } catch (_) {
      // Fallback if batch RPC is not migrated yet — preserve duplicates.
      var ok = 0;
      for (final id in ids) {
        final n = await incrementViews(id);
        if (n > 0) ok++;
      }
      return ok;
    }
  }
}
