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

    // İzin İSTEMEDEN initialize — izin onboarding'in son adımında,
    // "sana hatırlatalım mı?" bağlamıyla istenir (requestPermissions).
    // Uygulama açılır açılmaz izin diyaloğu göstermek çoğu kullanıcının
    // refleks olarak "İzin Verme" demesine yol açıyor.
    const androidInit =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings: settings);

    _isInitialized = true;
  }

  /// Bildirim iznini ister — onboarding'in son adımında, bağlamıyla çağrılır.
  /// Daha önce cevaplanmışsa sistem diyaloğu tekrar çıkmaz.
  Future<bool> requestPermissions() async {
    // Android 13+ runtime izin
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await androidImpl?.requestNotificationsPermission();

    // iOS izin
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? iosGranted) ?? false;
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

  /// Günlük hatırlatıcı — v1.2.0'dan itibaren ayrı bir sabah bildirimi
  /// YOK (bildirim yorgunluğu). Tek akşam bildirimi her şeyi kapsar;
  /// bu metot geriye dönük uyumluluk için akşam hatırlatıcısına yönlenir.
  Future<void> scheduleDailyReminder({
    int hour = 9,
    int minute = 0,
  }) async {
    // Eski sabah bildirimi planlıysa iptal et.
    await _plugin.cancel(id: 500);
    await scheduleStreakBreakReminder();
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(id: 500);
  }

  /// Günün TEK rutin bildirimi — akşam hatırlatıcısı (varsayılan 19:00).
  ///
  /// v1.2.0: Önceden günde 3 ayrı bildirim vardı (09:00 hedef + 18:00 hata
  /// + 20:00 streak) — bildirim yorgunluğu yaratıyordu. Artık tek pozitif
  /// akşam mesajı streak + hata tekrarını birlikte kapsar. Gün içinde
  /// çalışan kullanıcı için [cancelStreakBreakReminderToday] bugünkü
  /// bildirimi susturur.
  Future<void> scheduleStreakBreakReminder({
    int hour = 19,
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
      title: 'Günü kapatmadan ✨',
      body: '15 dakika yeter — serin sürsün, bekleyen hatalarına da göz at.',
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

  /// Hata Sepeti uyarısı — v1.2.0'dan itibaren ayrı bildirim YOK; akşam
  /// hatırlatıcısı (19:00) hata tekrarını da kapsıyor. Bu metot eski
  /// planlanmış bildirimi temizler ve akşam hatırlatıcısını garantiler.
  Future<void> scheduleMistakeReviewReminder({
    int hour = 18,
    int minute = 0,
  }) async {
    await _plugin.cancel(id: 700);
    await scheduleStreakBreakReminder();
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
