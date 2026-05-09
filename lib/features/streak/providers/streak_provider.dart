import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../timer/models/focus_session.dart';
import '../../timer/providers/focus_provider.dart';

/// Streak (peşpeşe çalışılan gün sayısı) hesaplaması
///
/// Bir günde en az 1 odak oturumu (`FocusSession`) tamamlandıysa o gün
/// "çalışılmış" sayılır. Streak bugünden geriye doğru kesintisiz tüm
/// günlerin sayısıdır.
class StreakStats {
  const StreakStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.studiedToday,
    required this.studiedDaysThisMonth,
  });

  /// Aktif (mevcut) streak
  final int currentStreak;

  /// En uzun streak (tüm zamanlar)
  final int longestStreak;

  /// Bugün en az bir oturum yapıldı mı?
  final bool studiedToday;

  /// Bu ay çalışılan toplam gün sayısı
  final int studiedDaysThisMonth;
}

final streakProvider = Provider<StreakStats>((ref) {
  final sessions = ref.watch(focusHistoryProvider);
  return _computeStreak(sessions);
});

StreakStats _computeStreak(List<FocusSession> sessions) {
  if (sessions.isEmpty) {
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

  if (studiedDays.isEmpty) {
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
  final studiedToday = studiedDays.contains(today);

  // Mevcut streak: bugün veya dün başlayarak geriye doğru
  int current = 0;
  var cursor = studiedToday
      ? today
      : (studiedDays.contains(yesterday) ? yesterday : null);

  while (cursor != null && studiedDays.contains(cursor)) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  // En uzun streak
  final sorted = studiedDays.toList()..sort();
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

  // Bu ay çalışılan günler
  final monthStart = DateTime(now.year, now.month);
  final studiedThisMonth =
      studiedDays.where((d) => !d.isBefore(monthStart)).length;

  return StreakStats(
    currentStreak: current,
    longestStreak: longest,
    studiedToday: studiedToday,
    studiedDaysThisMonth: studiedThisMonth,
  );
}
