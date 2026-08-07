import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:nae_mo/features/auth/presentation/pages/auth_loading_page.dart';
import 'package:nae_mo/features/auth/presentation/pages/login_page.dart';
import 'package:nae_mo/features/auth/presentation/states/auth_state.dart';
import 'package:nae_mo/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:nae_mo/features/calendar/presentation/pages/calendar_shell_page.dart';
import 'package:nae_mo/features/calendar/presentation/pages/month_view_page.dart';
import 'package:nae_mo/features/calendar/presentation/pages/today_page.dart';
import 'package:nae_mo/features/calendar/presentation/pages/week_view_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  final authSubscription = ref.listen(
    authViewModelProvider,
    (_, __) => refreshNotifier.refresh(),
  );

  final router = GoRouter(
    initialLocation: AppRoutes.bootstrap,
    refreshListenable: refreshNotifier,
    redirect: (context, state) => _authRedirect(
      ref.read(authViewModelProvider),
      state,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.bootstrap,
        name: 'bootstrap',
        builder: (context, state) => const AuthLoadingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => CalendarShellPage(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.today,
            name: 'today',
            builder: (context, state) => const TodayPage(),
          ),
          GoRoute(
            path: AppRoutes.day,
            name: 'legacy-day',
            redirect: (context, state) => AppRoutes.today,
          ),
          GoRoute(
            path: AppRoutes.week,
            name: 'week',
            builder: (context, state) => const WeekViewPage(),
          ),
          GoRoute(
            path: AppRoutes.month,
            name: 'month',
            builder: (context, state) => const MonthViewPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(error: '${state.error}'),
  );

  ref.onDispose(() {
    authSubscription.close();
    refreshNotifier.dispose();
    router.dispose();
  });

  return router;
});

String? _authRedirect(
  AsyncValue<AuthState> authValue,
  GoRouterState routerState,
) {
  final location = routerState.matchedLocation;
  final isBootstrap = location == AppRoutes.bootstrap;
  final isLogin = location == AppRoutes.login;

  if (authValue.isLoading) {
    return isBootstrap ? null : AppRoutes.bootstrap;
  }

  final isAuthenticated =
      authValue.asData?.value.session is AuthenticatedSession;

  if (!isAuthenticated) {
    return isLogin ? null : AppRoutes.login;
  }

  if (isBootstrap || isLogin) return AppRoutes.today;
  return null;
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

class ErrorPage extends StatelessWidget {
  final String error;
  const ErrorPage({required this.error, super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Text('페이지를 찾을 수 없습니다: $error')),
      );
}

abstract class AppRoutes {
  static const String bootstrap = '/bootstrap';
  static const String login = '/login';
  static const String today = '/calendar/today';
  static const String day = '/calendar/day';
  static const String week = '/calendar/week';
  static const String month = '/calendar/month';
}
