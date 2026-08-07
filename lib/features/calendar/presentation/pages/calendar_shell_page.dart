import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nae_mo/core/router/app_router.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:nae_mo/features/auth/presentation/viewmodels/auth_view_model.dart';

enum _CalendarMenuAction {
  routineManagement,
  categoryManagement,
  settings,
  signOut,
}

class CalendarShellPage extends ConsumerWidget {
  const CalendarShellPage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider).asData?.value;
    final location = GoRouterState.of(context).matchedLocation;

    ref.listen(authViewModelProvider, (previous, next) {
      final previousError = previous?.asData?.value.errorMessage;
      final nextState = next.asData?.value;
      final nextError = nextState?.errorMessage;
      final isStillSignedIn = nextState?.session is AuthenticatedSession;

      if (nextError != null && nextError != previousError && isStillSignedIn) {
        _showMessage(context, nextError);
      }
    });

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        title: const Text('NAE MO'),
        actions: [
          PopupMenuButton<_CalendarMenuAction>(
            key: const Key('calendarMoreMenu'),
            enabled: !(authState?.isSubmitting ?? false),
            tooltip: '더보기',
            onSelected: (action) => _handleMenuAction(context, ref, action),
            itemBuilder: (context) => const [
              PopupMenuItem(
                key: Key('routineManagementAction'),
                value: _CalendarMenuAction.routineManagement,
                child: Text('루틴 관리'),
              ),
              PopupMenuItem(
                key: Key('categoryManagementAction'),
                value: _CalendarMenuAction.categoryManagement,
                child: Text('카테고리 관리'),
              ),
              PopupMenuItem(
                key: Key('settingsAction'),
                value: _CalendarMenuAction.settings,
                child: Text('설정'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                key: Key('logoutAction'),
                value: _CalendarMenuAction.signOut,
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 12),
                    Text('로그아웃'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: child,
      floatingActionButton: FloatingActionButton(
        key: const Key('calendarAddButton'),
        tooltip: '추가',
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    _CalendarMenuAction action,
  ) {
    switch (action) {
      case _CalendarMenuAction.routineManagement:
        _showMessage(context, '루틴 관리 화면은 다음 작업에서 제공됩니다.');
        break;
      case _CalendarMenuAction.categoryManagement:
        _showMessage(context, '카테고리 관리 화면은 다음 작업에서 제공됩니다.');
        break;
      case _CalendarMenuAction.settings:
        _showMessage(context, '설정 화면은 다음 작업에서 제공됩니다.');
        break;
      case _CalendarMenuAction.signOut:
        ref.read(authViewModelProvider.notifier).signOut();
        break;
    }
  }

  Future<void> _showAddSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('addEventAction'),
              leading: const Icon(Icons.event_outlined),
              title: const Text('일정 추가'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showMessage(context, '일정 추가 화면은 다음 작업에서 제공됩니다.');
              },
            ),
            ListTile(
              key: const Key('addTodoAction'),
              leading: const Icon(Icons.check_box_outlined),
              title: const Text('투두 추가'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showMessage(context, '투두 추가 화면은 다음 작업에서 제공됩니다.');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
