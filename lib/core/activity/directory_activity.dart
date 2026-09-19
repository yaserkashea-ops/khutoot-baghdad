import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Counts real directory link/app opens for public activity social proof.
abstract final class DirectoryActivity {
  static const _cachedCountKey = 'khutoot_dir_open_count_cache';

  static int? _memoryCount;
  static bool _recordedThisProcess = false;

  /// Last known open count (memory → prefs). Safe for UI before network returns.
  static int get cachedCount => _memoryCount ?? 0;

  static Future<int> loadCachedCount() async {
    if (_memoryCount != null) return _memoryCount!;
    try {
      final prefs = await SharedPreferences.getInstance();
      _memoryCount = prefs.getInt(_cachedCountKey) ?? 0;
    } catch (_) {
      _memoryCount = 0;
    }
    return _memoryCount!;
  }

  /// Record one open for this page/app load, then refresh the public total.
  /// Never await on the critical boot path — call via `unawaited`.
  static Future<int> syncOnLaunch() async {
    await loadCachedCount();
    if (!SupabaseConfig.isConfigured) return cachedCount;

    try {
      final prefs = await SharedPreferences.getInstance();
      final client = Supabase.instance.client;

      if (!_recordedThisProcess) {
        final raw = await client.rpc('record_directory_open');
        final n = _asInt(raw);
        _recordedThisProcess = true;
        if (n != null) {
          _memoryCount = n;
          await prefs.setInt(_cachedCountKey, n);
          return n;
        }
      }

      final raw = await client.rpc('get_directory_open_count');
      final n = _asInt(raw);
      if (n != null) {
        _memoryCount = n;
        await prefs.setInt(_cachedCountKey, n);
        return n;
      }
    } catch (_) {
      // RPC/table may not exist yet — keep cache.
    }
    return cachedCount;
  }

  static int? _asInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// Formatted like global apps: "26,978 مستخدم".
  static String labelFor(int count) {
    final n = count < 0 ? 0 : count;
    return '${formatCount(n)} مستخدم';
  }

  /// Thousand separators: 26978 → "26,978".
  static String formatCount(int count) {
    final n = count < 0 ? 0 : count;
    final raw = '$n';
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final fromEnd = raw.length - i;
      buf.write(raw[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}
