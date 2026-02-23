import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nae_mo/features/calendar/presentation/pages/calendar_shell_page.dart';
import 'package:nae_mo/features/calendar/presentation/pages/day_view_page.dart';
import 'package:nae_mo/features/calendar/presentation/pages/month_view_page.dart';
import 'package:nae_mo/features/calendar/presentation/pages/week_view_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.day,
    debugLogDiagnostics: true,
    routes: [
      ShellRoute(
        builder: (context, state, child) => CalendarShellPage(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.day,
            name: 'day',
            builder: (context, state) => const DayViewPage(),
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
  static const String day = '/calendar/day';
  static const String week = '/calendar/week';
  static const String month = '/calendar/month';
}
