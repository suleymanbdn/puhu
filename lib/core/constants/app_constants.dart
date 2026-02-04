/// Uygulama genelinde kullanılan sabit değerler
class AppConstants {
  AppConstants._();

  // Uygulama Bilgileri
  static const String appName = 'Zaman Yönetimi';
  static const String appVersion = '1.0.0';

  // Hive Box İsimleri
  static const String tasksBox = 'tasks_box';
  static const String settingsBox = 'settings_box';
  static const String focusSessionsBox = 'focus_sessions_box';
  static const String timeBudgetsBox = 'time_budgets_box';
  static const String usersBox = 'users_box';

  // SharedPreferences Keys
  static const String themeKey = 'theme_mode';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String languageKey = 'language';

  // Pomodoro Varsayılan Süreleri (dakika)
  static const int defaultWorkDuration = 25;
  static const int defaultShortBreakDuration = 5;
  static const int defaultLongBreakDuration = 15;

  // Animasyon Süreleri
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);
}

