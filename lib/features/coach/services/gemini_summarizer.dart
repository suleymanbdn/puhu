import 'dart:convert';
import 'dart:io';

import 'ai_cache.dart';
import 'ai_summarizer.dart';

/// Google Gemini Free Tier üzerinden çalışan AI sağlayıcı (BYOK).
///
/// Kullanıcı kendi ücretsiz Gemini API key'ini Ayarlar'dan yapıştırır
/// (https://aistudio.google.com → "Get API key"). Free tier:
/// - Gemini 1.5 Flash: 15 RPM, 1.500 RPD
///
/// Aynı koç notu/özet 24 saat cache'lenir → bir kullanıcı genelde günde 1-2
/// çağrı yapar → free tier çoğu kullanıcı için yeterli.
class GeminiSummarizer implements AiSummarizer {
  GeminiSummarizer({required this.apiKey, required AiCache cache})
      : _cache = cache;

  final String apiKey;
  final AiCache _cache;

  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  @override
  bool get isAvailable => apiKey.isNotEmpty;

  @override
  String get providerName => 'Google Gemini (ücretsiz)';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  @override
  Future<String?> generateCoachNote(String contextDescription) async {
    if (!isAvailable) return null;

    // Cache key: bağlam + bugün (gün başına maks 1 çağrı).
    final dayKey = _todayKey();
    final cacheKey =
        'coach_note:$dayKey:${contextDescription.hashCode.toUnsigned(32)}';
    final cached = _cache.get(cacheKey);
    if (cached != null) return cached;

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

    // Konu özeti ders+konu adıyla; aynı konu için tek özet.
    final cacheKey =
        'topic_summary:${subjectTitle.toLowerCase()}:${topicName.toLowerCase()}';
    final cached = _cache.get(cacheKey);
    if (cached != null) return cached;

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
    if (result != null) {
      await _cache.put(cacheKey, result, ttl: const Duration(days: 30));
    }
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
        'contents': [
          {
            'parts': [
              {'text': '$prompt\n\nBağlam:\n$context'},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 600,
        },
      });

      final client = HttpClient();
      try {
        final req = await client
            .postUrl(Uri.parse('$_endpoint?key=$apiKey'))
            .timeout(const Duration(seconds: 12));
        req.headers.contentType = ContentType.json;
        req.add(utf8.encode(body));
        final res = await req.close().timeout(const Duration(seconds: 20));
        if (res.statusCode != 200) return null;
        final responseBody = await res.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        final candidates = json['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) return null;
        final content = candidates.first as Map<String, dynamic>?;
        final parts =
            (content?['content'] as Map<String, dynamic>?)?['parts'] as List<dynamic>?;
        if (parts == null || parts.isEmpty) return null;
        final text = (parts.first as Map<String, dynamic>)['text'] as String?;
        return text?.trim();
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
