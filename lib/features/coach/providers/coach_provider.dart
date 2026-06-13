import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/purchase_service.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../mistakes/providers/mistake_provider.dart';
import '../../questions/providers/question_log_provider.dart';
import '../../streak/providers/streak_provider.dart';
import '../../subjects/models/subject.dart';
import '../../subjects/providers/topic_provider.dart';
import '../models/study_plan.dart';
import '../services/algorithmic_coach.dart';
import 'ai_provider.dart';

/// Algoritmik koç raporu — tüm veri sağlayıcıları değiştikçe yeniden hesaplanır.
final coachReportProvider = Provider<CoachReport?>((ref) {
  final profile = ref.watch(examProfileProvider);
  if (profile == null) return null;

  final topics = ref.watch(topicProvider);
  final logs = ref.watch(questionLogProvider);
  final mistakes = ref.watch(mistakeProvider);
  final streak = ref.watch(streakProvider);

  return AlgorithmicCoach().generate(
    profile: profile,
    topics: topics,
    questionLogs: logs,
    mistakes: mistakes,
    streak: streak,
  );
});

/// Bugünkü öneri (hero kart için kısayol).
final todayRecommendationProvider = Provider<TodayRecommendation?>((ref) {
  return ref.watch(coachReportProvider)?.todayRecommendation;
});

/// Anasayfa için otomatik AI koç notu.
///
/// Koç raporundaki gerçekleri AI'a verip 2-3 cümlelik günlük mesaja çevirir.
/// Bağlam günlük olarak sabit tutulur (tarz parametresi sabit) → `GroqSummarizer`
/// cache'i sayesinde günde ~1 gerçek API çağrısı yapılır, gerisi cache'ten gelir;
/// rate limit tüketilmez. AI sağlayıcı yoksa/çevrimdışıysa `null` döner → UI
/// fallback (selam/öneri başlığı) gösterir.
final coachNoteProvider = FutureProvider<String?>((ref) async {
  final report = ref.watch(coachReportProvider);
  if (report == null) return null;

  final summarizer = ref.watch(aiSummarizerProvider);
  if (!summarizer.isAvailable) return null;

  String titleOf(String id) {
    for (final s in Subject.values) {
      if (s.id == id) return s.title;
    }
    return id;
  }

  final weakest = report.weakestSubjectIds.map(titleOf).join(', ');
  final strongest = report.strongestSubjectIds.map(titleOf).join(', ');
  final context = '''
En zayıf 3 ders: $weakest.
En güçlü 3 ders: $strongest.
Bugünkü öneri: ${report.todayRecommendation.title}.
İstenen tarz: motive edici günlük durum özeti
''';

  return summarizer.generateCoachNote(context);
});

/// Plus üyelere özel — AI'ın kişiye özel haftalık strateji notu.
///
/// Kural motorunun ürettiği haftalık plan gerçeklerini (zayıf dersler, sınava
/// kalan süre, günlük hedef) AI'a verir; AI bunları "bu haftaya odaklı somut
/// strateji" koçluğuna çevirir. Gün-gün program ızgarası deterministik kalır,
/// AI sadece kişisel strateji katmanını ekler. Premium değilse / AI yoksa null.
/// Günlük cache'li → ~1 gerçek çağrı/gün.
final weeklyPlanNoteProvider = FutureProvider<String?>((ref) async {
  if (!ref.watch(isPremiumProvider)) return null;

  final report = ref.watch(coachReportProvider);
  final profile = ref.watch(examProfileProvider);
  if (report == null || profile == null) return null;

  final summarizer = ref.watch(aiSummarizerProvider);
  if (!summarizer.isAvailable) return null;

  String titleOf(String id) {
    for (final s in Subject.values) {
      if (s.id == id) return s.title;
    }
    return id;
  }

  final weakest = report.weakestSubjectIds.map(titleOf).join(', ');
  final context = '''
Bu hafta için kısa, kişisel bir çalışma stratejisi koçluğu yaz.
Sınava kalan gün: ${profile.daysUntilExam}.
Günlük hedef: ${profile.dailyTargetHours} saat.
Bu hafta öncelikli (en zayıf) dersler: $weakest.
Bugünkü öneri: ${report.todayRecommendation.title}.
İstenen tarz: bu haftaya odaklı somut strateji — hangi derse ne zaman yüklenmeli.
''';

  return summarizer.generateCoachNote(context);
});
