import 'package:flutter/foundation.dart';

/// Intent from the home page to open the public directory with a search.
class DirectoryBrowseQuery {
  const DirectoryBrowseQuery({
    this.riders = false,
    this.area = '',
    this.destination = '',
    this.timeSlot,
  });

  final bool riders;
  final String area;
  final String destination;

  /// `صباحي` / `مسائي`. Null defaults to morning in the directory.
  final String? timeSlot;
}

abstract final class DirectoryBrowse {
  static final ValueNotifier<DirectoryBrowseQuery?> query =
      ValueNotifier<DirectoryBrowseQuery?>(null);

  static void open(DirectoryBrowseQuery next) {
    query.value = next;
  }
}
