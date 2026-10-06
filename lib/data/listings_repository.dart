import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/preview_mode.dart';
import '../core/data/supabase_mappers.dart';
import '../core/matches/listing_route_match.dart';
import '../core/models/listing.dart';
import '../core/models/listing_subscription.dart';
import '../core/notifications/publisher_push_registrar.dart';
import '../core/utils/phone_digits.dart';

/// Listings store. Uses Supabase when a client is provided, otherwise in-memory.
class ListingsRepository {
  ListingsRepository({SupabaseClient? client}) : _client = client;

  static ListingsRepository shared = ListingsRepository();

  final SupabaseClient? _client;

  bool get isRemote => _client != null;

  late final List<Listing> _items = _client == null ? _seedLocal() : <Listing>[];
  int _seq = 100;
  String? _lastWriteKey;
  DateTime? _lastWriteAt;
  Listing? _lastWritten;

  String _writeKey(Listing listing) => [
        listing.type.name,
        listing.area.trim(),
        listing.destination.trim(),
        listing.timePeriod.name,
        listing.vehicleType ?? '',
        listing.contactPhone ?? '',
        listing.contactTelegram ?? '',
        listing.status.name,
      ].join('|');

  Listing? _replayWrite(Listing listing) {
    final key = _writeKey(listing);
    final at = _lastWriteAt;
    final last = _lastWritten;
    if (last == null || at == null || _lastWriteKey != key) return null;
    if (DateTime.now().difference(at) > const Duration(seconds: 8)) return null;
    return last;
  }

  Listing _rememberWrite(Listing listing) {
    _lastWriteKey = _writeKey(listing);
    _lastWriteAt = DateTime.now();
    _lastWritten = listing;
    return listing;
  }

  static void bindShared(SupabaseClient client) {
    if (PreviewMode.enabled) return;
    shared = ListingsRepository(client: client);
  }

  /// In-memory seed only. Safe to call more than once.
  static void bindPreview() {
    shared = ListingsRepository();
  }

  static List<Listing> _seedLocal() => [
        Listing(
          id: '1',
          type: ListingType.driver,
          area: 'المنصور',
          destination: 'الجادرية',
          originSubs: const ['شارع الرواد', 'حي دراغ'],
          destinationSubs: const ['جامعة بغداد', 'مول الجادرية'],
          timePeriod: TimePeriod.morning,
          departureTime: '7:30',
          returnTime: '2:00',
          vehicleType: 'سيارة صالون',
          seatsCount: 3,
          genderRequirement: GenderRequirement.mixed,
          contactPhone: '9647701234567',
          status: ListingStatus.published,
          governorate: 'بغداد',
          referenceCode: 'KH-LOCAL1',
          ownerAccountId: PreviewMode.accountId,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          bumpedAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: ListingSubscription.renewFromNow(
            DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ),
        Listing(
          id: '2',
          type: ListingType.driver,
          area: 'الأعظمية',
          destination: 'باب المعظم',
          originSubs: const ['شارع الرشيد', 'الفضل'],
          destinationSubs: const ['باب المعظم — الوزارات', 'مدينة الطب'],
          timePeriod: TimePeriod.evening,
          returnTime: '5:30',
          vehicleType: 'فان',
          seatsCount: 6,
          genderRequirement: GenderRequirement.maleOnly,
          contactPhone: '9647809876543',
          status: ListingStatus.published,
          governorate: 'بغداد',
          referenceCode: 'KH-LOCAL2',
          createdAt: DateTime.now().subtract(const Duration(days: 35)),
          bumpedAt: DateTime.now().subtract(const Duration(days: 35)),
          expiresAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Listing(
          id: '5',
          type: ListingType.driver,
          area: 'الكرادة',
          destination: 'زيونة',
          timePeriod: TimePeriod.morning,
          vehicleType: 'سيارة صالون',
          seatsCount: 3,
          genderRequirement: GenderRequirement.mixed,
          contactPhone: '9647700001122',
          status: ListingStatus.published,
          governorate: 'بغداد',
          referenceCode: 'KH-SOON1',
          createdAt: DateTime.now().subtract(const Duration(days: 27)),
          bumpedAt: DateTime.now().subtract(const Duration(days: 27)),
          expiresAt: DateTime.now().add(const Duration(days: 3)),
        ),
        Listing(
          id: '3',
          type: ListingType.driver,
          area: 'الدورة',
          destination: 'الجامعة التكنولوجية',
          timePeriod: TimePeriod.morning,
          vehicleType: 'سيارة صالون',
          seatsCount: 3,
          genderRequirement: GenderRequirement.mixed,
          contactPhone: '9647511112233',
          status: ListingStatus.pendingReview,
          governorate: 'بغداد',
          referenceCode: 'KH-PEND1',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        Listing(
          id: '4',
          type: ListingType.driver,
          area: 'البياع',
          destination: 'الجامعة المستنصرية',
          originSubs: const ['السيدية'],
          destinationSubs: const ['شارع فلسطين', 'الوزيرية'],
          timePeriod: TimePeriod.evening,
          vehicleType: 'سيارة صالون',
          seatsCount: 2,
          genderRequirement: GenderRequirement.femaleOnly,
          contactTelegram: '@baghdad_line',
          status: ListingStatus.awaitingPayment,
          governorate: 'بغداد',
          referenceCode: 'KH-PAY01',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        Listing(
          id: 'r1',
          type: ListingType.rider,
          area: 'الدورة',
          destination: 'الجادرية',
          originSubs: const ['شارع أبو طيارة'],
          destinationSubs: const ['جامعة بغداد'],
          timePeriod: TimePeriod.morning,
          departureTime: '7:00',
          seatsCount: 1,
          genderRequirement: GenderRequirement.mixed,
          contactPhone: '9647705551111',
          status: ListingStatus.published,
          governorate: 'بغداد',
          referenceCode: 'KH-RIDE1',
          ownerAccountId: PreviewMode.accountId,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          bumpedAt: DateTime.now().subtract(const Duration(hours: 5)),
          expiresAt: ListingSubscription.renewFromNow(
            DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ),
        Listing(
          id: 'r2',
          type: ListingType.rider,
          area: 'المنصور',
          destination: 'باب المعظم',
          timePeriod: TimePeriod.evening,
          seatsCount: 2,
          genderRequirement: GenderRequirement.femaleOnly,
          contactTelegram: '@preview_rider',
          status: ListingStatus.published,
          governorate: 'بغداد',
          referenceCode: 'KH-RIDE2',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          bumpedAt: DateTime.now().subtract(const Duration(days: 2)),
          expiresAt: ListingSubscription.renewFromNow(
            DateTime.now().subtract(const Duration(days: 2)),
          ),
        ),
        Listing(
          id: 'legacy-open',
          type: ListingType.rider,
          area: '',
          destination: '',
          timePeriod: TimePeriod.morning,
          genderRequirement: GenderRequirement.mixed,
          vehicleType: 'خط صباحي...',
          contactPhone: '9647701234567',
          status: ListingStatus.published,
          governorate: 'بغداد',
          referenceCode: 'KH-OLD01',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          bumpedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ];

  Future<List<Listing>> fetchAll({bool publishedOnly = true}) async {
    if (_client != null) {
      try {
        var query = _client.from('listings').select();
        if (publishedOnly) {
          query = query.eq('status', 'published');
        }
        final rows = await query
            .order('bumped_at', ascending: false, nullsFirst: false)
            .order('created_at', ascending: false)
            .timeout(const Duration(seconds: 8));
        final list = (rows as List)
            .map((e) => ListingMapper.fromRow(Map<String, dynamic>.from(e as Map)))
            .where((l) => !publishedOnly || l.isLiveInDirectory)
            .toList()
          ..sort((a, b) => b.sortAt.compareTo(a.sortAt));
        return List<Listing>.unmodifiable(await _withActiveBookings(list));
      } catch (_) {
        final rows = await _client
            .from('listings')
            .select()
            .order('bumped_at', ascending: false, nullsFirst: false)
            .order('created_at', ascending: false);
        final list = (rows as List)
            .map((e) => ListingMapper.fromRow(Map<String, dynamic>.from(e as Map)))
            .where((l) => !publishedOnly || l.isLiveInDirectory)
            .toList()
          ..sort((a, b) => b.sortAt.compareTo(a.sortAt));
        return List<Listing>.unmodifiable(await _withActiveBookings(list));
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final copy = _items
        .where((l) => !publishedOnly || l.isLiveInDirectory)
        .toList()
      ..sort((a, b) => b.sortAt.compareTo(a.sortAt));
    return List<Listing>.unmodifiable(copy);
  }

  Future<List<Listing>> fetchAdminQueue({ListingStatus? status}) async {
    if (_client != null) {
      try {
        final raw = await _client.rpc(
          'admin_list_listings_by_status',
          params: {
            'p_status': status == null ? null : ListingMapper.statusToDb(status),
          },
        );
        return List<Listing>.unmodifiable(
          (raw as List)
              .map((e) => ListingMapper.fromRow(Map<String, dynamic>.from(e as Map)))
              .toList(),
        );
      } catch (_) {
        return fetchAll(publishedOnly: false).then((all) {
          final filtered = status == null
              ? all
              : all.where((l) => l.status == status).toList();
          return List<Listing>.unmodifiable(filtered);
        });
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final list = status == null
        ? List<Listing>.from(_items)
        : _items.where((l) => l.status == status).toList();
    list.sort((a, b) => b.sortAt.compareTo(a.sortAt));
    return List<Listing>.unmodifiable(list);
  }

  /// Driver submits a route for admin review (not public yet).
  Future<Listing> submitRequest(Listing listing) async {
    final replay = _replayWrite(listing.copyWith(status: ListingStatus.pendingReview));
    if (replay != null) return replay;
    final payload = ListingMapper.toInsert(
      listing.copyWith(status: ListingStatus.pendingReview),
    );
    if (_client != null) {
      try {
        final row = await _client.rpc(
          'submit_listing_request',
          params: {'p_data': payload},
        );
        final map = row is Map
            ? Map<String, dynamic>.from(row)
            : Map<String, dynamic>.from((row as List).first as Map);
        return _rememberWrite(ListingMapper.fromRow(map));
      } catch (_) {
        final row = await _client
            .from('listings')
            .insert({
              ...payload,
              'status': 'pending_review',
              'governorate': listing.governorate,
            })
            .select()
            .single()
            .timeout(const Duration(seconds: 8));
        return _rememberWrite(ListingMapper.fromRow(Map<String, dynamic>.from(row)));
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final now = DateTime.now();
    final created = listing.copyWith(
      id: listing.id.isEmpty ? '${_seq++}' : listing.id,
      status: ListingStatus.pendingReview,
      referenceCode: listing.referenceCode ??
          'KH-L${_seq.toString().padLeft(4, '0')}',
      createdAt: now,
      updatedAt: now,
    );
    _items.insert(0, created);
    return _rememberWrite(created);
  }

  /// Guest compose on the unified public feed (preview / in-memory).
  Future<Listing> publishUnifiedGuest(Listing listing) async {
    final published = listing.copyWith(status: ListingStatus.published);
    final replay = _replayWrite(published);
    if (replay != null) return replay;
    if (_client != null && !PreviewMode.enabled) {
      return submitRequest(listing);
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final now = DateTime.now();
    final created = listing.copyWith(
      id: listing.id.isEmpty ? '${_seq++}' : listing.id,
      status: ListingStatus.published,
      createdAt: now,
      updatedAt: now,
      bumpedAt: now,
    );
    _items.insert(0, created);
    return _rememberWrite(created);
  }

  Future<Listing> setStatus({
    required String id,
    required ListingStatus status,
    String? adminNote,
  }) async {
    if (_client != null) {
      try {
        final row = await _client.rpc(
          'admin_set_listing_status',
          params: {
            'p_id': id,
            'p_status': ListingMapper.statusToDb(status),
            'p_admin_note': adminNote,
          },
        );
        final map = row is Map
            ? Map<String, dynamic>.from(row)
            : Map<String, dynamic>.from((row as List).first as Map);
        return _afterPublishStatus(ListingMapper.fromRow(map));
      } catch (_) {
        final now = DateTime.now().toUtc();
        final row = await _client
            .from('listings')
            .update({
              'status': ListingMapper.statusToDb(status),
              if (adminNote != null) 'admin_note': adminNote,
              if (status == ListingStatus.published) ...{
                'bumped_at': now.toIso8601String(),
                'expires_at':
                    ListingSubscription.renewFromNow(now).toIso8601String(),
                'is_hidden': false,
              },
              'updated_at': now.toIso8601String(),
            })
            .eq('id', id)
            .select()
            .single();
        return _afterPublishStatus(
          ListingMapper.fromRow(Map<String, dynamic>.from(row)),
        );
      }
    }
    final index = _items.indexWhere((l) => l.id == id);
    if (index < 0) throw StateError('Listing $id not found');
    final now = DateTime.now();
    final updated = _items[index].copyWith(
      status: status,
      adminNote: adminNote,
      bumpedAt: status == ListingStatus.published
          ? now
          : _items[index].bumpedAt,
      expiresAt: status == ListingStatus.published
          ? ListingSubscription.renewFromNow(now)
          : _items[index].expiresAt,
      isHidden:
          status == ListingStatus.published ? false : _items[index].isHidden,
      updatedAt: now,
    );
    _items[index] = updated;
    return _afterPublishStatus(updated);
  }

  Listing _afterPublishStatus(Listing listing) {
    if (listing.status == ListingStatus.published && !PreviewMode.enabled) {
      unawaited(ListingPublishPush.notifyPublished(listing.id));
    }
    return listing;
  }

  /// Published / hidden / expired listings for the subscriptions admin tab.
  Future<List<Listing>> fetchSubscriptionListings() async {
    final all = await fetchAll(publishedOnly: false);
    final list = all
        .where((l) => l.status == ListingStatus.published || l.isHidden)
        .toList()
      ..sort((a, b) => a.effectiveExpiresAt.compareTo(b.effectiveExpiresAt));
    return List<Listing>.unmodifiable(list);
  }

  Future<Listing> renewListing(String id) async {
    if (_client != null) {
      try {
        final row = await _client.rpc(
          'admin_renew_listing',
          params: {'p_id': id},
        );
        final map = row is Map
            ? Map<String, dynamic>.from(row)
            : Map<String, dynamic>.from((row as List).first as Map);
        return ListingMapper.fromRow(map);
      } catch (_) {
        final now = DateTime.now().toUtc();
        final row = await _client
            .from('listings')
            .update({
              'status': 'published',
              'is_hidden': false,
              'bumped_at': now.toIso8601String(),
              'expires_at':
                  ListingSubscription.renewFromNow(now).toIso8601String(),
              'updated_at': now.toIso8601String(),
            })
            .eq('id', id)
            .select()
            .single();
        return ListingMapper.fromRow(Map<String, dynamic>.from(row));
      }
    }
    final index = _items.indexWhere((l) => l.id == id);
    if (index < 0) throw StateError('Listing $id not found');
    final now = DateTime.now();
    final updated = _items[index].copyWith(
      status: ListingStatus.published,
      isHidden: false,
      bumpedAt: now,
      expiresAt: ListingSubscription.renewFromNow(now),
      updatedAt: now,
    );
    _items[index] = updated;
    return updated;
  }

  Future<Listing> setBooked(
    String id, {
    required bool booked,
    bool republish = true,
  }) async {
    if (_client != null) {
      try {
        final now = DateTime.now().toUtc();
        final payload = <String, dynamic>{
          'is_booked': booked,
          'updated_at': now.toIso8601String(),
        };
        if (!booked && republish) {
          payload['status'] = 'published';
          payload['is_hidden'] = false;
          payload['bumped_at'] = now.toIso8601String();
          payload['expires_at'] =
              ListingSubscription.renewFromNow(now).toIso8601String();
        }
        final row = await _client
            .from('listings')
            .update(payload)
            .eq('id', id)
            .select()
            .single();
        return ListingMapper.fromRow(Map<String, dynamic>.from(row));
      } catch (_) {
        final found = await findById(id);
        if (found == null) rethrow;
        return found.copyWith(isBooked: booked, updatedAt: DateTime.now());
      }
    }
    final index = _items.indexWhere((l) => l.id == id);
    if (index < 0) throw StateError('Listing $id not found');
    final now = DateTime.now();
    final current = _items[index];
    final updated = booked
        ? current.copyWith(isBooked: true, updatedAt: now)
        : republish
            ? current.copyWith(
                isBooked: false,
                isHidden: false,
                status: ListingStatus.published,
                bumpedAt: now,
                expiresAt: ListingSubscription.renewFromNow(now),
                updatedAt: now,
              )
            : current.copyWith(isBooked: false, updatedAt: now);
    _items[index] = updated;
    return updated;
  }

  Future<Listing> hideListing(String id) async {
    if (_client != null) {
      try {
        final row = await _client.rpc(
          'admin_hide_listing',
          params: {'p_id': id},
        );
        final map = row is Map
            ? Map<String, dynamic>.from(row)
            : Map<String, dynamic>.from((row as List).first as Map);
        return ListingMapper.fromRow(map);
      } catch (_) {
        final row = await _client
            .from('listings')
            .update({
              'is_hidden': true,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', id)
            .select()
            .single();
        return ListingMapper.fromRow(Map<String, dynamic>.from(row));
      }
    }
    final index = _items.indexWhere((l) => l.id == id);
    if (index < 0) throw StateError('Listing $id not found');
    final updated = _items[index].copyWith(
      isHidden: true,
      updatedAt: DateTime.now(),
    );
    _items[index] = updated;
    return updated;
  }

  /// Treat pending/approved contact unlocks as booked even if `is_booked` is missing.
  Future<List<Listing>> _withActiveBookings(List<Listing> list) async {
    if (_client == null || list.isEmpty) return list;
    try {
      final rows = await _client
          .from('contact_unlocks')
          .select('rider_request_id')
          .inFilter('status', ['pending', 'approved']);
      final ids = <String>{
        for (final raw in rows as List)
          '${(raw as Map)['rider_request_id'] ?? ''}',
      }..remove('');
      return [
        for (final l in list)
          l.isDriver ? l : l.copyWith(isBooked: ids.contains(l.id)),
      ];
    } catch (_) {
      return list;
    }
  }

  /// Opposite-type listings that share origin/destination (main or sub) and time.
  Future<List<Listing>> fetchRouteMatches(Listing mine) async {
    final opposite =
        mine.isDriver ? ListingType.rider : ListingType.driver;
    List<Listing> candidates;
    if (_client != null) {
      final rows = await _client
          .from('listings')
          .select()
          .eq('listing_type', opposite == ListingType.driver ? 'driver' : 'rider')
          .order('created_at', ascending: false);
      candidates = (rows as List)
          .map(
            (e) => ListingMapper.fromRow(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      candidates = _items.where((l) => l.type == opposite).toList();
    }
    return List<Listing>.unmodifiable(
      await _withActiveBookings(
        ListingRouteMatch.filterMatches(
          mine: mine,
          candidates: candidates.where((l) => l.isLiveInDirectory),
        ),
      ),
    );
  }

  Future<Listing?> findByPhone(String phone) async {
    final matches = await findAllByPhone(phone);
    if (matches.isEmpty) return null;
    return matches.first;
  }

  /// All listings linked to this phone (normalized digits).
  Future<List<Listing>> findAllByPhone(String phone) async {
    if (PhoneDigits.normalize(phone).isEmpty) return const [];

    if (_client != null) {
      try {
        final rows = await _client.rpc(
          'find_listings_by_phone',
          params: {'p_phone': phone.trim()},
        );
        return List<Listing>.unmodifiable(
          (rows as List)
              .map(
                (e) => ListingMapper.fromRow(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
        );
      } catch (_) {
        final all = await fetchAll();
        return List<Listing>.unmodifiable(
          all.where((l) => PhoneDigits.matches(l.contactPhone, phone)).toList(),
        );
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 20));
    return List<Listing>.unmodifiable(
      _items.where((l) => PhoneDigits.matches(l.contactPhone, phone)).toList(),
    );
  }

  Future<Listing> insert(Listing listing) async {
    final replay = _replayWrite(listing);
    if (replay != null) return replay;
    if (_client != null) {
      final row = await _client
          .from('listings')
          .insert(ListingMapper.toInsert(listing))
          .select()
          .single()
          .timeout(const Duration(seconds: 8));
      return _rememberWrite(ListingMapper.fromRow(Map<String, dynamic>.from(row)));
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final now = DateTime.now();
    final withExpiry = listing.status == ListingStatus.published &&
            listing.expiresAt == null
        ? listing.copyWith(
            expiresAt: ListingSubscription.renewFromNow(now),
            bumpedAt: listing.bumpedAt ?? now,
          )
        : listing;
    final created = withExpiry.copyWith(
      id: withExpiry.id.isEmpty ? '${_seq++}' : withExpiry.id,
      createdAt: now,
      updatedAt: now,
    );
    _items.insert(0, created);
    return _rememberWrite(created);
  }

  Future<List<Listing>> insertMany(Iterable<Listing> listings) async {
    final created = <Listing>[];
    for (final listing in listings) {
      created.add(await insert(listing));
    }
    return created;
  }

  Future<Listing> update(Listing listing) async {
    if (_client != null) {
      final phone = listing.contactPhone?.trim() ?? '';
      if (phone.isNotEmpty) {
        try {
          final row = await _client.rpc(
            'update_listing_by_phone',
            params: {
              'p_phone': phone,
              'p_id': listing.id,
              'p_data': ListingMapper.toInsert(listing),
            },
          );
          final map = row is Map
              ? Map<String, dynamic>.from(row)
              : Map<String, dynamic>.from((row as List).first as Map);
          return ListingMapper.fromRow(map);
        } catch (_) {
          // Fall through to direct update (admin session).
        }
      }
      final row = await _client
          .from('listings')
          .update(ListingMapper.toUpdate(listing))
          .eq('id', listing.id)
          .select()
          .single();
      return ListingMapper.fromRow(Map<String, dynamic>.from(row));
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final index = _items.indexWhere((l) => l.id == listing.id);
    if (index < 0) {
      throw StateError('Listing ${listing.id} not found');
    }
    final updated = listing.copyWith(updatedAt: DateTime.now());
    _items[index] = updated;
    return updated;
  }

  Future<Listing?> findById(String id) async {
    if (_client != null) {
      final rows =
          await _client.from('listings').select().eq('id', id).limit(1);
      final list = rows as List;
      if (list.isEmpty) return null;
      return ListingMapper.fromRow(Map<String, dynamic>.from(list.first as Map));
    }
    try {
      return _items.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteById(String id) async {
    if (_client != null) {
      await _client.from('listings').delete().eq('id', id);
      return true;
    }
    final index = _items.indexWhere((l) => l.id == id);
    if (index < 0) return false;
    _items.removeAt(index);
    return true;
  }

  /// Delete only when [phone] matches the listing owner phone.
  Future<bool> deleteByPhone({
    required String id,
    required String phone,
  }) async {
    if (PhoneDigits.normalize(phone).isEmpty) return false;

    if (_client != null) {
      try {
        final ok = await _client.rpc(
          'delete_listing_by_phone',
          params: {
            'p_phone': phone.trim(),
            'p_id': id,
          },
        );
        return ok == true;
      } catch (_) {
        return false;
      }
    }

    final index = _items.indexWhere(
      (l) => l.id == id && PhoneDigits.matches(l.contactPhone, phone),
    );
    if (index < 0) return false;
    _items.removeAt(index);
    return true;
  }

  Future<int> countAll() async {
    if (_client != null) {
      final rows = await _client.from('listings').select('id');
      return (rows as List).length;
    }
    return _items.length;
  }

  /// Real directory lines: published driver routes that are not hidden.
  Future<int> countLiveDirectory() async {
    if (_client != null) {
      final rows = await _client
          .from('listings')
          .select('id, is_hidden, status, listing_type');
      var n = 0;
      for (final raw in rows as List) {
        final map = Map<String, dynamic>.from(raw as Map);
        if (map['listing_type'] != 'driver') continue;
        if (map['status'] != 'published') continue;
        if (map['is_hidden'] == true) continue;
        n++;
      }
      return n;
    }
    return _items.where((l) => l.isDriver && l.isLiveInDirectory).length;
  }

  Future<int> countDrivers() async {
    if (_client != null) {
      final rows =
          await _client.from('listings').select('id').eq('listing_type', 'driver');
      return (rows as List).length;
    }
    return _items.where((l) => l.type == ListingType.driver).length;
  }

  Future<int> countRiders() async {
    if (_client != null) {
      final rows =
          await _client.from('listings').select('id').eq('listing_type', 'rider');
      return (rows as List).length;
    }
    return _items.where((l) => l.type == ListingType.rider).length;
  }

  /// Kept for older call sites / tests against the in-memory store.
  int get totalCount => _items.length;
  int get driverCount =>
      _items.where((l) => l.type == ListingType.driver).length;
  int get riderCount => _items.where((l) => l.type == ListingType.rider).length;
}
