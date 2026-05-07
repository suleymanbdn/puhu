import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/models/user_model.dart';
import 'features/tasks/models/task_model.dart';
import 'features/tasks/models/task_enums.dart';
import 'features/timer/models/focus_session.dart';
import 'features/timer/models/time_budget.dart';

/// Uygulamanın giriş noktası
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe tarih formatlaması için intl başlatma
  await initializeDateFormatting('en_US', null);

  // Hive başlatma
  await _initHive();

  // Uygulamayı çalıştır
  runApp(
    const ProviderScope(
      child: ZamanYonetimiApp(),
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

    // User adapter (typeId: 10)
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(UserAdapter());
  } catch (e) {
    // Adapter zaten kayıtlıysa devam et
    debugPrint('Adapter kayıt hatası (normal olabilir): $e');
  }

  // Box'ları paralel olarak aç (daha hızlı)
  await Future.wait([
    Hive.openBox<Task>(AppConstants.tasksBox),
    Hive.openBox<FocusSession>(AppConstants.focusSessionsBox),
    Hive.openBox<TimeBudget>(AppConstants.timeBudgetsBox),
    Hive.openBox<User>(AppConstants.usersBox),
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

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Tema yapılandırması
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Router yapılandırması
      routerConfig: router,
    );
  }
}
