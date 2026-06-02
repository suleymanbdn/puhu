/// AI yazı üretici soyut katman.
///
/// Bu abstraksiyon birden fazla AI sağlayıcı (Gemini, Apple Foundation
/// Models, OpenAI vs.) arkasına aynı arayüz koyar — koç ekranı sağlayıcıyı
/// bilmeden sadece [generateCoachNote] / [summarizeTopic] çağırır.
///
/// Sprint 4c: Gemini implementasyonu (BYOK).
/// Sprint 4b: Apple Foundation Models (iOS 18+, on-device).
abstract class AiSummarizer {
  /// Sağlayıcı şu an çağrı yapabilir mi? (API key ayarlı, ağ var vb.)
  bool get isAvailable;

  /// Kullanıcı arayüzünde gösterilecek sağlayıcı adı.
  String get providerName;

  /// Koç önerilerinden 2-3 cümlelik motivasyonel/yönlendirici metin.
  ///
  /// [contextDescription] içinde sağlayıcıya verilecek bağlam (zayıf
  /// dersler, son durum vs.) düz metinle aktarılır — burada üst katman
  /// koç raporunu serialize eder.
  Future<String?> generateCoachNote(String contextDescription);

  /// Belirli bir konunun 200 kelimelik özeti + 3 madde formül/kavram.
  Future<String?> summarizeTopic({
    required String subjectTitle,
    required String topicName,
  });
}

/// Hiçbir şey yapmayan implementasyon — kullanıcı sağlayıcı seçmediğinde
/// veya provider yapılandırılmadığında dönen no-op.
class NoOpAiSummarizer implements AiSummarizer {
  const NoOpAiSummarizer();

  @override
  bool get isAvailable => false;

  @override
  String get providerName => 'Yapılandırılmadı';

  @override
  Future<String?> generateCoachNote(String contextDescription) async => null;

  @override
  Future<String?> summarizeTopic({
    required String subjectTitle,
    required String topicName,
  }) async =>
      null;
}
