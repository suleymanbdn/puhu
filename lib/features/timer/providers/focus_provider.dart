import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
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
  final DateTime? startTime;

  const FocusTimerState({
    this.status = TimerStatus.idle,
    this.focusType = FocusType.work,
    this.totalSeconds = 25 * 60,
    this.remainingSeconds = 25 * 60,
    this.linkedTaskId,
    this.category,
    this.startTime,
  });

  FocusTimerState copyWith({
    TimerStatus? status,
    FocusType? focusType,
    int? totalSeconds,
    int? remainingSeconds,
    String? linkedTaskId,
    TaskCategory? category,
    DateTime? startTime,
  }) {
    return FocusTimerState(
      status: status ?? this.status,
      focusType: focusType ?? this.focusType,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      category: category ?? this.category,
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
  FocusTimerNotifier() : super(const FocusTimerState());

  Timer? _timer;
  final _uuid = const Uuid();

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
      }
    });
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
    state = FocusTimerState(
      focusType: state.focusType,
      totalSeconds: state.focusType.defaultMinutes * 60,
      remainingSeconds: state.focusType.defaultMinutes * 60,
    );
  }

  /// Focus tipini değiştir
  void setFocusType(FocusType type) {
    _timer?.cancel();
    state = FocusTimerState(
      focusType: type,
      totalSeconds: type.defaultMinutes * 60,
      remainingSeconds: type.defaultMinutes * 60,
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
      categoryName: state.category?.title,
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
  TimeBudgetNotifier() : super(const TimeBudgetState()) {
    _loadBudgets();
  }

  Box<TimeBudget> get _box => Hive.box<TimeBudget>(AppConstants.timeBudgetsBox);

  /// Hafta başlangıcını al (Pazartesi)
  DateTime get _currentWeekStart {
    final now = DateTime.now();
    final daysToSubtract = now.weekday - 1;
    return DateTime(now.year, now.month, now.day - daysToSubtract);
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
        budgets = DefaultBudgets.createDefaults(weekStart);
        for (final budget in budgets) {
          await _box.put(budget.id, budget);
        }
      }

      state = state.copyWith(budgets: budgets, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Bütçeye süre ekle
  Future<void> addTimeToCategory(String categoryName, int minutes) async {
    final budgets = state.budgets.map((b) {
      if (b.categoryName == categoryName) {
        final updated = b.copyWith(spentMinutes: b.spentMinutes + minutes);
        _box.put(b.id, updated);
        return updated;
      }
      return b;
    }).toList();

    state = state.copyWith(budgets: budgets);
  }

  /// Bütçe hedefini güncelle
  Future<void> updateBudgetTarget(String budgetId, int newTargetMinutes) async {
    final budgets = state.budgets.map((b) {
      if (b.id == budgetId) {
        final updated = b.copyWith(targetMinutesPerWeek: newTargetMinutes);
        _box.put(b.id, updated);
        return updated;
      }
      return b;
    }).toList();

    state = state.copyWith(budgets: budgets);
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
  return FocusTimerNotifier();
});

/// Time budget provider
final timeBudgetProvider =
    StateNotifierProvider<TimeBudgetNotifier, TimeBudgetState>((ref) {
  return TimeBudgetNotifier();
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
