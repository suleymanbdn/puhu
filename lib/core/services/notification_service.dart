import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Channel ID'leri
  static const String _timerChannel = 'timer_channel';
  static const String _examChannel = 'exam_reminders';
  static const String _reviewChannel = 'topic_reviews';
  static const String _dailyChannel = 'daily_goal';

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidInit =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings: settings);

    // Android 13+ runtime izin
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    _isInitialized = true;
  }

  // ============================================================
  // INSTANT NOTIFICATIONS
  // ============================================================

  Future<void> showTimerCompleteNotification(
      String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _timerChannel,
        'Zamanlayıcı Bildirimleri',
        channelDescription: 'Odak ve mola süreleri bittiğinde uyarır',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // ============================================================
  // SCHEDULED NOTIFICATIONS
  // ============================================================

  /// YKS sınav tarihine göre 100/30/7/1 gün kala bildirim planlar.
  Future<void> scheduleExamReminders(DateTime examDate) async {
    // Eski exam bildirimlerini temizle (id 1000-1099 arası rezerve)
    for (int id = 1000; id < 1100; id++) {
      await _plugin.cancel(id: id);
    }

    // Daha sık temas: yakına gelirken aciliyet artsın.
    final milestones = <int>[100, 50, 30, 10, 7, 3, 1];
    int idCounter = 1000;
    for (final daysBefore in milestones) {
      final fireAt = examDate.subtract(Duration(days: daysBefore));
      final scheduled =
          DateTime(fireAt.year, fireAt.month, fireAt.day, 9, 0);
      if (scheduled.isBefore(DateTime.now())) {
        idCounter++;
        continue;
      }

      String title;
      String body;
      if (daysBefore >= 30) {
        title = 'YKS\'ye $daysBefore gün kaldı';
        body = 'Planını gözden geçir, hızını koru.';
      } else if (daysBefore >= 7) {
        title = 'Son düzlük: $daysBefore gün kaldı';
        body = 'Zayıf konularını tekrar et, tempolu git.';
      } else {
        title = 'YKS yarın!';
        body = 'Bol uyu, hafif tekrar yap, başaracaksın 💪';
      }

      await _scheduleAt(
        id: idCounter++,
        title: title,
        body: body,
        when: scheduled,
        channelId: _examChannel,
        channelName: 'Sınav Hatırlatıcıları',
      );
    }
  }

  /// Bir konunun spaced repetition tekrar bildirimini planlar
  Future<void> scheduleTopicReview({
    required String topicId,
    required String topicName,
    required String subjectTitle,
    required DateTime studiedAt,
    List<int> reviewDays = const [1, 3, 7, 21],
  }) async {
    final baseId = 2000 + (topicId.hashCode.abs() % 8000);

    for (var i = 0; i < reviewDays.length; i++) {
      final id = baseId + i;
      await _plugin.cancel(id: id);

      final fireAt = studiedAt.add(Duration(days: reviewDays[i]));
      final scheduled =
          DateTime(fireAt.year, fireAt.month, fireAt.day, 19, 0);
      if (scheduled.isBefore(DateTime.now())) continue;

      await _scheduleAt(
        id: id,
        title: 'Tekrar zamanı: $topicName',
        body: '$subjectTitle - Bu konuyu unutmamak için 5 dakika tekrar et.',
        when: scheduled,
        channelId: _reviewChannel,
        channelName: 'Konu Tekrarları',
      );
    }
  }

  /// Günlük çalışma hedefini hatırlatma bildirimi (her gün belirli saatte)
  Future<void> scheduleDailyReminder({
    int hour = 9,
    int minute = 0,
  }) async {
    await _plugin.cancel(id: 500);

    final now = DateTime.now();
    var first = DateTime(now.year, now.month, now.day, hour, minute);
    if (first.isBefore(now)) {
      first = first.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: 500,
      title: 'Günaydın! 🌅',
      body: 'Bugünkü çalışma hedefini hatırla, başlamanın tam zamanı.',
      scheduledDate: tz.TZDateTime.from(first, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannel,
          'Günlük Hatırlatıcı',
          channelDescription: 'Her gün çalışma hedefini hatırlatır',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // her gün
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(id: 500);
  }

  /// Akşam streak break uyarısı — her gün belirli saatte (varsayılan 20:00)
  /// tetiklenir. Mesaj kullanıcının streak'ini kaybetmemesi için çalışmaya
  /// davet eder. Streak Freeze'i olan kullanıcılar için bile motivasyon
  /// kaynağı; gün içinde çalışan kullanıcı için ise app açtığında
  /// [cancelStreakBreakReminderToday] ile bugünkü instance kapatılır.
  Future<void> scheduleStreakBreakReminder({
    int hour = 20,
    int minute = 0,
  }) async {
    await _plugin.cancel(id: 600);

    final now = DateTime.now();
    var first = DateTime(now.year, now.month, now.day, hour, minute);
    if (first.isBefore(now)) {
      first = first.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: 600,
      title: 'Streak\'ini kaybetme 🔥',
      body: 'Bugün hâlâ çalışmadıysan kısa bir pomodoro bile yeter.',
      scheduledDate: tz.TZDateTime.from(first, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannel,
          'Streak Uyarısı',
          channelDescription:
              'Akşam saatlerinde streak\'in kırılmasını engellemek için uyarı',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // her gün aynı saat
    );
  }

  /// Bugünkü streak uyarısını sustur. Kullanıcı çalıştığını uygulamada
  /// kanıtladıysa (focus session bitirdiyse) çağırılır.
  Future<void> cancelStreakBreakReminderToday() async {
    await _plugin.cancel(id: 600);
    // Yarın için tekrar planla.
    await scheduleStreakBreakReminder();
  }

  Future<void> cancelStreakBreakReminder() async {
    await _plugin.cancel(id: 600);
  }

  /// Hata Sepeti günlük tekrar uyarısı — varsayılan 18:00. Mesaj her gün
  /// aynı; sepette bekleyen yoksa kullanıcı bildirimi gör-ardımcı kapatır,
  /// var ise tekrar oturumuna girer.
  Future<void> scheduleMistakeReviewReminder({
    int hour = 18,
    int minute = 0,
  }) async {
    await _plugin.cancel(id: 700);

    final now = DateTime.now();
    var first = DateTime(now.year, now.month, now.day, hour, minute);
    if (first.isBefore(now)) {
      first = first.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: 700,
      title: 'Hata Sepeti 📓',
      body: 'Bekleyen hatalarına bir göz at — 10 dakika yeter.',
      scheduledDate: tz.TZDateTime.from(first, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _reviewChannel,
          'Hata Tekrarı',
          channelDescription:
              'Hata sepetindeki bekleyen kayıtları gözden geçirme uyarısı',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // her gün aynı saat
    );
  }

  Future<void> cancelMistakeReviewReminder() async {
    await _plugin.cancel(id: 700);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ============================================================
  // INTERNAL
  // ============================================================

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required String channelId,
    required String channelName,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
