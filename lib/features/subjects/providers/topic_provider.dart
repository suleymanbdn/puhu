import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../data/yks_curriculum.dart';
import '../models/subject.dart';
import '../models/topic.dart';

/// Tüm konuların state'i
class TopicNotifier extends StateNotifier<List<Topic>> {
  TopicNotifier() : super([]) {
    _load();
  }

  static const _uuid = Uuid();

  Box<Topic> get _box => Hive.box<Topic>(AppConstants.topicsBox);

  void _load() {
    state = _box.values.toList();
  }

  /// Bir sınav tipi için curriculum'da olan ama Hive'da olmayan konuları
  /// otomatik oluşturur. Onboarding'den sonra çağrılır.
  Future<void> ensureTopicsForExamType(ExamTypeFilter examType) async {
    final curriculum = YksCurriculum.forExamType(examType);
    final existing = {for (final t in state) '${t.subjectId}::${t.name}': t};
    final toAdd = <Topic>[];

    for (final entry in curriculum.entries) {
      final subjectId = entry.key.id;
      for (final topicName in entry.value) {
        final key = '$subjectId::$topicName';
        if (!existing.containsKey(key)) {
          toAdd.add(Topic(
            id: _uuid.v4(),
            subjectId: subjectId,
            name: topicName,
          ));
        }
      }
    }

    if (toAdd.isEmpty) return;

    final writes = <Future<void>>[];
    for (final t in toAdd) {
      writes.add(_box.put(t.id, t));
    }
    await Future.wait(writes);
    state = [...state, ...toAdd];
  }

  /// Bir derse ait konuları döndürür
  List<Topic> forSubject(Subject subject) {
    return state.where((t) => t.subjectId == subject.id).toList();
  }

  /// Konu durumunu güncelle
  Future<void> updateStatus(String topicId, TopicStatus status) async {
    final idx = state.indexWhere((t) => t.id == topicId);
    if (idx < 0) return;
    final updated = state[idx].copyWith(status: status);
    await _box.put(updated.id, updated);
    state = [...state]..[idx] = updated;
  }

  /// Konuya çalışma süresi ekle (Pomodoro tamamlandığında)
  Future<void> addStudyTime(String topicId, int minutes) async {
    final idx = state.indexWhere((t) => t.id == topicId);
    if (idx < 0) return;
    final current = state[idx];
    final updated = current.copyWith(
      totalMinutes: current.totalMinutes + minutes,
      lastStudiedAt: DateTime.now(),
      status: current.status == TopicStatus.notStarted
          ? TopicStatus.inProgress
          : current.status,
    );
    await _box.put(updated.id, updated);
    state = [...state]..[idx] = updated;
  }

  /// Soru çözüm sonucu ekle
  Future<void> addQuestionResult(
    String topicId, {
    required int correct,
    required int wrong,
  }) async {
    final idx = state.indexWhere((t) => t.id == topicId);
    if (idx < 0) return;
    final current = state[idx];
    final updated = current.copyWith(
      questionsSolved: current.questionsSolved + correct + wrong,
      correctCount: current.correctCount + correct,
    );
    await _box.put(updated.id, updated);
    state = [...state]..[idx] = updated;
  }

  /// Notları güncelle
  Future<void> updateNotes(String topicId, String notes) async {
    final idx = state.indexWhere((t) => t.id == topicId);
    if (idx < 0) return;
    final updated = state[idx].copyWith(notes: notes);
    await _box.put(updated.id, updated);
    state = [...state]..[idx] = updated;
  }
}

final topicProvider =
    StateNotifierProvider<TopicNotifier, List<Topic>>((ref) => TopicNotifier());

/// Bir derse ait konular
final topicsForSubjectProvider =
    Provider.family<List<Topic>, Subject>((ref, subject) {
  final all = ref.watch(topicProvider);
  return all.where((t) => t.subjectId == subject.id).toList();
});

/// Bir dersin tamamlanma yüzdesi (0-1)
final subjectCompletionProvider =
    Provider.family<double, Subject>((ref, subject) {
  final topics = ref.watch(topicsForSubjectProvider(subject));
  if (topics.isEmpty) return 0;
  final completed =
      topics.where((t) => t.status == TopicStatus.completed).length;
  return completed / topics.length;
});
