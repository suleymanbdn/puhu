/// Uygulama genelinde kullanılan sabit değerler
class AppConstants {
  AppConstants._();

  // Uygulama Bilgileri
  static const String appName = 'YKS Pusula';
  static const String appVersion = '1.0.0';

  /// Google Play paket adı (mağaza bağlantıları)
  static const String androidApplicationId = 'com.zamanyonetimi.app';

  static const String playStoreListingUrl =
      'https://play.google.com/store/apps/details?id=$androidApplicationId';

  // Hive Box İsimleri
  static const String tasksBox = 'tasks_box';
  static const String settingsBox = 'settings_box';
  static const String focusSessionsBox = 'focus_sessions_box';
  static const String timeBudgetsBox = 'time_budgets_box';
  static const String topicsBox = 'topics_box';
  static const String examProfileBox = 'exam_profile_box';
  static const String questionLogsBox = 'question_logs_box';
  static const String mockExamsBox = 'mock_exams_box';

  // SharedPreferences Keys
  static const String themeKey = 'theme_mode';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String languageKey = 'language';
  static const String onboardingCompletedKey = 'onboarding_completed';

  // Pomodoro Varsayılan Süreleri (dakika)
  static const int defaultWorkDuration = 25;
  static const int defaultShortBreakDuration = 5;
  static const int defaultLongBreakDuration = 15;

  // Animasyon Süreleri
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);
}

