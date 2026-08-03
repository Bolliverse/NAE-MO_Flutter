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
      final current = state.valueOrNull;
      if (current != null &&
          current.overview.date == previous.overview.date &&
          current.pendingTodoIds.contains(taskId)) {
        final reverted = _restoreCompletion(current, previous, taskId);
        state = AsyncData(
          reverted.copyWith(
            pendingTodoIds: {...reverted.pendingTodoIds}..remove(taskId),
          ),
        );
      }
      return failure;
    }

    final current = state.valueOrNull;
    if (current != null &&
        current.overview.date == previous.overview.date &&
        current.pendingTodoIds.contains(taskId)) {
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

  final toggled = TodayEntry(
    task: _copyWithInverseCompletion(source.task),
    category: source.category,
  );

  return _rebuildWithTodo(state, toggled);
}

TodayState _restoreCompletion(
  TodayState current,
  TodayState previous,
  String taskId,
) {
  final original = _findTodo(previous.overview, taskId);
  if (original == null) return current;

  return _rebuildWithTodo(current, original);
}

TodayState _rebuildWithTodo(TodayState state, TodayEntry todo) {
  final overview = state.overview;
  final taskId = todo.task.id;
  final overdueTodos = _withoutTask(overview.overdueTodos, taskId);
  final allDayEvents = _withoutTask(overview.allDayEvents, taskId);
  final timelineItems = _withoutTask(overview.timelineItems, taskId);
  final untimedTodos = _withoutTask(overview.untimedTodos, taskId);
  final completedTodos = _withoutTask(overview.completedTodos, taskId);
  final targetDate = _localDate(todo.task.targetDate);
  final selectedDate = _localDate(overview.date);

  if (todo.task.isCompleted) {
    if (targetDate == selectedDate) {
      completedTodos.add(todo);
    }
  } else if (targetDate.isBefore(selectedDate)) {
    overdueTodos.add(todo);
  } else if (targetDate == selectedDate) {
    if (todo.task.hasTime) {
      timelineItems.add(todo);
    } else {
      untimedTodos.add(todo);
    }
  }

  overdueTodos.sort(_compareOverdue);
  timelineItems.sort(_compareTimeline);
  untimedTodos.sort(_compareByCategoryThenCreated);
  completedTodos.sort(_compareByCreated);

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

int _compareOverdue(TodayEntry left, TodayEntry right) {
  final targetDate = _localDate(left.task.targetDate).compareTo(
    _localDate(right.task.targetDate),
  );
  if (targetDate != 0) return targetDate;

  return _compareByCreated(left, right);
}

int _compareTimeline(TodayEntry left, TodayEntry right) {
  final start = _compareNullableDateTime(
    left.task.startDateTime,
    right.task.startDateTime,
  );
  if (start != 0) return start;

  final end = _compareNullableDateTime(
    left.task.endDateTime,
    right.task.endDateTime,
  );
  if (end != 0) return end;

  return left.task.id.compareTo(right.task.id);
}

int _compareByCategoryThenCreated(TodayEntry left, TodayEntry right) {
  final leftCategory = left.category;
  final rightCategory = right.category;
  if (leftCategory == null && rightCategory != null) return 1;
  if (leftCategory != null && rightCategory == null) return -1;
  if (leftCategory != null && rightCategory != null) {
    final sortOrder = leftCategory.sortOrder.compareTo(rightCategory.sortOrder);
    if (sortOrder != 0) return sortOrder;
  }

  return _compareByCreated(left, right);
}

int _compareNullableDateTime(DateTime? left, DateTime? right) {
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;
  return left.compareTo(right);
}

int _compareByCreated(TodayEntry left, TodayEntry right) {
  final createdAt = left.task.createdAt.compareTo(right.task.createdAt);
  if (createdAt != 0) return createdAt;

  return left.task.id.compareTo(right.task.id);
}
