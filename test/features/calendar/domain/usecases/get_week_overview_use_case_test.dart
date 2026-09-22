import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart' as result;
import 'package:nae_mo/features/calendar/domain/entities/week_overview.dart';
import 'package:nae_mo/features/calendar/domain/usecases/get_week_overview_use_case.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';

void main() {
  test('returns seven civil dates spanning year and leap-month boundaries',
      () async {
    for (final selected in [DateTime(2027, 1, 1, 23), DateTime(2024, 2, 29)]) {
      final tasks = _Tasks([]);
      final categories = _Categories();
      final week =
          (await GetWeekOverviewUseCase(tasks, categories)(selected)).data!;
      expect(week.start.weekday, DateTime.monday);
      expect(week.days.length, 7);
      expect(week.end.weekday, DateTime.sunday);
      expect(tasks.rangeStart, week.start);
      expect(tasks.rangeEnd, week.end);
      expect(tasks.calls, 1);
      expect(categories.calls, 1);
      expect(week.days.every((day) => day.events.isEmpty && day.todoCount == 0),
          isTrue);
      expect(() => week.days.clear(), throwsUnsupportedError);
    }
    expect(weekStartFor(DateTime(2027, 1, 1)), DateTime(2026, 12, 28));
  });

  test(
      'caps summaries, keeps full counts, sorts stably and omits completed Todo preview',
      () async {
    final date = DateTime(2026, 9, 14);
    final tasks = _Tasks([
      _task('late', date, hour: 12),
      _task('early', date, hour: 9),
      _task('all-day', date),
      _task('completed', date, todo: true, completed: true, hour: 7),
      _task('todo-b', date, todo: true, hour: 10),
      _task('todo-a', date, todo: true, hour: 10),
      _task('untimed', date, todo: true),
      _task('outside', DateTime(2026, 9, 21)),
    ]);
    final week =
        (await GetWeekOverviewUseCase(tasks, _Categories())(date)).data!;
    final monday = week.days.first;
    expect(monday.events.map((entry) => entry.task.id), ['all-day', 'early']);
    expect(monday.eventCount, 3);
    expect(monday.todoCount, 4);
    expect(monday.completedTodoCount, 1);
    expect(monday.firstTodo!.task.id, 'todo-a');
    expect(monday.events.first.category!.name, '업무');
    expect(() => monday.events.clear(), throwsUnsupportedError);
    expect(week.days.skip(1).every((day) => day.eventCount == 0), isTrue);
  });

  test('missing category remains readable and failures propagate', () async {
    final tasks = _Tasks([_task('orphan', DateTime(2026, 9, 14))]);
    final categories = _Categories(empty: true);
    final useCase = GetWeekOverviewUseCase(tasks, categories);
    expect(
        (await useCase(DateTime(2026, 9, 14)))
            .data!
            .days
            .first
            .events
            .first
            .category,
        isNull);
    categories.failure = const CacheFailure('categories');
    expect((await useCase(DateTime(2026, 9, 14))).failure, categories.failure);
    tasks.failure = const CacheFailure('tasks');
    final before = categories.calls;
    expect((await useCase(DateTime(2026, 9, 14))).failure, tasks.failure);
    expect(categories.calls, before);
  });
}

Task _task(String id, DateTime date,
        {bool todo = false, bool completed = false, int? hour}) =>
    Task(
        id: id,
        title: id,
        kind: todo ? TaskKind.todo : TaskKind.event,
        targetDate: date,
        categoryId: 'work',
        isCompleted: completed,
        hasTime: hour != null,
        startDateTime: hour == null
            ? null
            : DateTime(date.year, date.month, date.day, hour),
        endDateTime: hour == null
            ? null
            : DateTime(date.year, date.month, date.day, hour + 1),
        isAllDay: !todo && hour == null,
        isRecurring: false,
        createdAt: date);

class _Tasks extends Fake implements TaskRepository {
  _Tasks(this.tasks);
  final List<Task> tasks;
  DateTime? rangeStart;
  DateTime? rangeEnd;
  int calls = 0;
  Failure? failure;
  @override
  Future<result.Result<List<Task>>> getTasksByRange(
      DateTime start, DateTime end) async {
    calls++;
    rangeStart = start;
    rangeEnd = end;
    return failure == null ? result.success(tasks) : result.fail(failure!);
  }
}

class _Categories extends Fake implements CategoryRepository {
  _Categories({this.empty = false});
  final bool empty;
  int calls = 0;
  Failure? failure;
  @override
  Future<result.Result<List<Category>>> getCategories() async {
    calls++;
    if (failure != null) return result.fail(failure!);
    return result.success(empty
        ? []
        : const [
            Category(id: 'work', name: '업무', color: 0xFF67C1DE, sortOrder: 0)
          ]);
  }
}
