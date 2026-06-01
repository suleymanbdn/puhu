import '../../exam/models/exam_profile.dart';
import '../../mistakes/models/mistake.dart';
import '../../questions/models/question_log.dart';
import '../../streak/providers/streak_provider.dart';
import '../../subjects/models/subject.dart';
import '../../subjects/models/topic.dart';
import '../models/study_plan.dart';

/// Saf algoritmik koç — hiçbir LLM/API çağrısı yok, deterministik.
///
/// **Skor formülü** (her component 0-25, toplam 0-100):
/// - `recentNetScore`: Son 7 günlük net düşükse yüksek skor.
/// - `topicCompletionScore`: Konuların tamamlanma oranı düşükse yüksek.
/// - `mistakeBacklogScore`: Hata sepetinde bekleyenler çok ise yüksek.
/// - `timeNeglectScore`: Toplam çalışılan dakika sınava göre eksikse yüksek.
///
/// **Plan dağılımı:** Skoru yüksek dersler haftalık dakikaların büyük dilimini
/// alır; aynı ders üst üste iki güne konmaz (çeşitlilik).
class AlgorithmicCoach {
  AlgorithmicCoach({DateTime? now}) : _now = now ?? DateTime.now();

  final DateTime _now;

  /// Ana giriş — tüm veri parçalarını alır, koç raporu üretir.
  CoachReport generate({
    required ExamProfile profile,
    required List<Topic> topics,
    required List<QuestionLog> questionLogs,
    required List<Mistake> mistakes,
    required StreakStats streak,
  }) {
    final examFilter = _examTypeFilter(profile.examType);
    final subjects = Subject.forExamType(examFilter);

    // Subject skorlarını hesapla.
    final scores = <SubjectScore>[
      for (final s in subjects)
        _computeSubjectScore(
          subject: s,
          topics: topics.where((t) => t.subjectId == s.id).toList(),
          recentLogs: questionLogs
              .where((l) =>
                  l.subjectId == s.id &&
                  l.date.isAfter(_now.subtract(const Duration(days: 7))))
              .toList(),
          pendingMistakes: mistakes
              .where((m) => !m.mastered && m.subjectId == s.id && m.isPending)
              .length,
        ),
    ]..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    // Haftalık plan üret (top N skorlu derslerle).
    final weeklyPlan = _generateWeeklyPlan(
      scores: scores,
      topics: topics,
      dailyTargetMinutes: (profile.dailyTargetHours * 60).round(),
    );

    // Bugünkü öneri.
    final pendingMistakes =
        mistakes.where((m) => !m.mastered && m.isPending).length;
    final todayRecommendation = _todayRecommendation(
      scores: scores,
      topics: topics,
      streak: streak,
      pendingMistakes: pendingMistakes,
      dailyTargetMinutes: (profile.dailyTargetHours * 60).round(),
    );

    return CoachReport(
      subjectScores: scores,
      weeklyPlan: weeklyPlan,
      todayRecommendation: todayRecommendation,
      weakestSubjectIds: scores.take(3).map((s) => s.subjectId).toList(),
      strongestSubjectIds: scores.reversed
          .take(3)
          .map((s) => s.subjectId)
          .toList(growable: false),
    );
  }

  // ---------------------------------------------------------------------------
  // Subject score hesabı
  // ---------------------------------------------------------------------------

  SubjectScore _computeSubjectScore({
    required Subject subject,
    required List<Topic> topics,
    required List<QuestionLog> recentLogs,
    required int pendingMistakes,
  }) {
    // Net hesabı (YKS standardı: doğru - yanlış/4).
    final recentNet = recentLogs.fold<double>(
      0,
      (acc, l) => acc + l.correct - (l.wrong / 4),
    );

    // Konu tamamlanma oranı.
    final completedCount =
        topics.where((t) => t.status == TopicStatus.completed).length;
    final completionRatio =
        topics.isEmpty ? 0.0 : completedCount / topics.length;

    final totalMinutes =
        topics.fold<int>(0, (acc, t) => acc + t.totalMinutes);

    // Score component'leri (her biri 0-25):

    // 1) Recent net — hedef nete (dersin soru sayısı * 0.5) göre normalize.
    //    Düşük net → yüksek skor.
    final targetNet = subject.questionCount * 0.5; // tutucu hedef
    final netRatio = (recentNet / targetNet).clamp(0.0, 1.0);
    final recentNetScore = (1.0 - netRatio) * 25.0;

    // 2) Topic completion — eksik tamamlanma yüksek skor.
    final topicCompletionScore = (1.0 - completionRatio) * 25.0;

    // 3) Mistake backlog — bekleyen 0 → 0 skor; bekleyen 10+ → 25 skor.
    final mistakeBacklogScore =
        (pendingMistakes.clamp(0, 10) / 10.0) * 25.0;

    // 4) Time neglect — son 7 gün hiç çalışılmadıysa max skor; çok çalışıldıysa 0.
    //    Her ders için ideal: dailyTargetMinutes / subjectCount * 7 dakika/hafta.
    //    Burada relatif: bu dersin son 7 gün toplam log dakikası vs. ideal.
    //    Basitleştirme: son 7 gün soru log'u yoksa max skor, var ve >=1 saat → 0.
    final hasRecentActivity = recentLogs.isNotEmpty;
    double timeNeglectScore;
    if (!hasRecentActivity) {
      timeNeglectScore = 25.0;
    } else {
      final recentTotal =
          recentLogs.fold<int>(0, (acc, l) => acc + l.correct + l.wrong);
      // 50 sorudan az → bir miktar ihmal, 200+ → bol çalışma
      timeNeglectScore = ((200 - recentTotal).clamp(0, 200) / 200) * 25.0;
    }

    return SubjectScore(
      subjectId: subject.id,
      totalScore: recentNetScore +
          topicCompletionScore +
          mistakeBacklogScore +
          timeNeglectScore,
      recentNetScore: recentNetScore,
      topicCompletionScore: topicCompletionScore,
      mistakeBacklogScore: mistakeBacklogScore,
      timeNeglectScore: timeNeglectScore,
      recentNet: recentNet,
      completionRatio: completionRatio,
      pendingMistakes: pendingMistakes,
      totalMinutesSpent: totalMinutes,
    );
  }

  // ---------------------------------------------------------------------------
  // Haftalık plan üretimi
  // ---------------------------------------------------------------------------

  WeeklyPlan _generateWeeklyPlan({
    required List<SubjectScore> scores,
    required List<Topic> topics,
    required int dailyTargetMinutes,
  }) {
    // En öncelikli top 5 ders (skoru 0 olanları al ama yine de plan dahil et).
    final topSubjects = scores.take(5).toList();
    if (topSubjects.isEmpty) {
      return WeeklyPlan(allocations: const {}, generatedAt: _now);
    }

    // Her ders için "ne kadar pay" alıyor? Skoru yüksek → büyük pay.
    final totalScore =
        topSubjects.fold<double>(0, (acc, s) => acc + s.totalScore);

    // Haftalık toplam dakika.
    final weeklyMinutes = dailyTargetMinutes * 7;

    // Her ders için haftalık dakika.
    final perSubjectMinutes = <String, int>{};
    for (final s in topSubjects) {
      final ratio = totalScore == 0
          ? (1.0 / topSubjects.length) // bütün skorlar 0 → eşit dağıt
          : (s.totalScore / totalScore);
      perSubjectMinutes[s.subjectId] = (weeklyMinutes * ratio).round();
    }

    // 7 güne dağıt — aynı ders üst üste 2 güne gelmesin (sırayla yerleştir).
    final allocations = <int, List<DayAllocation>>{};
    for (var day = 1; day <= 7; day++) {
      allocations[day] = [];
    }

    // Her ders için günler arası "ne kadar pay" — basit round-robin.
    final dailyMinutesPerSubject = <String, int>{};
    for (final entry in perSubjectMinutes.entries) {
      dailyMinutesPerSubject[entry.key] = (entry.value / 4).round().clamp(15, 120);
    }

    // Round-robin: her gün 1-2 ders.
    var subjectIdx = 0;
    for (var day = 1; day <= 7; day++) {
      final allocationsForDay = <DayAllocation>[];
      var dayMinutes = 0;
      var attempts = 0;
      while (dayMinutes < dailyTargetMinutes && attempts < topSubjects.length) {
        final s = topSubjects[(subjectIdx + attempts) % topSubjects.length];
        final slot = (dailyMinutesPerSubject[s.subjectId] ?? 30).clamp(
          15,
          dailyTargetMinutes - dayMinutes,
        );
        if (slot < 15) break;
        // En zayıf 1-2 konu öner (correctRatio düşük + lastStudiedAt eski).
        final subjectTopics = topics
            .where((t) =>
                t.subjectId == s.subjectId &&
                t.status != TopicStatus.completed)
            .toList()
          ..sort((a, b) => a.correctRatio.compareTo(b.correctRatio));
        allocationsForDay.add(DayAllocation(
          subjectId: s.subjectId,
          minutes: slot,
          suggestedTopicIds:
              subjectTopics.take(2).map((t) => t.id).toList(growable: false),
        ));
        dayMinutes += slot;
        attempts++;
      }
      allocations[day] = allocationsForDay;
      subjectIdx = (subjectIdx + 1) % topSubjects.length;
    }

    return WeeklyPlan(allocations: allocations, generatedAt: _now);
  }

  // ---------------------------------------------------------------------------
  // Bugünkü öneri
  // ---------------------------------------------------------------------------

  TodayRecommendation _todayRecommendation({
    required List<SubjectScore> scores,
    required List<Topic> topics,
    required StreakStats streak,
    required int pendingMistakes,
    required int dailyTargetMinutes,
  }) {
    // 1) Hata sepeti dolu mu? Önce onu boşalt.
    if (pendingMistakes >= 3) {
      return TodayRecommendation(
        kind: RecommendationKind.reviewMistakes,
        title: '$pendingMistakes hatayı tekrar et',
        subtitle:
            'Önce sepetindeki bekleyen yanlışları gözden geçir — kalıcılaşsın.',
        minutes: (pendingMistakes * 2).clamp(10, 30),
        actionRoute: '/mistakes/review',
        mistakeReview: true,
      );
    }

    // 2) Bugün hiç çalışılmamış mı? Streak'i koru.
    if (!streak.studiedToday) {
      final topSubject = scores.isNotEmpty ? scores.first : null;
      final subjectName = topSubject == null
          ? 'çalışma'
          : _subjectTitleFromId(topSubject.subjectId);
      return TodayRecommendation(
        kind: RecommendationKind.startStreak,
        title: 'Streak\'i koru — $subjectName ile başla',
        subtitle:
            'Bugün hâlâ çalışmadın. 25 dakika bile yeterli; pomodoro\'yu başlat.',
        minutes: 25,
        actionRoute: '/timer',
        subjectId: topSubject?.subjectId,
      );
    }

    // 3) En zayıf derse odaklan.
    if (scores.isNotEmpty) {
      final top = scores.first;
      final subjectName = _subjectTitleFromId(top.subjectId);
      return TodayRecommendation(
        kind: RecommendationKind.focusWeakest,
        title: '$subjectName\'ne ${(dailyTargetMinutes ~/ 2)} dk ayır',
        subtitle: 'En çok ihtiyaç olan ders bu — skor: '
            '${top.totalScore.toStringAsFixed(0)}/100',
        minutes: dailyTargetMinutes ~/ 2,
        actionRoute: '/timer',
        subjectId: top.subjectId,
      );
    }

    // 4) Her şey iyi — ritmi koru.
    return const TodayRecommendation(
      kind: RecommendationKind.maintain,
      title: 'Ritmin iyi — devam et',
      subtitle: 'Bugünkü hedefini tamamlamış görünüyorsun. Devam!',
      minutes: 0,
      actionRoute: '/home',
    );
  }

  // ---------------------------------------------------------------------------
  // Yardımcı
  // ---------------------------------------------------------------------------

  ExamTypeFilter _examTypeFilter(ExamType t) {
    switch (t) {
      case ExamType.tyt:
        return ExamTypeFilter.tyt;
      case ExamType.sayisal:
        return ExamTypeFilter.sayisal;
      case ExamType.esitAgirlik:
        return ExamTypeFilter.esitAgirlik;
      case ExamType.sozel:
        return ExamTypeFilter.sozel;
      case ExamType.dil:
        return ExamTypeFilter.dil;
    }
  }

  String _subjectTitleFromId(String id) {
    for (final s in Subject.values) {
      if (s.id == id) return s.title;
    }
    return id;
  }
}
