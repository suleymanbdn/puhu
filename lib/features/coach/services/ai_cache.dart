import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// AI yanıtları için basit cache — gereksiz API çağrısı yapmaz.
///
/// Anahtar başına TTL (saniye) ile yazar; süresi dolan kayıtları okumaz.
/// JSON formatı:
/// ```
/// { "key1": { "v": "value", "exp": 1719999999 }, ... }
/// ```
class AiCache {
  AiCache(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'ai_cache_v1';

  Map<String, dynamic> _read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(Map<String, dynamic> data) =>
      _prefs.setString(_key, jsonEncode(data));

  /// Cache'ten oku — yoksa veya süresi dolduysa null.
  String? get(String key) {
    final data = _read();
    final entry = data[key];
    if (entry is! Map<String, dynamic>) return null;
    final exp = entry['exp'];
    final v = entry['v'];
    if (exp is! int || v is! String) return null;
    if (DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp) return null;
    return v;
  }

  /// Cache'e yaz (TTL saniye cinsinden — varsayılan 24 saat).
  Future<void> put(String key, String value,
      {Duration ttl = const Duration(hours: 24)}) async {
    final data = _read();
    final exp =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + ttl.inSeconds;
    data[key] = {'v': value, 'exp': exp};
    await _write(data);
  }

  /// Tüm cache'i temizle.
  Future<void> clear() => _prefs.remove(_key);
}
