/// Supabase project credentials for خطوط بغداد.
///
/// Fill [url] and [anonKey] from:
/// Supabase Dashboard → Project Settings → API
///
/// Or pass at build time:
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _urlFallback,
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _anonKeyFallback,
  );

  /// Paste project URL here (https://xxxx.supabase.co).
  static const _urlFallback = '';

  /// Paste the anon / public key here.
  static const _anonKeyFallback = '';

  static bool get isConfigured =>
      url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}
