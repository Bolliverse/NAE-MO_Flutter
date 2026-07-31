import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/category/data/repositories/category_repository_provider.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_provider.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_today_overview_use_case.g.dart';

class GetTodayOverviewUseCase {
  final TaskRepository _taskRepository;
  final CategoryRepository _categoryRepository;

  const GetTodayOverviewUseCase(
    this._taskRepository,
    this._categoryRepository,
  );

  Future<Result<TodayOverview>> call(DateTime selectedDate) async {
    final date = _localDate(selectedDate);

    final tasksResult = await _taskRepository.getTasksForTodayOverview(date);
    final tasksFailure = tasksResult.failure;
    if (tasksFailure != null) {
      return fail(tasksFailure);
    }

    final categoriesResult = await _categoryRepository.getCategories();
    final categoriesFailure = categoriesResult.failure;
    if (categoriesFailure != null) {
      return fail(categoriesFailure);
    }

    final categoriesById = <String, Category>{
      for (final category in categoriesResult.data!) category.id: category,
    };
    final overdueTodos = <TodayEntry>[];
    final allDayEvents = <TodayEntry>[];
    final timelineItems = <TodayEntry>[];
    final untimedTodos = <TodayEntry>[];
    final completedTodos = <TodayEntry>[];

    for (final task in tasksResult.data!) {
      final entry = TodayEntry(
        task: task,
        category: categoriesById[task.categoryId],
      );
      final targetDate = _localDate(task.targetDate);
      final isSelectedDate = targetDate.isAtSameMomentAs(date);

      if (task.isTodo && task.isCompleted && isSelectedDate) {
        completedTodos.add(entry);
      } else if (task.isTodo &&
          !task.isCompleted &&
          targetDate.isBefore(date)) {
        overdueTodos.add(entry);
      } else if (task.isEvent && task.isAllDay && isSelectedDate) {
        allDayEvents.add(entry);
      } else if (task.hasTime && isSelectedDate) {
        timelineItems.add(entry);
      } else if (task.isTodo && !task.isCompleted && isSelectedDate) {
        untimedTodos.add(entry);
      }
    }

    overdueTodos.sort(_compareOverdue);
    allDayEvents.sort(_compareByCategoryThenCreated);
    timelineItems.sort(_compareTimeline);
    untimedTodos.sort(_compareByCategoryThenCreated);
    completedTodos.sort(_compareByCreated);

    return success(
      TodayOverview(
        date: date,
        overdueTodos: List<TodayEntry>.unmodifiable(overdueTodos),
        allDayEvents: List<TodayEntry>.unmodifiable(allDayEvents),
        timelineItems: List<TodayEntry>.unmodifiable(timelineItems),
        untimedTodos: List<TodayEntry>.unmodifiable(untimedTodos),
        completedTodos: List<TodayEntry>.unmodifiable(completedTodos),
      ),
    );
  }
}

DateTime _localDate(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

int _compareOverdue(TodayEntry left, TodayEntry right) {
  final targetDate = _localDate(
    left.task.targetDate,
  ).compareTo(_localDate(right.task.targetDate));
  if (targetDate != 0) return targetDate;

  return _compareByCreated(left, right);
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

@riverpod
GetTodayOverviewUseCase getTodayOverviewUseCase(
  GetTodayOverviewUseCaseRef ref,
) =>
    GetTodayOverviewUseCase(
      ref.read(taskRepositoryProvider),
      ref.read(categoryRepositoryProvider),
    );
