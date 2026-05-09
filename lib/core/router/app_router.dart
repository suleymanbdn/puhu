import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/exam/providers/exam_profile_provider.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../../features/tasks/views/tasks_view.dart';
import '../../features/calendar/views/calendar_view.dart';
import '../../features/timer/views/timer_view.dart';
import '../../features/stats/views/stats_view.dart';
import '../../features/settings/views/settings_view.dart';
import '../../shared/widgets/main_scaffold.dart';

/// Uygulama route isimleri
class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding';
  static const String tasks = '/tasks';
  static const String calendar = '/calendar';
  static const String timer = '/timer';
  static const String stats = '/stats';
  static const String settings = '/settings';
}

/// Router provider — uygulamanın tek router kaynağı
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.tasks,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final profile = ref.read(examProfileProvider);
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      // Onboarding tamamlanmadıysa zorla onboarding'e yönlendir
      if (profile == null && !isOnboarding) {
        return AppRoutes.onboarding;
      }
      // Tamamlandıysa onboarding'e gitmesine izin verme
      if (profile != null && isOnboarding) {
        return AppRoutes.tasks;
      }
      return null;
    },
    routes: [
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: OnboardingView(),
        ),
      ),
      // Shell route - Alt navigasyon barı için
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Görevler
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tasks,
                name: 'tasks',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TasksView(),
                ),
              ),
            ],
          ),
          // Takvim
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                name: 'calendar',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CalendarView(),
                ),
              ),
            ],
          ),
          // Zamanlayıcı
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.timer,
                name: 'timer',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TimerView(),
                ),
              ),
            ],
          ),
          // İstatistikler
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.stats,
                name: 'stats',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: StatsView(),
                ),
              ),
            ],
          ),
          // Ayarlar
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsView(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
