import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/core/router/app_router.dart';

enum _CalendarView { day, week, month }

class CalendarShellPage extends ConsumerWidget {
  final Widget child;
  const CalendarShellPage({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final activeView = _activeView(location);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: _DateNavigator(
          date: selectedDate,
          view: activeView,
          onPrev: () => ref.read(selectedDateProvider.notifier).addDays(
                _daysToShift(activeView, forward: false),
              ),
          onNext: () => ref.read(selectedDateProvider.notifier).addDays(
                _daysToShift(activeView, forward: true),
              ),
          onTodayTap: () =>
              ref.read(selectedDateProvider.notifier).goToToday(),
        ),
        actions: [
          _ViewSwitcher(
            active: activeView,
            onChanged: (view) => _navigateTo(context, view),
          ),
          const SizedBox(width: 8),
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
            _label(),
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

  String _label() => switch (view) {
        _CalendarView.day =>
          DateFormat('M월 d일 (E)', 'ko').format(date),
        _CalendarView.week =>
          '${DateFormat('M월 d일', 'ko').format(date)} 주',
        _CalendarView.month =>
          DateFormat('yyyy년 M월', 'ko').format(date),
      };
}

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
