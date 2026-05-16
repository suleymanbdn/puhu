import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences örneği için provider (main'de override edilmeli veya asenkron başlatılmalı)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider override edilmedi');
});

// Ayarlar durumu
class SettingsState {
  final int workDuration; // dakika
  final int shortBreakDuration;
  final int longBreakDuration;
  final bool autoFlow; // Çalışma bitince otomatik molaya geç
  final bool notificationsEnabled; // Süre dolduğunda bildirim ver

  const SettingsState({
    this.workDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.autoFlow = false,
    this.notificationsEnabled = true,
  });

  SettingsState copyWith({
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    bool? autoFlow,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      autoFlow: autoFlow ?? this.autoFlow,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

// Ayarlar yöneticisi
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this.prefs) : super(const SettingsState()) {
    _loadSettings();
  }

  final SharedPreferences prefs;

  static const _kWork = 'pref_work_duration';
  static const _kShort = 'pref_short_break';
  static const _kLong = 'pref_long_break';
  static const _kAutoFlow = 'pref_auto_flow';
  static const _kNotifications = 'pref_notifications';

  void _loadSettings() {
    state = SettingsState(
      workDuration: prefs.getInt(_kWork) ?? 25,
      shortBreakDuration: prefs.getInt(_kShort) ?? 5,
      longBreakDuration: prefs.getInt(_kLong) ?? 15,
      autoFlow: prefs.getBool(_kAutoFlow) ?? false,
      notificationsEnabled: prefs.getBool(_kNotifications) ?? true,
    );
  }

  Future<void> setWorkDuration(int minutes) async {
    await prefs.setInt(_kWork, minutes);
    state = state.copyWith(workDuration: minutes);
  }

  Future<void> setShortBreakDuration(int minutes) async {
    await prefs.setInt(_kShort, minutes);
    state = state.copyWith(shortBreakDuration: minutes);
  }

  Future<void> setLongBreakDuration(int minutes) async {
    await prefs.setInt(_kLong, minutes);
    state = state.copyWith(longBreakDuration: minutes);
  }

  Future<void> setAutoFlow(bool enabled) async {
    await prefs.setBool(_kAutoFlow, enabled);
    state = state.copyWith(autoFlow: enabled);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await prefs.setBool(_kNotifications, enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }
}

// Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
