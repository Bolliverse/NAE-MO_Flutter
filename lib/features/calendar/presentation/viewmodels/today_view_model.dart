import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/domain/usecases/get_today_overview_use_case.dart';
import 'package:nae_mo/features/calendar/presentation/states/today_state.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/usecases/toggle_complete_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'today_view_model.g.dart';

@riverpod
class TodayViewModel extends _$TodayViewModel {
  @override
  Future<TodayState> build() async {
    final selectedDate = ref.watch(selectedDateProvider);
    final result = await ref.read(getTodayOverviewUseCaseProvider)(
      selectedDate,
    );

    return result.fold(
      onSuccess: (overview) => TodayState(overview: overview),
      onFailure: (failure) => throw failure,
    );
  }

  void retry() => ref.invalidateSelf();

  void toggleOverdueSection() {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        isOverdueExpanded: !current.isOverdueExpanded,
      ),
    );
  }

  void toggleCompletedSection() {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        isCompletedExpanded: !current.isCompletedExpanded,
      ),
    );
  }

  Future<Failure?> toggleTodo(String taskId) async {
    final previous = state.valueOrNull;
    if (previous == null || previous.pendingTodoIds.contains(taskId)) {
      return null;
    }

    final optimistic = _toggleCompletion(previous, taskId);
    if (optimistic == null) return null;

    state = AsyncData(
      optimistic.copyWith(
        pendingTodoIds: {...optimistic.pendingTodoIds, taskId},
      ),
    );

    final result = await ref.read(toggleCompleteUseCaseProvider)(taskId);
    final failure = result.failure;
    if (failure != null) {
      if (state.valueOrNull?.overview.date == previous.overview.date) {
        state = AsyncData(previous);
      }
      return failure;
    }

    final current = state.valueOrNull;
    if (current != null && current.overview.date == previous.overview.date) {
      state = AsyncData(
        current.copyWith(
          pendingTodoIds: {...current.pendingTodoIds}..remove(taskId),
        ),
      );
    }
    return null;
  }
}

TodayState? _toggleCompletion(TodayState state, String taskId) {
  final source = _findTodo(state.overview, taskId);
  if (source == null) return null;

  final overview = state.overview;
  final toggled = TodayEntry(
    task: _copyWithInverseCompletion(source.task),
    category: source.category,
  );
  final overdueTodos = _withoutTask(overview.overdueTodos, taskId);
  final allDayEvents = _withoutTask(overview.allDayEvents, taskId);
  final timelineItems = _withoutTask(overview.timelineItems, taskId);
  final untimedTodos = _withoutTask(overview.untimedTodos, taskId);
  final completedTodos = _withoutTask(overview.completedTodos, taskId);
  final targetDate = _localDate(toggled.task.targetDate);
  final selectedDate = _localDate(overview.date);

  if (toggled.task.isCompleted) {
    if (targetDate == selectedDate) {
      completedTodos.add(toggled);
    }
  } else if (targetDate.isBefore(selectedDate)) {
    overdueTodos.add(toggled);
  } else if (targetDate == selectedDate) {
    if (toggled.task.hasTime) {
      timelineItems.add(toggled);
    } else {
      untimedTodos.add(toggled);
    }
  }

  return state.copyWith(
    overview: TodayOverview(
      date: overview.date,
      overdueTodos: List.unmodifiable(overdueTodos),
      allDayEvents: List.unmodifiable(allDayEvents),
      timelineItems: List.unmodifiable(timelineItems),
      untimedTodos: List.unmodifiable(untimedTodos),
      completedTodos: List.unmodifiable(completedTodos),
    ),
  );
}

TodayEntry? _findTodo(TodayOverview overview, String taskId) {
  final entries = [
    ...overview.overdueTodos,
    ...overview.allDayEvents,
    ...overview.timelineItems,
    ...overview.untimedTodos,
    ...overview.completedTodos,
  ];

  for (final entry in entries) {
    if (entry.task.id == taskId && entry.task.isTodo) return entry;
  }
  return null;
}

List<TodayEntry> _withoutTask(List<TodayEntry> entries, String taskId) {
  return entries.where((entry) => entry.task.id != taskId).toList();
}

Task _copyWithInverseCompletion(Task task) {
  return Task(
    id: task.id,
    title: task.title,
    kind: task.kind,
    targetDate: task.targetDate,
    categoryId: task.categoryId,
    isCompleted: !task.isCompleted,
    hasTime: task.hasTime,
    startDateTime: task.startDateTime,
    endDateTime: task.endDateTime,
    isAllDay: task.isAllDay,
    isRecurring: task.isRecurring,
    recurrenceRule: task.recurrenceRule,
    createdAt: task.createdAt,
  );
}

DateTime _localDate(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
