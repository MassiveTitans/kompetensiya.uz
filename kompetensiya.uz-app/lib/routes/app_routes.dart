import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/vacancies_list_screen/vacancies_list_screen.dart';
import '../presentation/assessment_screen/assessment_screen.dart';
import '../presentation/community_screen/community_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/attendance_screen/attendance_screen.dart';
import '../presentation/kpi_screen/kpi_screen.dart';
import '../presentation/test_screen/test_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splashScreen = '/';
  static const String onboardingScreen = '/onboarding-screen';
  static const String loginScreen = '/login-screen';
  static const String homeScreen = '/home-screen';
  static const String vacanciesListScreen = '/vacancies-list-screen';
  static const String assessmentScreen = '/assessment-screen';
  static const String communityScreen = '/community-screen';
  static const String profileScreen = '/profile-screen';
  static const String attendanceScreen = '/attendance-screen';
  static const String kpiScreen = '/kpi-screen';
  static const String testScreen = '/test-screen';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  routes: [
    // Splash screen — entry point
    GoRoute(
      path: AppRoutes.splashScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    ),

    // Onboarding carousel
    GoRoute(
      path: AppRoutes.onboardingScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    ),

    // Auth screen — outside shell
    GoRoute(
      path: AppRoutes.loginScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    ),

    // Attendance screen — accessible from Profile (outside shell)
    GoRoute(
      path: AppRoutes.attendanceScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AttendanceScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    ),

    // KPI screen — accessible from Profile (outside shell)
    GoRoute(
      path: AppRoutes.kpiScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const KpiScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    ),

    // Test screen — accessible from Assessment (outside shell)
    GoRoute(
      path: AppRoutes.testScreen,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final assessment = extra?['assessment'] as Map<String, dynamic>? ?? {};
        final isPsychological = extra?['isPsychological'] as bool? ?? false;
        return CustomTransitionPage(
          key: state.pageKey,
          child: TestScreen(
            assessment: assessment,
            isPsychological: isPsychological,
          ),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        );
      },
    ),

    // Shell — bottom nav screens
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.homeScreen,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Branch 1: Assessment
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.assessmentScreen,
              builder: (context, state) => const AssessmentScreen(),
            ),
          ],
        ),
        // Branch 2: Vacancies
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.vacanciesListScreen,
              builder: (context, state) => const VacanciesListScreen(),
            ),
          ],
        ),
        // Branch 3: Community
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.communityScreen,
              builder: (context, state) => const CommunityScreen(),
            ),
          ],
        ),
        // Branch 4: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profileScreen,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
