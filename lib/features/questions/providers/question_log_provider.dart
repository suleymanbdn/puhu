import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../subjects/models/subject.dart';
import '../../subjects/providers/topic_provider.dart';
import '../models/question_log.dart';

class QuestionLogNotifier extends StateNotifier<List<QuestionLog>> {
  QuestionLogNotifier(this.ref) : super([]) {
    _load();
  }

  final Ref ref;
  static const _uuid = Uuid();

  Box<QuestionLog> get _box =>
      Hive.box<QuestionLog>(AppConstants.questionLogsBox);

  void _load() {
    final logs = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    state = logs;
  }

  /// Yeni soru log'u ekler ve eğer topicId verildiyse Topic'in
  /// `questionsSolved` ve `correctCount` değerlerini de günceller.
  Future<QuestionLog> addLog({
    required String subjectId,
    String? topicId,
    required int correct,
    required int wrong,
    required int blank,
    String? note,
  }) async {
    final log = QuestionLog(
      id: _uuid.v4(),
      subjectId: subjectId,
      topicId: topicId,
      correct: correct,
      wrong: wrong,
      blank: blank,
      date: DateTime.now(),
      note: note,
    );

    await _box.put(log.id, log);
    state = [log, ...state];

    // Topic'e yansıt
    if (topicId != null && (correct + wrong) > 0) {
      await ref
          .read(topicProvider.notifier)
          .addQuestionResult(topicId, correct: correct, wrong: wrong);
    }

    return log;
  }

  Future<void> deleteLog(String id) async {
    await _box.delete(id);
    state = state.where((l) => l.id != id).toList();
  }

  /// Bir derse ait toplam net (tüm zamanlar)
  double netForSubject(Subject subject) {
    return state
        .where((l) => l.subjectId == subject.id)
        .fold(0.0, (sum, l) => sum + l.net);
  }

  /// Bugünün toplam net'i
  double get todayTotalNet {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return state
        .where((l) {
          final d = DateTime(l.date.year, l.date.month, l.date.day);
          return d == today;
        })
        .fold(0.0, (sum, l) => sum + l.net);
  }

  /// Bugün toplam çözülen soru sayısı
  int get todayTotalQuestions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return state
        .where((l) {
          final d = DateTime(l.date.year, l.date.month, l.date.day);
          return d == today;
        })
        .fold(0, (sum, l) => sum + l.total);
  }

  /// Bu haftanın log'ları
  List<QuestionLog> get thisWeekLogs {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(start.year, start.month, start.day);
    return state.where((l) => l.date.isAfter(weekStart)).toList();
  }
}

final questionLogProvider =
    StateNotifierProvider<QuestionLogNotifier, List<QuestionLog>>(
  (ref) => QuestionLogNotifier(ref),
);
