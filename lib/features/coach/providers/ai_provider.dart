import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/settings_provider.dart';
import '../services/ai_cache.dart';
import '../services/ai_rate_limiter.dart';
import '../services/ai_summarizer.dart';
import '../services/gemini_summarizer.dart';
import '../services/groq_summarizer.dart';

/// Bundled Groq API key (compile-time veya release öncesi doldurulur).
///
/// Boş bırakılırsa Groq tier devre dışı — kullanıcı Gemini BYOK'la devam
/// edebilir. Anahtar reverse-engineering ile çıkarılabilir; kötüye kullanım
/// halinde Groq panel'inden revoke + yeni release.
const String _kBundledGroqApiKey = String.fromEnvironment(
  'PUHU_GROQ_KEY',
  defaultValue: '',
);

/// Cihaz başına günlük Groq çağrı limiti.
const int _kGroqDailyMax = 10;

/// Kullanıcının verdiği Gemini API key'i — `_prefsKey` altında saklanır.
const _prefsKey = 'gemini_api_key_v1';

/// Kullanıcının Settings'ten yapıştırdığı key. Boş string = hiç ayarlanmamış.
final geminiApiKeyProvider = StateNotifierProvider<GeminiKeyNotifier, String>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return GeminiKeyNotifier(prefs);
  },
);

class GeminiKeyNotifier extends StateNotifier<String> {
  GeminiKeyNotifier(this._prefs) : super(_prefs.getString(_prefsKey) ?? '');
  final SharedPreferences _prefs;

  Future<void> setKey(String value) async {
    state = value.trim();
    if (state.isEmpty) {
      await _prefs.remove(_prefsKey);
    } else {
      await _prefs.setString(_prefsKey, state);
    }
  }
}

/// AI cache layer.
final aiCacheProvider = Provider<AiCache>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AiCache(prefs);
});

/// Groq için cihaz başına günlük rate limiter.
final aiRateLimiterProvider = Provider<AiRateLimiter>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AiRateLimiter(prefs, dailyMax: _kGroqDailyMax);
});

/// Bundled Groq sağlayıcısı — anahtar boş değilse aktif.
final bundledGroqProvider = Provider<GroqSummarizer?>((ref) {
  if (_kBundledGroqApiKey.isEmpty) return null;
  return GroqSummarizer(
    apiKey: _kBundledGroqApiKey,
    cache: ref.watch(aiCacheProvider),
    rateLimiter: ref.watch(aiRateLimiterProvider),
  );
});

/// Hangi tier aktif — UI badge ve "kalan hak" göstermek için kullanılır.
enum AiTier {
  none, // hiçbir sağlayıcı yok
  bundledGroq, // ücretsiz puhu sağlayıcısı aktif
  userGemini, // kullanıcı kendi Gemini key'ini girmiş
}

/// Şu an aktif tier'i seçer.
///
/// Öncelik: kullanıcı Gemini key girdiyse o (sınırsız) → yoksa bundled
/// Groq → yoksa NoOp.
final activeAiTierProvider = Provider<AiTier>((ref) {
  final geminiKey = ref.watch(geminiApiKeyProvider);
  if (geminiKey.isNotEmpty) return AiTier.userGemini;
  if (ref.watch(bundledGroqProvider) != null) return AiTier.bundledGroq;
  return AiTier.none;
});

/// Aktif AI summarizer — tier'a göre seçilir.
final aiSummarizerProvider = Provider<AiSummarizer>((ref) {
  final tier = ref.watch(activeAiTierProvider);
  switch (tier) {
    case AiTier.userGemini:
      final cache = ref.watch(aiCacheProvider);
      return GeminiSummarizer(
        apiKey: ref.watch(geminiApiKeyProvider),
        cache: cache,
      );
    case AiTier.bundledGroq:
      return ref.watch(bundledGroqProvider)!;
    case AiTier.none:
      return const NoOpAiSummarizer();
  }
});

/// Bundled Groq için bugün kalan kullanım hakkı (UI gösterimi).
/// Kullanıcı kendi key'ini girmişse -1 döner = sınırsız.
final aiRemainingTodayProvider = Provider<int>((ref) {
  final tier = ref.watch(activeAiTierProvider);
  if (tier == AiTier.userGemini) return -1;
  if (tier == AiTier.bundledGroq) {
    return ref.watch(aiRateLimiterProvider).remainingToday;
  }
  return 0;
});
