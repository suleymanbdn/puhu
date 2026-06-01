import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exam/providers/exam_profile_provider.dart';
import '../../mistakes/providers/mistake_provider.dart';
import '../../questions/providers/question_log_provider.dart';
import '../../streak/providers/streak_provider.dart';
import '../../subjects/providers/topic_provider.dart';
import '../models/study_plan.dart';
import '../services/algorithmic_coach.dart';

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
