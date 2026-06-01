import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/settings_provider.dart';
import '../models/mistake.dart';
import '../services/mistake_repository.dart';

const _uuid = Uuid();

/// Tüm hata listesi (aktif + mastered).
final mistakeProvider =
    StateNotifierProvider<MistakeNotifier, List<Mistake>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MistakeNotifier(MistakeRepository(prefs));
});

/// Aktif (mastered olmayan) hatalar — liste ekranlarında bu kullanılır.
final activeMistakesProvider = Provider<List<Mistake>>((ref) {
  final all = ref.watch(mistakeProvider);
  return all.where((m) => !m.mastered).toList()
    ..sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
});

/// Bugün (ve geçmiş günlerden) tekrar bekleyen hatalar.
final pendingMistakesProvider = Provider<List<Mistake>>((ref) {
  final active = ref.watch(activeMistakesProvider);
  return active.where((m) => m.isPending).toList();
});

/// Bir ders altında bekleyen hata sayısı.
final pendingCountForSubjectProvider =
    Provider.family<int, String>((ref, subjectId) {
  final pending = ref.watch(pendingMistakesProvider);
  return pending.where((m) => m.subjectId == subjectId).length;
});

/// Toplam aktif hata sayısı.
final activeMistakeCountProvider = Provider<int>((ref) {
  return ref.watch(activeMistakesProvider).length;
});

/// Bugün tekrar bekleyen hata sayısı (dashboard rozeti için).
final pendingMistakeCountProvider = Provider<int>((ref) {
  return ref.watch(pendingMistakesProvider).length;
});

class MistakeNotifier extends StateNotifier<List<Mistake>> {
  MistakeNotifier(this._repo) : super(_repo.readAll());

  final MistakeRepository _repo;

  Future<void> _persist() => _repo.writeAll(state);

  /// Yeni hata ekler.
  Future<Mistake> add({
    required String subjectId,
    String? topicId,
    required String title,
    String? note,
  }) async {
    final m = Mistake(
      id: _uuid.v4(),
      subjectId: subjectId,
      topicId: topicId,
      title: title.trim(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      addedAt: DateTime.now(),
    );
    state = [m, ...state];
    await _persist();
    return m;
  }

  /// Tekrar sonucu kaydı: "Biliyorum".
  Future<void> markCorrect(String id) async {
    final now = DateTime.now();
    state = [
      for (final m in state)
        if (m.id == id) m.markCorrect(now) else m,
    ];
    await _persist();
  }

  /// Tekrar sonucu kaydı: "Yine yanlış".
  Future<void> markWrong(String id) async {
    final now = DateTime.now();
    state = [
      for (final m in state)
        if (m.id == id) m.markWrong(now) else m,
    ];
    await _persist();
  }

  /// Hatayı sil.
  Future<void> delete(String id) async {
    state = state.where((m) => m.id != id).toList();
    await _persist();
  }

  /// Mastered işaretle (manuel "öğrenildi").
  Future<void> markMastered(String id) async {
    state = [
      for (final m in state)
        if (m.id == id) m.copyWith(mastered: true) else m,
    ];
    await _persist();
  }

  /// Mastered'i geri al (tekrar aktif et).
  Future<void> unmaster(String id) async {
    state = [
      for (final m in state)
        if (m.id == id) m.copyWith(mastered: false) else m,
    ];
    await _persist();
  }
}
