import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/domain/entities/week_overview.dart';
import 'package:nae_mo/features/category/data/repositories/category_repository_provider.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_provider.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';

class GetWeekOverviewUseCase {
  const GetWeekOverviewUseCase(this._tasks, this._categories);
  final TaskRepository _tasks;
  final CategoryRepository _categories;

  Future<Result<WeekOverview>> call(DateTime selectedDate) async {
    final start = weekStartFor(selectedDate);
    final tasks =
        await _tasks.getTasksByRange(start, calendarDayOffset(start, 6));
    if (tasks.failure != null) return fail(tasks.failure!);
    final categories = await _categories.getCategories();
    if (categories.failure != null) return fail(categories.failure!);
    final byId = {
      for (final category in categories.data!) category.id: category
    };
    final buckets = List.generate(7, (_) => <TodayEntry>[]);
    for (final task in tasks.data!) {
      final local = task.targetDate.toLocal();
      final date = DateTime(local.year, local.month, local.day);
      if (date.isBefore(start) || date.isAfter(calendarDayOffset(start, 6))) {
        continue;
      }
      buckets[date.weekday - 1]
          .add(TodayEntry(task: task, category: byId[task.categoryId]));
    }
    final days = <WeekDaySummary>[];
    for (var index = 0; index < 7; index++) {
      final events = buckets[index]
          .where((entry) => entry.task.isEvent)
          .toList()
        ..sort(_compare);
      final todos = buckets[index].where((entry) => entry.task.isTodo).toList();
      final incomplete = todos
          .where((entry) => !entry.task.isCompleted)
          .toList()
        ..sort(_compare);
      days.add(WeekDaySummary(
          date: calendarDayOffset(start, index),
          events: events.take(2).toList(),
          firstTodo: incomplete.isEmpty ? null : incomplete.first,
          eventCount: events.length,
          todoCount: todos.length,
          completedTodoCount: todos.length - incomplete.length));
    }
    return success(WeekOverview(start: start, days: days));
  }
}

int _compare(TodayEntry left, TodayEntry right) {
  final a = left.task;
  final b = right.task;
  if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
  final aTime = a.startDateTime;
  final bTime = b.startDateTime;
  if (aTime != null && bTime == null) return -1;
  if (aTime == null && bTime != null) return 1;
  if (aTime != null && bTime != null) {
    final comparison = aTime.compareTo(bTime);
    if (comparison != 0) return comparison;
  }
  final created = a.createdAt.compareTo(b.createdAt);
  return created != 0 ? created : a.id.compareTo(b.id);
}

final getWeekOverviewUseCaseProvider =
    Provider.autoDispose<GetWeekOverviewUseCase>(
  (ref) => GetWeekOverviewUseCase(
      ref.watch(taskRepositoryProvider), ref.watch(categoryRepositoryProvider)),
);
