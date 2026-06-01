import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/purchase_service.dart';
import '../../../core/services/settings_provider.dart';
import '../services/streak_freeze_service.dart';

/// Streak Freeze durumu — view'ler bunu izler.
final streakFreezeProvider =
    StateNotifierProvider<StreakFreezeNotifier, StreakFreezeData>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StreakFreezeNotifier(StreakFreezeService(prefs));
});

/// Bu ay kalan token sayısı (premium durumuna duyarlı).
final remainingFreezeTokensProvider = Provider<int>((ref) {
  final data = ref.watch(streakFreezeProvider);
  final isPremium = ref.watch(isPremiumProvider);
  return data.remainingTokens(isPremium: isPremium);
});

/// Aylık maksimum token kapasitesi.
final maxFreezeTokensProvider = Provider<int>((ref) {
  final isPremium = ref.watch(isPremiumProvider);
  return StreakFreezeData.maxTokens(isPremium: isPremium);
});

class StreakFreezeNotifier extends StateNotifier<StreakFreezeData> {
  StreakFreezeNotifier(this._service) : super(_service.read());

  final StreakFreezeService _service;

  /// Bir günü dondurmayı dener. Token kalmadıysa veya gün zaten donmuşsa
  /// `false` döner. Aksi halde token'ı tüketir, günü kaydeder, `true` döner.
  Future<bool> freezeDay(DateTime day, {required bool isPremium}) async {
    final key = StreakFreezeService.dayKey(day);
    if (state.frozenDays.contains(key)) return false;
    final remaining = state.remainingTokens(isPremium: isPremium);
    if (remaining <= 0) return false;

    final next = state.copyWith(
      tokensUsed: state.tokensUsed + 1,
      frozenDays: {...state.frozenDays, key},
    );
    await _service.write(next);
    state = next;
    return true;
  }

  /// Bir günün donmuş olup olmadığını kontrol eder.
  bool isFrozen(DateTime day) =>
      state.frozenDays.contains(StreakFreezeService.dayKey(day));
}
