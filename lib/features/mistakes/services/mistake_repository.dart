import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mistake.dart';

/// Hata Sepeti kalıcı katmanı — JSON listesi olarak SharedPreferences'ta
/// saklar.
///
/// Veri seti küçük (kullanıcı başına yüzlerce satır). Hive overhead'i için
/// build_runner gerektirmemek adına bu basit yaklaşım seçildi. Gelecekte
/// koleksiyon büyürse Hive'a geçiş kolay (model JSON serializable).
class MistakeRepository {
  MistakeRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'mistakes_v1';

  List<Mistake> readAll() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Mistake.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeAll(List<Mistake> mistakes) async {
    final encoded =
        jsonEncode(mistakes.map((m) => m.toJson()).toList(growable: false));
    await _prefs.setString(_key, encoded);
  }
}
