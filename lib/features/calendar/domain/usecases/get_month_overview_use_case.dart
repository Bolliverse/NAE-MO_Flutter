import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/calendar/domain/entities/month_overview.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/category/data/repositories/category_repository_provider.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_provider.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';

class GetMonthOverviewUseCase {
  const GetMonthOverviewUseCase(this._tasks, this._categories);

  final TaskRepository _tasks;
  final CategoryRepository _categories;

  Future<Result<MonthOverview>> call(DateTime selectedDate) async {
    final start = monthStartFor(selectedDate);
    final end = DateTime(start.year, start.month + 1, 0);
    final tasks = await _tasks.getTasksByRange(start, end);
    if (tasks.failure != null) return fail(tasks.failure!);
    final categories = await _categories.getCategories();
    if (categories.failure != null) return fail(categories.failure!);

    final categoriesById = <String, Category>{
      for (final category in categories.data!) category.id: category,
    };
    final buckets = List.generate(end.day, (_) => <TodayEntry>[]);
    for (final task in tasks.data!) {
      final day = localCalendarDay(task.targetDate);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      buckets[day.day - 1].add(TodayEntry(
        task: task,
        category: categoriesById[task.categoryId],
      ));
    }

    final days = <MonthDaySummary>[];
    for (var index = 0; index < buckets.length; index++) {
      final entries = buckets[index]..sort(_compareEntries);
      final byCategory = <String?, _MarkerCounts>{};
      for (final entry in entries) {
        final id = entry.task.categoryId;
        final counts =
            byCategory.putIfAbsent(id, () => _MarkerCounts(categoriesById[id]));
        if (entry.task.isEvent) {
          counts.hasEvent = true;
        } else {
          counts.todoCount++;
          if (entry.task.isCompleted) counts.completedCount++;
        }
      }
      final sortedIds = byCategory.keys.toList()
        ..sort((left, right) {
          final a = byCategory[left]!.category;
          final b = byCategory[right]!.category;
          if (a == null && b != null) return 1;
          if (a != null && b == null) return -1;
          if (a != null && b != null) {
            final order = a.sortOrder.compareTo(b.sortOrder);
            if (order != 0) return order;
            return a.id.compareTo(b.id);
          }
          return (left ?? '').compareTo(right ?? '');
        });
      days.add(MonthDaySummary(
        date: DateTime(start.year, start.month, index + 1),
        markers: [
          for (final id in sortedIds.take(4))
            MonthCategoryMarker(
              category: byCategory[id]!.category,
              shape: byCategory[id]!.hasEvent
                  ? byCategory[id]!.todoCount > 0
                      ? MonthMarkerShape.mixed
                      : MonthMarkerShape.event
                  : MonthMarkerShape.todo,
              isChecked: byCategory[id]!.todoCount > 0 &&
                  byCategory[id]!.todoCount == byCategory[id]!.completedCount,
            ),
        ],
        entries: entries,
      ));
    }
    return success(MonthOverview(start: start, days: days));
  }
}

class _MarkerCounts {
  _MarkerCounts(this.category);
  final Category? category;
  bool hasEvent = false;
  int todoCount = 0;
  int completedCount = 0;
}

int _compareEntries(TodayEntry left, TodayEntry right) {
  final a = left.task;
  final b = right.task;
  if (a.isEvent != b.isEvent) return a.isEvent ? -1 : 1;
  if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
  if (a.isTodo && a.isCompleted != b.isCompleted) {
    return a.isCompleted ? 1 : -1;
  }
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

final getMonthOverviewUseCaseProvider =
    Provider.autoDispose<GetMonthOverviewUseCase>(
        (ref) => GetMonthOverviewUseCase(
              ref.watch(taskRepositoryProvider),
              ref.watch(categoryRepositoryProvider),
            ));
