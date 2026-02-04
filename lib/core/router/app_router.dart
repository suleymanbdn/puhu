import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/tasks/views/tasks_view.dart';
import '../../features/calendar/views/calendar_view.dart';
import '../../features/timer/views/timer_view.dart';
import '../../features/stats/views/stats_view.dart';
import '../../shared/widgets/main_scaffold.dart';

/// Uygulama route isimleri
class AppRoutes {
  AppRoutes._();

  static const String tasks = '/tasks';
  static const String calendar = '/calendar';
  static const String timer = '/timer';
  static const String stats = '/stats';
}

/// Router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.tasks,
    debugLogDiagnostics: true,
    routes: [
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
        ],
      ),
    ],
  );
});

/// Eski GoRouter yapılandırması - geriye dönük uyumluluk için
final appRouter = GoRouter(
  initialLocation: AppRoutes.tasks,
  debugLogDiagnostics: true,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
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
      ],
    ),
  ],
);
