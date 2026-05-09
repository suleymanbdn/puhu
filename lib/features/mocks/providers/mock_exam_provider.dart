import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../exam/models/exam_profile.dart';
import '../models/mock_exam.dart';

class MockExamNotifier extends StateNotifier<List<MockExam>> {
  MockExamNotifier() : super([]) {
    _load();
  }

  static const _uuid = Uuid();

  Box<MockExam> get _box => Hive.box<MockExam>(AppConstants.mockExamsBox);

  void _load() {
    final list = _box.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    state = list;
  }

  Future<MockExam> add({
    required String publisher,
    required DateTime date,
    required ExamType examType,
    required Map<String, double> subjectNets,
    String? note,
  }) async {
    final exam = MockExam(
      id: _uuid.v4(),
      publisher: publisher,
      date: date,
      examType: examType,
      subjectNets: subjectNets,
      note: note,
    );
    await _box.put(exam.id, exam);
    state = [...state, exam]..sort((a, b) => a.date.compareTo(b.date));
    return exam;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    state = state.where((e) => e.id != id).toList();
  }

  /// Toplam net'lerin tarihe sıralı listesi (grafik için)
  List<({DateTime date, double net})> get netSeries {
    return state
        .map((e) => (date: e.date, net: e.totalNet))
        .toList();
  }

  /// Son denemenin toplam net'i
  double? get lastNet => state.isEmpty ? null : state.last.totalNet;

  /// Tüm denemelerin ortalama net'i
  double get averageNet {
    if (state.isEmpty) return 0;
    final sum = state.fold<double>(0, (s, e) => s + e.totalNet);
    return sum / state.length;
  }

  /// Bir derse göre net gelişimi
  List<({DateTime date, double net})> seriesForSubject(String subjectId) {
    return state
        .map((e) => (date: e.date, net: e.netFor(subjectId)))
        .toList();
  }
}

final mockExamProvider =
    StateNotifierProvider<MockExamNotifier, List<MockExam>>(
  (ref) => MockExamNotifier(),
);
