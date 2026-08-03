import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nae_mo/core/router/app_router.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/expandable_menu_fab.dart';

class CalendarShellPage extends StatelessWidget {
  const CalendarShellPage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: SafeArea(child: child),
      floatingActionButton: ExpandableMenuFab(
        onSelected: (action) => _handleGlobalAction(context, action),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _activeIndex(location),
        onDestinationSelected: (index) => _navigateTo(context, index),
        destinations: const [
          NavigationDestination(
            key: Key('calendarTodayDestination'),
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '오늘',
          ),
          NavigationDestination(
            key: Key('calendarWeekDestination'),
            icon: Icon(Icons.view_week_outlined),
            selectedIcon: Icon(Icons.view_week),
            label: '주간',
          ),
          NavigationDestination(
            key: Key('calendarMonthDestination'),
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '월간',
          ),
        ],
      ),
    );
  }

  int _activeIndex(String location) {
    if (location == AppRoutes.week) return 1;
    if (location == AppRoutes.month) return 2;
    return 0;
  }

  void _navigateTo(BuildContext context, int index) {
    final route = switch (index) {
      1 => AppRoutes.week,
      2 => AppRoutes.month,
      _ => AppRoutes.today,
    };
    context.go(route);
  }

  void _handleGlobalAction(
    BuildContext context,
    DailyGlobalAction action,
  ) {
    final message = switch (action) {
      DailyGlobalAction.add => '새 항목 추가 화면은 다음 작업에서 제공됩니다.',
      DailyGlobalAction.routine => '루틴 관리 화면은 다음 작업에서 제공됩니다.',
      DailyGlobalAction.category => '카테고리 관리 화면은 다음 작업에서 제공됩니다.',
      DailyGlobalAction.settings => '설정 화면은 다음 작업에서 제공됩니다.',
    };
    _showMessage(context, message);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
