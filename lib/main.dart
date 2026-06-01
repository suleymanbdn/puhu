import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/purchase_service.dart';
import 'core/services/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/exam/models/exam_profile.dart';
import 'features/mocks/models/mock_exam.dart';
import 'features/questions/models/question_log.dart';
import 'features/subjects/models/topic.dart';
import 'features/update/providers/store_update_provider.dart';
import 'features/update/views/update_prompt_page.dart';
import 'features/tasks/models/task_model.dart';
import 'features/tasks/models/task_enums.dart';
import 'features/timer/models/focus_session.dart';
import 'features/timer/models/time_budget.dart';

/// Uygulamanın giriş noktası
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe tarih formatlaması için intl başlatma
  await initializeDateFormatting('tr_TR', null);

  // Hive başlatma
  await _initHive();

  // Bildirim servisi başlatma
  await NotificationService.instance.initialize();

  // RevenueCat (satın alma) başlatma
  await configureRevenueCat();

  // SharedPreferences başlatma
  final prefs = await SharedPreferences.getInstance();

  // v1.1.3 migration: mevcut kullanıcılar için bir kez streak break uyarısı
  // planla. Yeni kullanıcılar onboarding'de zaten alır; eskiler Settings'i
  // açmadan da uyarıyı görsün. Sessizce başarısız olsun (bildirimler
  // izinli olmayabilir).
  if (!(prefs.getBool('streak_break_scheduled_v1') ?? false)) {
    try {
      await NotificationService.instance.scheduleStreakBreakReminder();
      await prefs.setBool('streak_break_scheduled_v1', true);
    } catch (_) {}
  }

  // Uygulamayı çalıştır
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ZamanYonetimiApp(),
    ),
  );
}

/// Hive veritabanını başlatır ve adapter'ları kaydeder
Future<void> _initHive() async {
  await Hive.initFlutter();

  // Adapter'ları kaydet (zaten kayıtlıysa hata vermez)
  try {
    // Task adapter'ları
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TaskCategoryAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TaskPriorityAdapter());

    // Focus session adapter'ları
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(FocusMoodAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(FocusTypeAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(FocusSessionAdapter());

    // Time budget adapter'ı
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(TimeBudgetAdapter());

    // YKS adapter'ları
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(TopicStatusAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(TopicAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(ExamTypeAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(ExamProfileAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(QuestionLogAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(MockExamAdapter());
  } on ArgumentError catch (e) {
    // Adapter zaten kayıtlıysa güvenle devam et
    debugPrint('Adapter already registered: $e');
  }

  // Box'ları paralel olarak aç (daha hızlı)
  await Future.wait([
    Hive.openBox<Task>(AppConstants.tasksBox),
    Hive.openBox<FocusSession>(AppConstants.focusSessionsBox),
    Hive.openBox<TimeBudget>(AppConstants.timeBudgetsBox),
    Hive.openBox<Topic>(AppConstants.topicsBox),
    Hive.openBox<ExamProfile>(AppConstants.examProfileBox),
    Hive.openBox<QuestionLog>(AppConstants.questionLogsBox),
    Hive.openBox<MockExam>(AppConstants.mockExamsBox),
  ]);
}

/// Ana uygulama widget'ı
class ZamanYonetimiApp extends ConsumerWidget {
  const ZamanYonetimiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tema modunu dinle
    final themeMode = ref.watch(themeModeNotifierProvider);
    // Router'ı provider'dan al
    final router = ref.watch(appRouterProvider);
    final storeUpdateAsync = ref.watch(storeUpdateCheckProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Türkçe yerelleştirme — tarih seçici, takvim vb. Türkçe görünür
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Tema yapılandırması
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Router yapılandırması
      routerConfig: router,

      // Play'de güncelleme varsa tam ekran yönlendirme
      builder: (context, child) {
        return storeUpdateAsync.when(
          data: (state) {
            if (!state.needsPrompt) {
              return child ?? const SizedBox.shrink();
            }
            return UpdatePromptPage(
              initialState: state,
              onRecheck: () => ref.invalidate(storeUpdateCheckProvider),
            );
          },
          loading: () => child ?? const SizedBox.shrink(),
          error: (_, __) => child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
