import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cihaz başına günlük AI çağrı sayacı.
///
/// Bundled (ücretsiz) sağlayıcı için. Kullanıcı kendi key'ini girdiğinde
/// (örn. Gemini BYOK) bu sayaç devre dışı kalır.
///
/// Format: SharedPreferences'a JSON yazar: `{"date":"2026-06-10","count":3}`
/// Gün değiştiğinde sayaç otomatik resetlenir.
class AiRateLimiter {
  AiRateLimiter(this._prefs, {this.dailyMax = 10});

  final SharedPreferences _prefs;
  final int dailyMax;

  static const _key = 'ai_rate_limit_v1';

  /// Bugün kalan kullanım hakkı. dailyMax — bugün kullanılan.
  int get remainingToday {
    final state = _read();
    return (dailyMax - state.count).clamp(0, dailyMax);
  }

  /// Bugün kullanım var mı?
  bool get canConsume => remainingToday > 0;

  /// Bir çağrı tüket. true dönerse çağrı yapılabilir.
  Future<bool> consume() async {
    final state = _read();
    if (state.count >= dailyMax) return false;
    await _write(_State(date: _todayKey(), count: state.count + 1));
    return true;
  }

  _State _read() {
    final raw = _prefs.getString(_key);
    final today = _todayKey();
    if (raw == null) return _State(date: today, count: 0);
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final date = j['date'] as String? ?? '';
      final count = (j['count'] as num?)?.toInt() ?? 0;
      if (date != today) return _State(date: today, count: 0);
      return _State(date: date, count: count);
    } catch (_) {
      return _State(date: today, count: 0);
    }
  }

  Future<void> _write(_State s) =>
      _prefs.setString(_key, jsonEncode({'date': s.date, 'count': s.count}));

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}

class _State {
  final String date;
  final int count;
  _State({required this.date, required this.count});
}
