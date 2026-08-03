import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/features/calendar/presentation/states/today_state.dart';
import 'package:nae_mo/features/calendar/presentation/viewmodels/today_view_model.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/daily_split_scaffold.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/today_all_day_section.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/today_date_header.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/today_overdue_section.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/today_timeline_section.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/today_todo_section.dart';

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
          calendarPinnedBuilder: (context, layout) => _PanePresentation(
            key: const Key('dailyCalendarPinned'),
            layout: layout,
            expanded: TodayAllDaySection(
              key: const Key('todayAllDaySection'),
              entries: overview.allDayEvents,
            ),
          ),
          todoPinnedBuilder: (context, layout) => _PanePresentation(
            key: const Key('dailyTodoPinned'),
            layout: layout,
            expanded: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TodayOverdueSection(
                  key: const Key('todayOverdueSection'),
                  entries: overview.overdueTodos,
                  isExpanded: state.isOverdueExpanded,
                  pendingTodoIds: state.pendingTodoIds,
                  onToggleExpanded: ref
                      .read(todayViewModelProvider.notifier)
                      .toggleOverdueSection,
                  onToggleTodo: toggleTodo,
                ),
                TodayTodoSection(
                  key: const Key('todayUntimedSection'),
                  title: '시간 미정 할 일',
                  entries: overview.untimedTodos,
                  pendingTodoIds: state.pendingTodoIds,
                  onToggleTodo: toggleTodo,
                ),
              ],
            ),
          ),
          calendarTimelineBuilder: (context, layout) => _PanePresentation(
            key: const Key('dailyCalendarTimeline'),
            layout: layout,
            isTimeline: true,
            expanded: TodayTimelineSection(
              key: const Key('todayCalendarTimelineSection'),
              entries: calendarTimeline,
              pendingTodoIds: state.pendingTodoIds,
              onToggleTodo: toggleTodo,
            ),
          ),
          todoTimelineBuilder: (context, layout) => _PanePresentation(
            key: const Key('dailyTodoTimeline'),
            layout: layout,
            isTimeline: true,
            expanded: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TodayTimelineSection(
                  key: const Key('todayTodoTimelineSection'),
                  entries: todoTimeline,
                  pendingTodoIds: state.pendingTodoIds,
                  onToggleTodo: toggleTodo,
                ),
                TodayTodoSection(
                  key: const Key('todayCompletedSection'),
                  title: '완료한 할 일',
                  entries: overview.completedTodos,
                  pendingTodoIds: state.pendingTodoIds,
                  onToggleTodo: toggleTodo,
                  isCompletedPresentation: true,
                  isExpanded: state.isCompletedExpanded,
                  onToggleExpanded: ref
                      .read(todayViewModelProvider.notifier)
                      .toggleCompletedSection,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanePresentation extends StatelessWidget {
  const _PanePresentation({
    super.key,
    required this.layout,
    required this.expanded,
    this.isTimeline = false,
  });

  final DailyPaneLayout layout;
  final Widget expanded;
  final bool isTimeline;

  @override
  Widget build(BuildContext context) {
    if (!layout.isCompact) {
      if (isTimeline) return expanded;
      return SingleChildScrollView(
        primary: false,
        child: expanded,
      );
    }

    const surface = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          vertical: BorderSide(color: Color(0xFFE5E5E5)),
        ),
      ),
    );
    if (isTimeline) return const SizedBox(height: 960, child: surface);
    return const SizedBox.expand(child: surface);
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
