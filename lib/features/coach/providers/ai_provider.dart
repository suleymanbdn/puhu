import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/settings_provider.dart';
import '../services/ai_cache.dart';
import '../services/ai_summarizer.dart';
import '../services/gemini_summarizer.dart';

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

/// Aktif AI summarizer — kullanıcı key girmediyse no-op döner.
///
/// Sprint 4b'de iOS 18+ Apple Foundation Models implementasyonu burada
/// öncelikli sıraya alınacak; o zaman bu provider iOS'ta önce native'i
/// dener, başaramazsa Gemini fallback'e gider.
final aiSummarizerProvider = Provider<AiSummarizer>((ref) {
  final apiKey = ref.watch(geminiApiKeyProvider);
  if (apiKey.isEmpty) return const NoOpAiSummarizer();
  final cache = ref.watch(aiCacheProvider);
  return GeminiSummarizer(apiKey: apiKey, cache: cache);
});
