import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/features/calendar/presentation/states/today_state.dart';
import 'package:nae_mo/features/calendar/presentation/viewmodels/today_view_model.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/daily_calendar_pane.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/daily_split_scaffold.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/daily_todo_pane.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/today_date_header.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayViewModelProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedDateNotifier = ref.read(selectedDateProvider.notifier);
    final dateHeader = TodayDateHeader(
      key: const Key('todayDateHeader'),
      selectedDate: selectedDate,
      onPrevious: () => selectedDateNotifier.addDays(-1),
      onNext: () => selectedDateNotifier.addDays(1),
    );

    return today.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => _TodayStatus(
        dateHeader: dateHeader,
        child: const Center(
          child: CircularProgressIndicator(
            key: Key('todayLoadingIndicator'),
            semanticsLabel: '오늘 일정 불러오는 중',
          ),
        ),
      ),
      error: (error, _) => _TodayError(
        dateHeader: dateHeader,
        message: error is Failure ? error.message : '잠시 후 다시 시도해주세요.',
        onRetry: () => ref.read(todayViewModelProvider.notifier).retry(),
      ),
      data: (state) => _TodayContent(
        state: state,
        dateHeader: dateHeader,
      ),
    );
  }
}

class _TodayError extends StatelessWidget {
  const _TodayError({
    required this.dateHeader,
    required this.message,
    required this.onRetry,
  });

  final Widget dateHeader;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _TodayStatus(
      dateHeader: dateHeader,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: colors.error,
              ),
              const SizedBox(height: 12),
              Text(
                '오늘 일정을 불러올 수 없어요.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('todayRetryButton'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayStatus extends StatelessWidget {
  const _TodayStatus({
    required this.dateHeader,
    required this.child,
  });

  final Widget dateHeader;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _TodayPageFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              children: [
                dateHeader,
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight / 2,
                  ),
                  child: child,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TodayContent extends ConsumerWidget {
  const _TodayContent({
    required this.state,
    required this.dateHeader,
  });

  final TodayState state;
  final Widget dateHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = state.overview;
    final calendarTimeline = overview.timelineItems
        .where((entry) => entry.task.isEvent)
        .toList(growable: false);
    final todoTimeline = overview.timelineItems
        .where((entry) => entry.task.isTodo)
        .toList(growable: false);
    final completedPinned = overview.completedTodos
        .where((entry) => !entry.task.hasTime)
        .toList(growable: false);
    final completedTimeline = overview.completedTodos
        .where((entry) => entry.task.hasTime)
        .toList(growable: false);
    final todoPinned = [
      ...overview.overdueTodos,
      ...overview.untimedTodos,
      ...completedPinned,
    ];
    final visibleTodoTimeline = [
      ...todoTimeline,
      ...completedTimeline,
    ];

    Future<void> toggleTodo(String taskId) async {
      final initiatingDate = overview.date;
      final failure =
          await ref.read(todayViewModelProvider.notifier).toggleTodo(taskId);
      if (failure == null || !context.mounted) return;
      if (!_isSameLocalDate(
        initiatingDate,
        ref.read(selectedDateProvider),
      )) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failure.message)));
    }

    return _TodayPageFrame(
      child: KeyedSubtree(
        key: const Key('todayContent'),
        child: DailySplitScaffold(
          key: const Key('dailySplitScaffold'),
          header: dateHeader,
          pinnedHeight: 220,
          initialTimelineOffset: 8 * dailyCalendarHourExtent - 24,
          calendarPinnedBuilder: (context, layout) => DailyCalendarPinned(
            key: const Key('dailyCalendarPinned'),
            entries: overview.allDayEvents,
            isCompact: layout.isCompact,
          ),
          todoPinnedBuilder: (context, layout) => DailyTodoPinned(
            key: const Key('dailyTodoPinned'),
            entries: todoPinned,
            selectedDate: overview.date,
            isCompact: layout.isCompact,
            pendingTodoIds: state.pendingTodoIds,
            onToggleTodo: toggleTodo,
          ),
          calendarTimelineBuilder: (context, layout) => DailyCalendarTimeline(
            key: const Key('dailyCalendarTimeline'),
            entries: calendarTimeline,
            isCompact: layout.isCompact,
          ),
          todoTimelineBuilder: (context, layout) => DailyTodoTimeline(
            key: const Key('dailyTodoTimeline'),
            entries: visibleTodoTimeline,
            isCompact: layout.isCompact,
            pendingTodoIds: state.pendingTodoIds,
            onToggleTodo: toggleTodo,
          ),
        ),
      ),
    );
  }
}

class _TodayPageFrame extends StatelessWidget {
  const _TodayPageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: child,
        ),
      ),
    );
  }
}

bool _isSameLocalDate(DateTime left, DateTime right) {
  final localLeft = left.toLocal();
  final localRight = right.toLocal();
  return localLeft.year == localRight.year &&
      localLeft.month == localRight.month &&
      localLeft.day == localRight.day;
}
