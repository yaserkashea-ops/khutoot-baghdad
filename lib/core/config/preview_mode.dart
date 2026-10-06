/// Isolated preview build. Compile with `--dart-define=PREVIEW_MODE=true`.
///
/// Never talks to production Supabase. Listings stay in-memory for this process.
abstract final class PreviewMode {
  static const enabled = bool.fromEnvironment('PREVIEW_MODE');

  static const badgeLabel = 'نسخة معاينة تجريبية';

  /// In-memory publisher account used only while [enabled] is true.
  static const accountId = 'preview-account';
  static const sessionToken = 'preview-local-session';
}
