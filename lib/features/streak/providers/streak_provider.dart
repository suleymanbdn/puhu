import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../timer/models/focus_session.dart';
import '../../timer/providers/focus_provider.dart';
import 'streak_freeze_provider.dart';

/// Streak (peşpeşe çalışılan gün sayısı) hesaplaması
///
/// Bir günde en az 1 odak oturumu (`FocusSession`) tamamlandıysa o gün
/// "çalışılmış" sayılır. Streak bugünden geriye doğru kesintisiz tüm
/// günlerin sayısıdır. Streak Freeze ile "donmuş" günler de streak
/// devamlılığında "çalışılmış" gibi davranır (ancak `studiedToday` ve
/// `studiedDaysThisMonth` etkilenmez — bunlar yalnızca gerçek çalışmadır).
class StreakStats {
  const StreakStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.studiedToday,
    required this.studiedDaysThisMonth,
    this.canFreezeYesterday = false,
    this.streakIfYesterdayFrozen = 0,
  });

  /// Aktif (mevcut) streak
  final int currentStreak;

  /// En uzun streak (tüm zamanlar)
  final int longestStreak;

  /// Bugün en az bir oturum yapıldı mı?
  final bool studiedToday;

  /// Bu ay çalışılan toplam gün sayısı
  final int studiedDaysThisMonth;

  /// Dün boş bırakıldı ve önceki günde çalışma vardı — bir freeze token'ı
  /// kullanarak streak kurtarılabilir mi?
  final bool canFreezeYesterday;

  /// Dün dondurulursa streak ne olur (kullanıcıya gösterilecek vaat).
  final int streakIfYesterdayFrozen;
}

final streakProvider = Provider<StreakStats>((ref) {
  final sessions = ref.watch(focusHistoryProvider);
  final freeze = ref.watch(streakFreezeProvider);
  return _computeStreak(sessions, freeze.frozenDays);
});

StreakStats _computeStreak(
  List<FocusSession> sessions,
  Set<String> frozenDays,
) {
  if (sessions.isEmpty && frozenDays.isEmpty) {
    return const StreakStats(
      currentStreak: 0,
      longestStreak: 0,
      studiedToday: false,
      studiedDaysThisMonth: 0,
    );
  }

  // Çalışma yapılmış benzersiz günler (sıralı set)
  final studiedDays = <DateTime>{};
  for (final s in sessions) {
    if (s.actualMinutes <= 0) continue;
    studiedDays.add(
      DateTime(s.startTime.year, s.startTime.month, s.startTime.day),
    );
  }

  // Frozen günleri (string → DateTime) — streak devamlılığında "çalışılmış"
  // sayılacak ama studiedToday / studiedDaysThisMonth etkilenmeyecek.
  final frozenSet = <DateTime>{};
  for (final s in frozenDays) {
    final parts = s.split('-');
    if (parts.length != 3) continue;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) continue;
    frozenSet.add(DateTime(y, m, d));
  }

  // Streak hesabı için: gerçek çalışma + donmuş günler birleşimi.
  final effectiveDays = {...studiedDays, ...frozenSet};

  if (effectiveDays.isEmpty) {
    return const StreakStats(
      currentStreak: 0,
      longestStreak: 0,
      studiedToday: false,
      studiedDaysThisMonth: 0,
    );
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  // studiedToday yalnızca GERÇEK çalışma — donmuş günler buraya girmez.
  final studiedToday = studiedDays.contains(today);

  // Mevcut streak: bugün/dün başlayarak geriye doğru effectiveDays üzerinde.
  int current = 0;
  var cursor = effectiveDays.contains(today)
      ? today
      : (effectiveDays.contains(yesterday) ? yesterday : null);

  while (cursor != null && effectiveDays.contains(cursor)) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  // En uzun streak (effective günler üzerinden — donmuş günler de katkı verir)
  final sorted = effectiveDays.toList()..sort();
  int longest = 0;
  int run = 0;
  DateTime? prev;
  for (final d in sorted) {
    if (prev == null) {
      run = 1;
    } else {
      final diff = d.difference(prev).inDays;
      run = diff == 1 ? run + 1 : 1;
    }
    if (run > longest) longest = run;
    prev = d;
  }

  // Bu ay çalışılan günler — sadece GERÇEK çalışma.
  final monthStart = DateTime(now.year, now.month);
  final studiedThisMonth =
      studiedDays.where((d) => !d.isBefore(monthStart)).length;

  // Dünü dondurarak streak kurtarılabilir mi?
  final dayBeforeYesterday = today.subtract(const Duration(days: 2));
  final yesterdayMissing = !effectiveDays.contains(yesterday);
  final priorAnchorExists = effectiveDays.contains(dayBeforeYesterday);
  final canFreezeYesterday = yesterdayMissing && priorAnchorExists;

  int streakIfYesterdayFrozen = 0;
  if (canFreezeYesterday) {
    // Sanal olarak dünü ekleyip streak'i hesapla.
    final virtual = {...effectiveDays, yesterday};
    var c = studiedToday ? today : yesterday;
    while (virtual.contains(c)) {
      streakIfYesterdayFrozen++;
      c = c.subtract(const Duration(days: 1));
    }
  }

  return StreakStats(
    currentStreak: current,
    longestStreak: longest,
    studiedToday: studiedToday,
    studiedDaysThisMonth: studiedThisMonth,
    canFreezeYesterday: canFreezeYesterday,
    streakIfYesterdayFrozen: streakIfYesterdayFrozen,
  );
}
