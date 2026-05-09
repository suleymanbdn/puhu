import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/settings_provider.dart';
import '../../exam/models/exam_profile.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../subjects/models/subject.dart';
import '../models/focus_session.dart';
import '../models/time_budget.dart';
import '../../tasks/models/task_enums.dart';

// =============================================================================
// FOCUS TIMER STATE
// =============================================================================

/// Timer durumu
enum TimerStatus { idle, running, paused, completed }

/// Focus timer state
class FocusTimerState {
  final TimerStatus status;
  final FocusType focusType;
  final int totalSeconds;
  final int remainingSeconds;
  final String? linkedTaskId;
  final TaskCategory? category;
  final String? subjectId;
  final String? topicId;
  final DateTime? startTime;

  const FocusTimerState({
    this.status = TimerStatus.idle,
    this.focusType = FocusType.work,
    this.totalSeconds = 25 * 60,
    this.remainingSeconds = 25 * 60,
    this.linkedTaskId,
    this.category,
    this.subjectId,
    this.topicId,
    this.startTime,
  });

  FocusTimerState copyWith({
    TimerStatus? status,
    FocusType? focusType,
    int? totalSeconds,
    int? remainingSeconds,
    String? linkedTaskId,
    TaskCategory? category,
    String? subjectId,
    String? topicId,
    DateTime? startTime,
    bool clearSubject = false,
    bool clearTopic = false,
  }) {
    return FocusTimerState(
      status: status ?? this.status,
      focusType: focusType ?? this.focusType,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      category: category ?? this.category,
      subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
      topicId: clearTopic ? null : (topicId ?? this.topicId),
      startTime: startTime ?? this.startTime,
    );
  }

  /// İlerleme yüzdesi (0-1)
  double get progress {
    if (totalSeconds == 0) return 0;
    return 1 - (remainingSeconds / totalSeconds);
  }

  /// Kalan süreyi mm:ss formatında döndürür
  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Geçen süre (dakika)
  int get elapsedMinutes => (totalSeconds - remainingSeconds) ~/ 60;
}

// =============================================================================
// FOCUS TIMER NOTIFIER
// =============================================================================

class FocusTimerNotifier extends StateNotifier<FocusTimerState> {
  FocusTimerNotifier(this.ref) : super(const FocusTimerState()) {
    // Başlangıçta ayarlardan süreleri çek
    _applySettings(ref.read(settingsProvider));
    
    // Ayarlar değiştiğinde (ve timer boşta ise) süreleri güncelle
    ref.listen<SettingsState>(settingsProvider, (previous, next) {
      if (state.status == TimerStatus.idle) {
        _applySettings(next);
      }
    });
  }

  final Ref ref;
  Timer? _timer;
  final _uuid = const Uuid();

  void _applySettings(SettingsState settings) {
    int minutes = settings.workDuration;
    if (state.focusType == FocusType.shortBreak) minutes = settings.shortBreakDuration;
    if (state.focusType == FocusType.longBreak) minutes = settings.longBreakDuration;

    state = state.copyWith(
      totalSeconds: minutes * 60,
      remainingSeconds: minutes * 60,
    );
  }

  /// Timer'ı başlat
  void start() {
    if (state.status == TimerStatus.running) return;

    state = state.copyWith(
      status: TimerStatus.running,
      startTime: state.startTime ?? DateTime.now(),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _timer?.cancel();
        state = state.copyWith(status: TimerStatus.completed);
        _handleAutoFlow();
      }
    });
  }

  void _handleAutoFlow() {
    final settings = ref.read(settingsProvider);
    if (settings.autoFlow) {
      if (state.focusType == FocusType.work) {
        setFocusType(FocusType.shortBreak);
        start();
      } else {
        setFocusType(FocusType.work);
        start();
      }
    }
  }

  /// Timer'ı duraklat
  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
  }

  /// Timer'ı devam ettir
  void resume() {
    start();
  }

  /// Timer'ı sıfırla
  void reset() {
    _timer?.cancel();
    final settings = ref.read(settingsProvider);
    int minutes = settings.workDuration;
    if (state.focusType == FocusType.shortBreak) minutes = settings.shortBreakDuration;
    if (state.focusType == FocusType.longBreak) minutes = settings.longBreakDuration;

    state = FocusTimerState(
      focusType: state.focusType,
      totalSeconds: minutes * 60,
      remainingSeconds: minutes * 60,
    );
  }

  /// Focus tipini değiştir
  void setFocusType(FocusType type) {
    _timer?.cancel();
    final settings = ref.read(settingsProvider);
    int minutes = settings.workDuration;
    if (type == FocusType.shortBreak) minutes = settings.shortBreakDuration;
    if (type == FocusType.longBreak) minutes = settings.longBreakDuration;

    state = FocusTimerState(
      focusType: type,
      totalSeconds: minutes * 60,
      remainingSeconds: minutes * 60,
    );
  }

  /// Süreyi manuel ayarla (dakika)
  void setDuration(int minutes) {
    _timer?.cancel();
    state = state.copyWith(
      totalSeconds: minutes * 60,
      remainingSeconds: minutes * 60,
      status: TimerStatus.idle,
    );
  }

  /// Görev bağla
  void linkTask(String taskId, TaskCategory category) {
    state = state.copyWith(
      linkedTaskId: taskId,
      category: category,
    );
  }

  /// Kategori seç
  void setCategory(TaskCategory category) {
    state = state.copyWith(category: category);
  }

  /// YKS dersi seç
  void setSubject(String? subjectId) {
    state = state.copyWith(
      subjectId: subjectId,
      // Ders değişince konu sıfırlanır
      clearTopic: true,
    );
  }

  /// YKS konusu seç
  void setTopic(String? topicId) {
    state = state.copyWith(topicId: topicId);
  }

  /// Oturumu tamamla ve kaydet
  Future<FocusSession> completeSession(FocusMood mood, {String? note}) async {
    _timer?.cancel();

    final session = FocusSession(
      id: _uuid.v4(),
      type: state.focusType,
      plannedMinutes: state.totalSeconds ~/ 60,
      actualMinutes: state.elapsedMinutes,
      mood: mood,
      startTime: state.startTime ?? DateTime.now(),
      endTime: DateTime.now(),
      taskId: state.linkedTaskId,
      // YKS pivot: categoryName önce subjectId, yoksa eski category.title
      categoryName: state.subjectId ?? state.category?.title,
      note: note,
    );

    // Hive'a kaydet
    final box = Hive.box<FocusSession>(AppConstants.focusSessionsBox);
    await box.put(session.id, session);

    // State'i sıfırla
    reset();

    return session;
  }

  /// Timer'ı iptal et
  void cancel() {
    _timer?.cancel();
    reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// =============================================================================
// TIME BUDGET NOTIFIER
// =============================================================================

class TimeBudgetState {
  final List<TimeBudget> budgets;
  final bool isLoading;

  const TimeBudgetState({
    this.budgets = const [],
    this.isLoading = false,
  });

  TimeBudgetState copyWith({
    List<TimeBudget>? budgets,
    bool? isLoading,
  }) {
    return TimeBudgetState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TimeBudgetNotifier extends StateNotifier<TimeBudgetState> {
  TimeBudgetNotifier(this.ref) : super(const TimeBudgetState()) {
    _loadBudgets();
    // ExamProfile değiştiğinde bütçeleri yeniden hesapla
    ref.listen<ExamProfile?>(examProfileProvider, (prev, next) {
      if (next == null) return;
      if (prev?.examType != next.examType) {
        _regenerateForCurrentWeek();
      }
    });
  }

  final Ref ref;

  Box<TimeBudget> get _box => Hive.box<TimeBudget>(AppConstants.timeBudgetsBox);

  /// Hafta başlangıcını al (Pazartesi)
  DateTime get _currentWeekStart {
    final now = DateTime.now();
    final daysToSubtract = now.weekday - 1;
    return DateTime(now.year, now.month, now.day - daysToSubtract);
  }

  /// Aktif sınav tipini ExamProfile'dan al, yoksa varsayılan olarak sayısal
  ExamTypeFilter get _activeExamType {
    final profile = ref.read(examProfileProvider);
    if (profile == null) return ExamTypeFilter.sayisal;
    switch (profile.examType) {
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

  /// Bütçeleri yükle
  Future<void> _loadBudgets() async {
    state = state.copyWith(isLoading: true);

    try {
      final weekStart = _currentWeekStart;
      var budgets = _box.values.where((b) {
        return b.weekStartDate.year == weekStart.year &&
            b.weekStartDate.month == weekStart.month &&
            b.weekStartDate.day == weekStart.day;
      }).toList();

      // Eğer bu hafta için bütçe yoksa, varsayılanları oluştur
      if (budgets.isEmpty) {
        final profile = ref.read(examProfileProvider);
        // Profil yoksa boş liste; onboarding sonrası regenerate edilecek
        if (profile != null) {
          budgets = DefaultBudgets.forExamType(
            _activeExamType,
            weekStart,
            weeklyTotalHours: profile.weeklyTargetHours,
          );
          for (final budget in budgets) {
            await _box.put(budget.id, budget);
          }
        }
      }

      state = state.copyWith(budgets: budgets, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Bu haftanın bütçelerini sınav tipine göre yeniden oluşturur
  /// (eski hafta bütçeleri korunur — yeni hafta sıfırdan oluşur)
  Future<void> _regenerateForCurrentWeek() async {
    final weekStart = _currentWeekStart;
    final profile = ref.read(examProfileProvider);
    if (profile == null) return;

    // Bu haftanın eski bütçelerini sil
    final toDelete = _box.values.where((b) {
      return b.weekStartDate.year == weekStart.year &&
          b.weekStartDate.month == weekStart.month &&
          b.weekStartDate.day == weekStart.day;
    }).map((b) => b.id).toList();
    for (final id in toDelete) {
      await _box.delete(id);
    }

    // Yenilerini oluştur
    final fresh = DefaultBudgets.forExamType(
      _activeExamType,
      weekStart,
      weeklyTotalHours: profile.weeklyTargetHours,
    );
    for (final b in fresh) {
      await _box.put(b.id, b);
    }
    state = state.copyWith(budgets: fresh);
  }

  /// Onboarding'den sonra çağrılır — ilk bütçeleri oluşturur
  Future<void> initializeForExamType() async {
    await _regenerateForCurrentWeek();
  }

  /// Bütçeye süre ekle
  Future<void> addTimeToCategory(String categoryName, int minutes) async {
    final writes = <Future<void>>[];
    final updatedBudgets = state.budgets.map((b) {
      if (b.categoryName == categoryName) {
        final updated = b.copyWith(spentMinutes: b.spentMinutes + minutes);
        writes.add(_box.put(b.id, updated));
        return updated;
      }
      return b;
    }).toList();

    await Future.wait(writes);
    state = state.copyWith(budgets: updatedBudgets);
  }

  /// Bütçe hedefini güncelle
  Future<void> updateBudgetTarget(String budgetId, int newTargetMinutes) async {
    final writes = <Future<void>>[];
    final updatedBudgets = state.budgets.map((b) {
      if (b.id == budgetId) {
        final updated = b.copyWith(targetMinutesPerWeek: newTargetMinutes);
        writes.add(_box.put(b.id, updated));
        return updated;
      }
      return b;
    }).toList();

    await Future.wait(writes);
    state = state.copyWith(budgets: updatedBudgets);
  }

  /// Haftalık bütçeleri sıfırla (yeni hafta için)
  Future<void> resetForNewWeek() async {
    await _box.clear();
    await _loadBudgets();
  }

  /// Toplam hedef saat
  double get totalTargetHours {
    return state.budgets.fold(0, (sum, b) => sum + b.targetHours);
  }

  /// Toplam harcanan saat
  double get totalSpentHours {
    return state.budgets.fold(0, (sum, b) => sum + b.spentHours);
  }
}

// =============================================================================
// FOCUS SESSIONS HISTORY
// =============================================================================

class FocusHistoryNotifier extends StateNotifier<List<FocusSession>> {
  FocusHistoryNotifier() : super([]) {
    _loadSessions();
  }

  Box<FocusSession> get _box => Hive.box<FocusSession>(AppConstants.focusSessionsBox);

  void _loadSessions() {
    final sessions = _box.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    state = sessions;
  }

  /// Bugünün oturumları
  List<FocusSession> get todaySessions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return state.where((s) {
      final sessionDate = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      return sessionDate == today;
    }).toList();
  }

  /// Bu haftanın oturumları
  List<FocusSession> get thisWeekSessions {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return state.where((s) => s.startTime.isAfter(startOfWeek)).toList();
  }

  /// Bugün toplam odaklanma süresi (dakika)
  int get todayTotalMinutes {
    return todaySessions.fold(0, (sum, s) => sum + s.actualMinutes);
  }

  /// Bu hafta toplam odaklanma süresi (dakika)
  int get weekTotalMinutes {
    return thisWeekSessions.fold(0, (sum, s) => sum + s.actualMinutes);
  }

  /// Oturum sil
  Future<void> deleteSession(String id) async {
    await _box.delete(id);
    _loadSessions();
  }

  /// Yenile
  void refresh() {
    _loadSessions();
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

/// Focus timer provider
final focusTimerProvider =
    StateNotifierProvider<FocusTimerNotifier, FocusTimerState>((ref) {
  return FocusTimerNotifier(ref);
});

/// Time budget provider
final timeBudgetProvider =
    StateNotifierProvider<TimeBudgetNotifier, TimeBudgetState>((ref) {
  return TimeBudgetNotifier(ref);
});

/// Focus history provider
final focusHistoryProvider =
    StateNotifierProvider<FocusHistoryNotifier, List<FocusSession>>((ref) {
  return FocusHistoryNotifier();
});

/// Bugünün istatistikleri
final todayFocusStatsProvider = Provider((ref) {
  final history = ref.watch(focusHistoryProvider.notifier);
  return {
    'sessions': history.todaySessions.length,
    'minutes': history.todayTotalMinutes,
  };
});

/// Bu haftanın istatistikleri
final weekFocusStatsProvider = Provider((ref) {
  final history = ref.watch(focusHistoryProvider.notifier);
  return {
    'sessions': history.thisWeekSessions.length,
    'minutes': history.weekTotalMinutes,
  };
});
