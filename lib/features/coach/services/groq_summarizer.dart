import 'dart:convert';
import 'dart:io';

import 'ai_cache.dart';
import 'ai_rate_limiter.dart';
import 'ai_summarizer.dart';

/// Groq Cloud — ücretsiz Llama 3.3 70B ile çalışan AI sağlayıcı.
///
/// Bu sağlayıcı uygulamayla birlikte gelir (bundled key). Kullanıcı
/// hiçbir şey ayarlamadan AI koç notu/konu özeti alabilir.
///
/// **Kısıtlar:**
/// - Cihaz başına günde [AiRateLimiter.dailyMax] istek
/// - Cache hit'lerde rate limit tüketilmez
/// - Premium kullanıcılar kendi Gemini key'ini kullanırsa rate limit yok
///
/// **Free tier (Groq):**
/// - 30 RPM, 14400 RPD (Llama 3.3 70B)
/// - Kredi kartı istenmez
///
/// **Güvenlik notu:** Bundled key reverse-engineering ile çıkartılabilir.
/// Riskli kullanım tespit edilirse Groq'tan key revoke + yeni release.
class GroqSummarizer implements AiSummarizer {
  GroqSummarizer({
    required this.apiKey,
    required AiCache cache,
    required AiRateLimiter rateLimiter,
  })  : _cache = cache,
        _rateLimiter = rateLimiter;

  final String apiKey;
  final AiCache _cache;
  final AiRateLimiter _rateLimiter;

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';

  @override
  bool get isAvailable => apiKey.isNotEmpty;

  @override
  String get providerName => 'Puhu AI (ücretsiz)';

  int get remainingToday => _rateLimiter.remainingToday;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  @override
  Future<String?> generateCoachNote(String contextDescription) async {
    if (!isAvailable) return null;

    final dayKey = _todayKey();
    final cacheKey =
        'coach_note:$dayKey:${contextDescription.hashCode.toUnsigned(32)}';
    final cached = _cache.get(cacheKey);
    if (cached != null) return cached;

    if (!await _rateLimiter.consume()) return null;

    const prompt = '''
Sen bir YKS (Türkiye üniversite sınavı) çalışma koçusun. Aşağıdaki öğrencinin
güncel durumu için 2-3 cümlelik bir motivasyon notu yaz. Net, doğrudan,
samimi ol; aşırı duygusal olma. Türkçe yaz, emoji kullanma.
''';
    final result = await _generate(prompt: prompt, context: contextDescription);
    if (result != null) await _cache.put(cacheKey, result);
    return result;
  }

  @override
  Future<String?> summarizeTopic({
    required String subjectTitle,
    required String topicName,
  }) async {
    if (!isAvailable) return null;

    final cacheKey =
        'topic_summary:${subjectTitle.toLowerCase()}:${topicName.toLowerCase()}';
    final cached = _cache.get(cacheKey);
    if (cached != null) return cached;

    if (!await _rateLimiter.consume()) return null;

    const prompt = '''
Aşağıda verilen YKS dersi ve konusu için kısa bir özet hazırla:
- Önce 2-3 cümlelik genel anlatım
- Sonra "Bilmen gereken 3 şey" başlığıyla 3 madde
- Madde başlarında • kullan
- Türkçe ve sade dil, 200 kelimeyi aşma
- Yanlış bilgi vermektense "kısa tut" tercih et
''';
    final result = await _generate(
      prompt: prompt,
      context: 'Ders: $subjectTitle\nKonu: $topicName',
    );
    if (result != null) await _cache.put(cacheKey, result);
    return result;
  }

  // ---------------------------------------------------------------------------
  // HTTP
  // ---------------------------------------------------------------------------

  Future<String?> _generate({
    required String prompt,
    required String context,
  }) async {
    try {
      final body = jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': '$prompt\n\nBağlam:\n$context',
          },
        ],
        'temperature': 0.7,
        'max_tokens': 600,
      });

      final client = HttpClient();
      try {
        final req = await client
            .postUrl(Uri.parse(_endpoint))
            .timeout(const Duration(seconds: 12));
        req.headers.contentType = ContentType.json;
        req.headers.add(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
        req.add(utf8.encode(body));
        final res = await req.close().timeout(const Duration(seconds: 20));
        if (res.statusCode != 200) return null;
        final responseBody = await res.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        final choices = json['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) return null;
        final message =
            (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        return content?.trim();
      } finally {
        client.close();
      }
    } catch (_) {
      return null;
    }
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
