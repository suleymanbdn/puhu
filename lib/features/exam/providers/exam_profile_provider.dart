import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/exam_profile.dart';

/// Kullanıcının YKS profili — null ise onboarding tamamlanmamış demektir.
class ExamProfileNotifier extends StateNotifier<ExamProfile?> {
  ExamProfileNotifier() : super(null) {
    _load();
  }

  Box<ExamProfile> get _box =>
      Hive.box<ExamProfile>(AppConstants.examProfileBox);

  void _load() {
    state = _box.get(ExamProfile.boxKey);
  }

  /// Yeni profil oluştur veya mevcut olanı güncelle
  Future<void> save(ExamProfile profile) async {
    await _box.put(ExamProfile.boxKey, profile);
    state = profile;
  }

  /// Profil var mı?
  bool get hasProfile => state != null;

  /// Sınav tipini güncelle
  Future<void> updateExamType(ExamType type) async {
    if (state == null) return;
    await save(state!.copyWith(examType: type));
  }

  /// Hedef bilgilerini güncelle
  Future<void> updateTarget({
    String? university,
    String? department,
    double? targetNet,
  }) async {
    if (state == null) return;
    await save(state!.copyWith(
      targetUniversity: university,
      targetDepartment: department,
      targetNet: targetNet,
    ));
  }

  /// Sınav tarihini güncelle
  Future<void> updateExamDate(DateTime date) async {
    if (state == null) return;
    await save(state!.copyWith(examDate: date));
  }

  /// Günlük çalışma hedefini güncelle
  Future<void> updateDailyTarget(double hours) async {
    if (state == null) return;
    await save(state!.copyWith(dailyTargetHours: hours));
  }

  /// Profili sıfırla (testler/dev için)
  Future<void> reset() async {
    await _box.delete(ExamProfile.boxKey);
    state = null;
  }
}

final examProfileProvider =
    StateNotifierProvider<ExamProfileNotifier, ExamProfile?>(
  (ref) => ExamProfileNotifier(),
);

/// Onboarding tamamlanmış mı?
final onboardingCompletedProvider = Provider<bool>((ref) {
  final profile = ref.watch(examProfileProvider);
  return profile != null;
});
