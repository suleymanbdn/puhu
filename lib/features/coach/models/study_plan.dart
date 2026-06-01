/// Algoritmik koç tarafından üretilen çalışma planı modelleri.
///
/// Tüm tipler immutable saf Dart — Hive veya json gerektirmiyor (çalışma anında
/// hesaplanır, kalıcı saklanmaz). Veri sağlayıcıları (topic, question log,
/// mistake, mock) değiştikçe plan otomatik yenilenir.
library;

/// Bir ders için "dikkat puanı" — yüksek = daha çok ihtiyaç var.
///
/// 0-100 arası normalize edilmiş. Algoritmik koç bu skoru kullanıp haftalık
/// dağılım yapar. Her component'in ayrıca breakdown'ı UI'da gösterilir
/// ("neden bu skor?" şeffaflığı).
class SubjectScore {
  const SubjectScore({
    required this.subjectId,
    required this.totalScore,
    required this.recentNetScore,
    required this.topicCompletionScore,
    required this.mistakeBacklogScore,
    required this.timeNeglectScore,
    required this.recentNet,
    required this.completionRatio,
    required this.pendingMistakes,
    required this.totalMinutesSpent,
  });

  /// Hangi ders? (`Subject.id`)
  final String subjectId;

  /// 0-100 arası genel "dikkat" skoru — yüksek = öncelikli.
  final double totalScore;

  /// Son 7 günlük net skoru (0-25). Düşük net → yüksek skor.
  final double recentNetScore;

  /// Konu tamamlanma oranı (0-25). Az tamamlanmış → yüksek skor.
  final double topicCompletionScore;

  /// Hata sepetinde bekleyenler (0-25). Çok birikmiş → yüksek skor.
  final double mistakeBacklogScore;

  /// Zaman yatırımı (0-25). Az çalışılmış → yüksek skor.
  final double timeNeglectScore;

  // ---- Şeffaflık için ham veriler ----

  /// Son 7 günlük toplam net.
  final double recentNet;

  /// Konuların tamamlanma oranı (0-1).
  final double completionRatio;

  /// Hata sepetinde bekleyen sayısı.
  final int pendingMistakes;

  /// Bu ders için toplam dakika.
  final int totalMinutesSpent;
}

/// Haftanın bir gününe yapılan ders ataması.
class DayAllocation {
  const DayAllocation({
    required this.subjectId,
    required this.minutes,
    required this.suggestedTopicIds,
  });

  /// Hangi ders?
  final String subjectId;

  /// Bu güne ayrılan toplam dakika.
  final int minutes;

  /// O ders içinden önerilen ilk 2 zayıf konu.
  final List<String> suggestedTopicIds;
}

/// Haftalık plan — gün bazında ders atamaları.
class WeeklyPlan {
  const WeeklyPlan({required this.allocations, required this.generatedAt});

  /// Gün başına (DateTime.weekday: 1=Pzt … 7=Paz) atanan dersler.
  final Map<int, List<DayAllocation>> allocations;

  final DateTime generatedAt;
}

/// Bugünkü tek odak önerisi — koç ekranının hero kartı.
class TodayRecommendation {
  const TodayRecommendation({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.minutes,
    required this.actionRoute,
    this.subjectId,
    this.mistakeReview = false,
  });

  final RecommendationKind kind;
  final String title;
  final String subtitle;
  final int minutes;
  final String actionRoute;
  final String? subjectId;
  final bool mistakeReview;
}

enum RecommendationKind {
  /// Hata sepetinde bekleyen var → tekrar oturumu.
  reviewMistakes,

  /// Bugün hâlâ çalışılmadı → pomodoro başlat (streak'i koru).
  startStreak,

  /// Streak güvende → zayıf konuya odaklan.
  focusWeakest,

  /// Hedef sağlamlaşıyor → mevcut ritmi koru.
  maintain,
}

/// Tam koç raporu.
class CoachReport {
  const CoachReport({
    required this.subjectScores,
    required this.weeklyPlan,
    required this.todayRecommendation,
    required this.weakestSubjectIds,
    required this.strongestSubjectIds,
  });

  /// Tüm derslerin skoru (totalScore DESC sıralı = en çok ihtiyaç önce).
  final List<SubjectScore> subjectScores;

  final WeeklyPlan weeklyPlan;

  final TodayRecommendation todayRecommendation;

  /// En zayıf 3 ders ID'si (totalScore yüksek).
  final List<String> weakestSubjectIds;

  /// En güçlü 3 ders ID'si (totalScore düşük).
  final List<String> strongestSubjectIds;
}
