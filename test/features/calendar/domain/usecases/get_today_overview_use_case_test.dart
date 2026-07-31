import 'package:flutter_test/flutter_test.dart' hide fail;
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/domain/usecases/get_today_overview_use_case.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';

void main() {
  group('GetTodayOverviewUseCase', () {
    test('normalizes, joins, classifies, and stably sorts every task once',
        () async {
      final selectedDate = DateTime.utc(2026, 7, 31, 15, 42);
      final local = selectedDate.toLocal();
      final date = DateTime(local.year, local.month, local.day);
      final twoDaysEarlier = DateTime(date.year, date.month, date.day - 2);
      final oneDayEarlier = DateTime(date.year, date.month, date.day - 1);
      final createdEarly = DateTime(2026, 7, 1, 8);
      final createdLater = DateTime(2026, 7, 1, 9);
      const firstCategory = Category(
        id: 'category-first',
        name: 'First',
        color: 0xFF000001,
        sortOrder: 1,
      );
      const secondCategory = Category(
        id: 'category-second',
        name: 'Second',
        color: 0xFF000002,
        sortOrder: 2,
      );

      final tasks = <Task>[
        _task(
          id: 'timeline-start-later',
          kind: TaskKind.todo,
          targetDate: date,
          categoryId: secondCategory.id,
          hasTime: true,
          startDateTime: DateTime(date.year, date.month, date.day, 10),
          endDateTime: DateTime(date.year, date.month, date.day, 11),
          createdAt: createdEarly,
        ),
        _task(
          id: 'all-day-missing-b',
          kind: TaskKind.event,
          targetDate: date,
          categoryId: 'unknown-category',
          isAllDay: true,
          createdAt: createdEarly,
        ),
        _task(
          id: 'completed-later',
          targetDate: date,
          categoryId: firstCategory.id,
          isCompleted: true,
          createdAt: createdLater,
        ),
        _task(
          id: 'overdue-created-later',
          targetDate: oneDayEarlier,
          createdAt: createdLater,
        ),
        _task(
          id: 'untimed-created-later',
          targetDate: date,
          categoryId: firstCategory.id,
          createdAt: createdLater,
        ),
        _task(
          id: 'all-day-second-category',
          kind: TaskKind.event,
          targetDate: date,
          categoryId: secondCategory.id,
          isAllDay: true,
          createdAt: createdEarly,
        ),
        _task(
          id: 'timeline-b',
          targetDate: date,
          categoryId: firstCategory.id,
          hasTime: true,
          startDateTime: DateTime(date.year, date.month, date.day, 9),
          endDateTime: DateTime(date.year, date.month, date.day, 10),
          createdAt: createdLater,
        ),
        _task(
          id: 'overdue-b',
          targetDate: oneDayEarlier,
          hasTime: true,
          startDateTime: DateTime(
            oneDayEarlier.year,
            oneDayEarlier.month,
            oneDayEarlier.day,
            10,
          ),
          endDateTime: DateTime(
            oneDayEarlier.year,
            oneDayEarlier.month,
            oneDayEarlier.day,
            11,
          ),
          createdAt: createdEarly,
        ),
        _task(
          id: 'completed-b',
          targetDate: date,
          categoryId: secondCategory.id,
          isCompleted: true,
          createdAt: createdEarly,
        ),
        _task(
          id: 'all-day-b',
          kind: TaskKind.event,
          targetDate: date,
          categoryId: firstCategory.id,
          isAllDay: true,
          createdAt: createdEarly,
        ),
        _task(
          id: 'untimed-missing-b',
          targetDate: date,
          categoryId: 'unknown-category',
          createdAt: createdEarly,
        ),
        _task(
          id: 'timeline-end-later',
          kind: TaskKind.event,
          targetDate: date,
          hasTime: true,
          startDateTime: DateTime(date.year, date.month, date.day, 9),
          endDateTime: DateTime(date.year, date.month, date.day, 11),
          createdAt: createdEarly,
        ),
        _task(
          id: 'overdue-earliest',
          targetDate: twoDaysEarlier,
          createdAt: createdLater,
        ),
        _task(
          id: 'untimed-second-category',
          targetDate: date,
          categoryId: secondCategory.id,
          createdAt: createdEarly,
        ),
        _task(
          id: 'all-day-created-later',
          kind: TaskKind.event,
          targetDate: date,
          categoryId: firstCategory.id,
          isAllDay: true,
          createdAt: createdLater,
        ),
        _task(
          id: 'completed-a',
          targetDate: date,
          categoryId: firstCategory.id,
          isCompleted: true,
          hasTime: true,
          startDateTime: DateTime(date.year, date.month, date.day, 8),
          endDateTime: DateTime(date.year, date.month, date.day, 9),
          createdAt: createdEarly,
        ),
        _task(
          id: 'untimed-b',
          targetDate: date,
          categoryId: firstCategory.id,
          createdAt: createdEarly,
        ),
        _task(
          id: 'all-day-a',
          kind: TaskKind.event,
          targetDate: date,
          categoryId: firstCategory.id,
          isAllDay: true,
          createdAt: createdEarly,
        ),
        _task(
          id: 'overdue-a',
          targetDate: oneDayEarlier,
          createdAt: createdEarly,
        ),
        _task(
          id: 'timeline-a',
          kind: TaskKind.event,
          targetDate: date,
          categoryId: firstCategory.id,
          hasTime: true,
          startDateTime: DateTime(date.year, date.month, date.day, 9),
          endDateTime: DateTime(date.year, date.month, date.day, 10),
          createdAt: createdEarly,
        ),
        _task(
          id: 'all-day-missing-a',
          kind: TaskKind.event,
          targetDate: date,
          isAllDay: true,
          createdAt: createdEarly,
        ),
        _task(
          id: 'untimed-a',
          targetDate: date,
          categoryId: firstCategory.id,
          createdAt: createdEarly,
        ),
        _task(
          id: 'untimed-missing-a',
          targetDate: date,
          createdAt: createdEarly,
        ),
      ];
      final taskRepository = _FakeTaskRepository(success(tasks));
      final categoryRepository = _FakeCategoryRepository(
        success([secondCategory, firstCategory]),
      );
      final useCase = GetTodayOverviewUseCase(
        taskRepository,
        categoryRepository,
      );

      final result = await useCase(selectedDate);

      expect(result.failure, isNull);
      final overview = result.data!;
      expect(overview.date, date);
      expect(overview.date.isUtc, isFalse);
      expect(taskRepository.overviewDates, [date]);
      expect(taskRepository.overviewCalls, 1);
      expect(categoryRepository.getCalls, 1);
      expect(
        _ids(overview.overdueTodos),
        [
          'overdue-earliest',
          'overdue-a',
          'overdue-b',
          'overdue-created-later',
        ],
      );
      expect(
        _ids(overview.allDayEvents),
        [
          'all-day-a',
          'all-day-b',
          'all-day-created-later',
          'all-day-second-category',
          'all-day-missing-a',
          'all-day-missing-b',
        ],
      );
      expect(
        _ids(overview.timelineItems),
        [
          'timeline-a',
          'timeline-b',
          'timeline-end-later',
          'timeline-start-later',
        ],
      );
      expect(
        _ids(overview.untimedTodos),
        [
          'untimed-a',
          'untimed-b',
          'untimed-created-later',
          'untimed-second-category',
          'untimed-missing-a',
          'untimed-missing-b',
        ],
      );
      expect(
        _ids(overview.completedTodos),
        ['completed-a', 'completed-b', 'completed-later'],
      );
      expect(
        overview.timelineItems.any(
          (entry) => entry.task.id == 'completed-a',
        ),
        isFalse,
      );
      expect(
        overview.allDayEvents.first.category,
        same(firstCategory),
      );
      expect(
        overview.allDayEvents
            .firstWhere((entry) => entry.task.id == 'all-day-missing-a')
            .category,
        isNull,
      );
      expect(
        overview.allDayEvents
            .firstWhere((entry) => entry.task.id == 'all-day-missing-b')
            .category,
        isNull,
      );
      final ids = [
        ...overview.overdueTodos,
        ...overview.allDayEvents,
        ...overview.timelineItems,
        ...overview.untimedTodos,
        ...overview.completedTodos,
      ].map((entry) => entry.task.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('returns the same task failure without reading categories', () async {
      const taskFailure = CacheFailure('task read failed');
      final taskRepository = _FakeTaskRepository(fail(taskFailure));
      final categoryRepository = _FakeCategoryRepository(success(const []));
      final useCase = GetTodayOverviewUseCase(
        taskRepository,
        categoryRepository,
      );

      final result = await useCase(DateTime(2026, 8, 1, 12));

      expect(result.data, isNull);
      expect(result.failure, same(taskFailure));
      expect(taskRepository.overviewCalls, 1);
      expect(categoryRepository.getCalls, 0);
    });

    test('returns the same category failure after one task read', () async {
      const categoryFailure = CacheFailure('category read failed');
      final taskRepository = _FakeTaskRepository(success(const []));
      final categoryRepository = _FakeCategoryRepository(
        fail(categoryFailure),
      );
      final useCase = GetTodayOverviewUseCase(
        taskRepository,
        categoryRepository,
      );

      final result = await useCase(DateTime(2026, 8, 1, 12));

      expect(result.data, isNull);
      expect(result.failure, same(categoryFailure));
      expect(taskRepository.overviewCalls, 1);
      expect(categoryRepository.getCalls, 1);
    });
  });
}

List<String> _ids(List<TodayEntry> entries) =>
    entries.map((entry) => entry.task.id).toList();

Task _task({
  required String id,
  TaskKind kind = TaskKind.todo,
  required DateTime targetDate,
  String? categoryId,
  bool isCompleted = false,
  bool hasTime = false,
  DateTime? startDateTime,
  DateTime? endDateTime,
  bool isAllDay = false,
  required DateTime createdAt,
}) {
  return Task(
    id: id,
    title: id,
    kind: kind,
    targetDate: targetDate,
    categoryId: categoryId,
    isCompleted: isCompleted,
    hasTime: hasTime,
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    isAllDay: isAllDay,
    isRecurring: false,
    createdAt: createdAt,
  );
}

class _FakeTaskRepository implements TaskRepository {
  _FakeTaskRepository(this.overviewResult);

  final Result<List<Task>> overviewResult;
  final List<DateTime> overviewDates = [];
  int overviewCalls = 0;

  @override
  Future<Result<List<Task>>> getTasksForTodayOverview(
    DateTime selectedDate,
  ) async {
    overviewCalls++;
    overviewDates.add(selectedDate);
    return overviewResult;
  }

  @override
  Future<Result<Task>> createTask(CreateTaskParams params) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deleteTask(String id) => throw UnimplementedError();

  @override
  Future<Result<Task>> getTaskById(String id) => throw UnimplementedError();

  @override
  Future<Result<List<Task>>> getTasksByDate(DateTime date) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Task>>> getTasksByRange(DateTime start, DateTime end) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Task>>> getUnscheduledTasks() =>
      throw UnimplementedError();

  @override
  Future<Result<Task>> toggleComplete(String id) => throw UnimplementedError();

  @override
  Future<Result<Task>> updateTask(UpdateTaskParams params) =>
      throw UnimplementedError();
}

class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository(this.categoriesResult);

  final Result<List<Category>> categoriesResult;
  int getCalls = 0;

  @override
  Future<Result<List<Category>>> getCategories() async {
    getCalls++;
    return categoriesResult;
  }

  @override
  Future<Result<Category>> createCategory({
    required String name,
    required int color,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deleteCategory(String id) => throw UnimplementedError();
}
