import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Streak Freeze (donma) durumunu kalıcı saklar.
///
/// Veri modeli (SharedPreferences JSON):
/// ```json
/// {
///   "monthAnchor": "2026-05",
///   "tokensUsed": 1,
///   "frozenDays": ["2026-05-23", "2026-06-02"]
/// }
/// ```
///
/// Token'lar her ay 1'inde sıfırlanır (`monthAnchor` mevcut aydan farklıysa
/// `tokensUsed` 0'a döner). Aylık maksimum:
/// - Ücretsiz: 2 token
/// - Premium: 5 token
class StreakFreezeService {
  StreakFreezeService(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'streak_freeze_v1';

  /// Mevcut ayın anchor'ı (YYYY-MM).
  static String _monthOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  /// Gün anahtarı (YYYY-MM-DD).
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// SharedPreferences'tan oku → güncel ayla harmanla → modeli döner.
  StreakFreezeData read() {
    final raw = _prefs.getString(_key);
    final now = DateTime.now();
    final currentMonth = _monthOf(now);

    if (raw == null) {
      return StreakFreezeData(
        monthAnchor: currentMonth,
        tokensUsed: 0,
        frozenDays: const {},
      );
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final storedMonth = json['monthAnchor'] as String? ?? currentMonth;
      final tokensUsed = json['tokensUsed'] as int? ?? 0;
      final frozenList = (json['frozenDays'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toSet();

      // Ay değişmişse token sayacı sıfırla (frozenDays geçmiş için kalsın).
      if (storedMonth != currentMonth) {
        return StreakFreezeData(
          monthAnchor: currentMonth,
          tokensUsed: 0,
          frozenDays: frozenList,
        );
      }
      return StreakFreezeData(
        monthAnchor: storedMonth,
        tokensUsed: tokensUsed,
        frozenDays: frozenList,
      );
    } catch (_) {
      // Bozuk veri → fresh start.
      return StreakFreezeData(
        monthAnchor: currentMonth,
        tokensUsed: 0,
        frozenDays: const {},
      );
    }
  }

  /// Tüm modeli yaz.
  Future<void> write(StreakFreezeData data) async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'monthAnchor': data.monthAnchor,
        'tokensUsed': data.tokensUsed,
        'frozenDays': data.frozenDays.toList(),
      }),
    );
  }
}

/// Streak Freeze veri modeli — immutable.
class StreakFreezeData {
  const StreakFreezeData({
    required this.monthAnchor,
    required this.tokensUsed,
    required this.frozenDays,
  });

  /// Şu anki ay (YYYY-MM).
  final String monthAnchor;

  /// Bu ay tüketilen token sayısı.
  final int tokensUsed;

  /// Donmuş günler (YYYY-MM-DD string seti) — streak hesabında bu günler
  /// "çalışılmış" sayılır.
  final Set<String> frozenDays;

  StreakFreezeData copyWith({
    int? tokensUsed,
    Set<String>? frozenDays,
  }) =>
      StreakFreezeData(
        monthAnchor: monthAnchor,
        tokensUsed: tokensUsed ?? this.tokensUsed,
        frozenDays: frozenDays ?? this.frozenDays,
      );

  /// Premium durumuna göre aylık maksimum token kapasitesi.
  static int maxTokens({required bool isPremium}) => isPremium ? 5 : 2;

  /// Bu ay kalan kullanılabilir token sayısı.
  int remainingTokens({required bool isPremium}) {
    final max = maxTokens(isPremium: isPremium);
    final remaining = max - tokensUsed;
    return remaining < 0 ? 0 : remaining;
  }
}
