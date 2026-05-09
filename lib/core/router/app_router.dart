import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/views/calendar_view.dart';
import '../../features/dashboard/views/dashboard_view.dart';
import '../../features/exam/providers/exam_profile_provider.dart';
import '../../features/mocks/views/mock_exam_view.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../../features/questions/views/question_log_view.dart';
import '../../features/settings/views/settings_view.dart';
import '../../features/stats/views/stats_view.dart';
import '../../features/subjects/views/subjects_view.dart';
import '../../features/subjects/views/topic_list_view.dart';
import '../../features/timer/views/timer_view.dart';
import '../../shared/widgets/main_scaffold.dart';

/// Uygulama route isimleri
class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String subjects = '/subjects';
  static const String calendar = '/calendar';
  static const String timer = '/timer';
  static const String questions = '/questions';
  static const String stats = '/stats';
  static const String settings = '/settings';
  static const String mocks = '/mocks';
  // Eski path - geriye dönük uyumluluk
  static const String tasks = '/tasks';
}

/// Router provider — uygulamanın tek router kaynağı
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final profile = ref.read(examProfileProvider);
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (profile == null && !isOnboarding) {
        return AppRoutes.onboarding;
      }
      if (profile != null && isOnboarding) {
        return AppRoutes.home;
      }
      if (state.matchedLocation == AppRoutes.tasks) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: OnboardingView()),
      ),
      // Standalone (shell dışında push edilen) ekranlar
      GoRoute(
        path: '/subject/:id',
        name: 'subjectDetail',
        builder: (context, state) =>
            TopicListView(subjectId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.mocks,
        name: 'mocks',
        builder: (context, state) => const MockExamView(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsView(),
      ),
      GoRoute(
        path: AppRoutes.calendar,
        name: 'calendar',
        builder: (context, state) => const CalendarView(),
      ),
      // Alt navigation shell (5 sekme)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              name: 'home',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DashboardView()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.subjects,
              name: 'subjects',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SubjectsView()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.timer,
              name: 'timer',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: TimerView()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.questions,
              name: 'questions',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: QuestionLogView()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.stats,
              name: 'stats',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: StatsView()),
            ),
          ]),
        ],
      ),
    ],
  );
});
