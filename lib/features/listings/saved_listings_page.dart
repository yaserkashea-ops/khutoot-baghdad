import 'package:flutter/material.dart';

import '../../core/listings/publish_draft_store.dart';
import '../../core/models/listing.dart';
import '../../core/theme/app_colors.dart';
import '../../data/listings_repository.dart';
import 'widgets/listing_card.dart';

class SavedListingsPage extends StatefulWidget {
  const SavedListingsPage({super.key});

  @override
  State<SavedListingsPage> createState() => _SavedListingsPageState();
}

class _SavedListingsPageState extends State<SavedListingsPage> {
  List<Listing> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    PublishDraftStore.savedRevision.addListener(_onSaved);
    _load();
  }

  void _onSaved() => _load();

  @override
  void dispose() {
    PublishDraftStore.savedRevision.removeListener(_onSaved);
    super.dispose();
  }

  Future<void> _load() async {
    final ids = await PublishDraftStore.savedIds();
    final all = await ListingsRepository.shared.fetchAll();
    if (!mounted) return;
    setState(() {
      _items = all.where((l) => ids.contains(l.id)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('المحفوظات')),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : _items.isEmpty
              ? const Center(child: Text('لا محفوظات بعد'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => ListingCard(listing: _items[i]),
                ),
    );
  }
}
