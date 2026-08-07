import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nae_mo/core/router/app_router.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:nae_mo/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/expandable_menu_fab.dart';

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
      body: SafeArea(child: child),
      floatingActionButton: ExpandableMenuFab(
        onSelected: (action) => _handleGlobalAction(
          context,
          ref,
          action,
          isSubmitting: authState?.isSubmitting ?? false,
          returnLocation: location,
        ),
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
      BuildContext context, WidgetRef ref, DailyGlobalAction action,
      {required bool isSubmitting, required String returnLocation}) {
    switch (action) {
      case DailyGlobalAction.add:
        context.go(
          Uri(
            path: AppRoutes.add,
            queryParameters: {'from': returnLocation},
          ).toString(),
        );
      case DailyGlobalAction.routine:
        _showMessage(context, '루틴 관리 화면은 다음 작업에서 제공됩니다.');
      case DailyGlobalAction.category:
        _showMessage(context, '카테고리 관리 화면은 다음 작업에서 제공됩니다.');
      case DailyGlobalAction.settings:
        _showSettingsSheet(
          context,
          ref,
          isSubmitting: isSubmitting,
        );
    }
  }

  Future<void> _showSettingsSheet(
    BuildContext context,
    WidgetRef ref, {
    required bool isSubmitting,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        key: const Key('settingsSheet'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '설정',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ListTile(
                key: const Key('logoutAction'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.logout_rounded),
                title: const Text('로그아웃'),
                onTap: isSubmitting
                    ? null
                    : () {
                        Navigator.of(sheetContext).pop();
                        ref.read(authViewModelProvider.notifier).signOut();
                      },
              ),
            ],
          ),
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
