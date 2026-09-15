import 'dart:async';

/// Completes once theme + Supabase (and optional admin auth) finish warming.
abstract final class AppBootstrap {
  static final Completer<void> _ready = Completer<void>();

  static Future<void> get ready => _ready.future;

  static void markReady() {
    if (!_ready.isCompleted) _ready.complete();
  }
}
