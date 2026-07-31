import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/core/router/app_router.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:nae_mo/features/auth/presentation/viewmodels/auth_view_model.dart';

enum _CalendarView { day, week, month }

enum _CalendarMenuAction { day, week, month, signOut }

class CalendarShellPage extends ConsumerWidget {
  final Widget child;
  const CalendarShellPage({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final authState = ref.watch(authViewModelProvider).asData?.value;
    final location = GoRouterState.of(context).matchedLocation;
    final activeView = _activeView(location);
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    void shiftBack() => ref.read(selectedDateProvider.notifier).addDays(
          _daysToShift(activeView, forward: false),
        );

    void shiftForward() => ref.read(selectedDateProvider.notifier).addDays(
          _daysToShift(activeView, forward: true),
        );

    void goToToday() => ref.read(selectedDateProvider.notifier).goToToday();

    ref.listen(authViewModelProvider, (previous, next) {
      final previousError = previous?.asData?.value.errorMessage;
      final nextState = next.asData?.value;
      final nextError = nextState?.errorMessage;
      final isStillSignedIn = nextState?.session is AuthenticatedSession;

      if (nextError != null && nextError != previousError && isStillSignedIn) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(nextError)),
          );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: isCompact
            ? IconButton(
                key: const Key('previousDateButton'),
                tooltip: '이전',
                icon: const Icon(Icons.chevron_left),
                onPressed: shiftBack,
              )
            : null,
        title: isCompact
            ? _DateTitle(
                date: selectedDate,
                view: activeView,
                onTodayTap: goToToday,
              )
            : _DateNavigator(
                date: selectedDate,
                view: activeView,
                onPrev: shiftBack,
                onNext: shiftForward,
                onTodayTap: goToToday,
              ),
        actions: [
          if (isCompact)
            IconButton(
              key: const Key('nextDateButton'),
              tooltip: '다음',
              icon: const Icon(Icons.chevron_right),
              onPressed: shiftForward,
            ),
          if (!isCompact)
            _ViewSwitcher(
              active: activeView,
              onChanged: (view) => _navigateTo(context, view),
            ),
          PopupMenuButton<_CalendarMenuAction>(
            key: const Key('calendarMoreMenu'),
            enabled: !(authState?.isSubmitting ?? false),
            tooltip: '더보기',
            onSelected: (action) {
              switch (action) {
                case _CalendarMenuAction.day:
                  _navigateTo(context, _CalendarView.day);
                  break;
                case _CalendarMenuAction.week:
                  _navigateTo(context, _CalendarView.week);
                  break;
                case _CalendarMenuAction.month:
                  _navigateTo(context, _CalendarView.month);
                  break;
                case _CalendarMenuAction.signOut:
                  ref.read(authViewModelProvider.notifier).signOut();
                  break;
              }
            },
            itemBuilder: (context) => _menuItems(
              activeView: activeView,
              includeViewSwitcher: isCompact,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: child,
    );
  }

  _CalendarView _activeView(String location) {
    if (location.contains('/week')) return _CalendarView.week;
    if (location.contains('/month')) return _CalendarView.month;
    return _CalendarView.day;
  }

  int _daysToShift(_CalendarView view, {required bool forward}) {
    final sign = forward ? 1 : -1;
    return switch (view) {
      _CalendarView.day => 1 * sign,
      _CalendarView.week => 7 * sign,
      _CalendarView.month => 30 * sign, // MonthView에서 정밀 처리
    };
  }

  void _navigateTo(BuildContext context, _CalendarView view) {
    final path = switch (view) {
      _CalendarView.day => AppRoutes.day,
      _CalendarView.week => AppRoutes.week,
      _CalendarView.month => AppRoutes.month,
    };
    context.go(path);
  }

  List<PopupMenuEntry<_CalendarMenuAction>> _menuItems({
    required _CalendarView activeView,
    required bool includeViewSwitcher,
  }) {
    return [
      if (includeViewSwitcher) ...[
        CheckedPopupMenuItem(
          value: _CalendarMenuAction.day,
          checked: activeView == _CalendarView.day,
          child: const Text('일 보기'),
        ),
        CheckedPopupMenuItem(
          value: _CalendarMenuAction.week,
          checked: activeView == _CalendarView.week,
          child: const Text('주 보기'),
        ),
        CheckedPopupMenuItem(
          value: _CalendarMenuAction.month,
          checked: activeView == _CalendarView.month,
          child: const Text('월 보기'),
        ),
        const PopupMenuDivider(),
      ],
      const PopupMenuItem(
        value: _CalendarMenuAction.signOut,
        child: Row(
          children: [
            Icon(Icons.logout),
            SizedBox(width: 12),
            Text('로그아웃'),
          ],
        ),
      ),
    ];
  }
}

// ── 날짜 네비게이터 ────────────────────────────────────────────
class _DateNavigator extends StatelessWidget {
  final DateTime date;
  final _CalendarView view;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTodayTap;

  const _DateNavigator({
    required this.date,
    required this.view,
    required this.onPrev,
    required this.onNext,
    required this.onTodayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
          visualDensity: VisualDensity.compact,
        ),
        GestureDetector(
          onTap: onTodayTap,
          child: Text(
            _dateLabel(date, view),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _DateTitle extends StatelessWidget {
  final DateTime date;
  final _CalendarView view;
  final VoidCallback onTodayTap;

  const _DateTitle({
    required this.date,
    required this.view,
    required this.onTodayTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTodayTap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _dateLabel(date, view),
          maxLines: 1,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date, _CalendarView view) => switch (view) {
      _CalendarView.day => DateFormat('M월 d일 (E)', 'ko').format(date),
      _CalendarView.week => '${DateFormat('M월 d일', 'ko').format(date)} 주',
      _CalendarView.month => DateFormat('yyyy년 M월', 'ko').format(date),
    };

// ── 뷰 전환 버튼 ─────────────────────────────────────────────
class _ViewSwitcher extends StatelessWidget {
  final _CalendarView active;
  final ValueChanged<_CalendarView> onChanged;

  const _ViewSwitcher({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_CalendarView>(
      segments: const [
        ButtonSegment(value: _CalendarView.day, label: Text('일')),
        ButtonSegment(value: _CalendarView.week, label: Text('주')),
        ButtonSegment(value: _CalendarView.month, label: Text('월')),
      ],
      selected: {active},
      onSelectionChanged: (set) => onChanged(set.first),
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
