import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart' as result;
import 'package:nae_mo/features/calendar/domain/entities/month_overview.dart';
import 'package:nae_mo/features/calendar/domain/usecases/get_month_overview_use_case.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';

void main() {
  test(
      'queries the inclusive month once and handles leap-day and year boundaries',
      () async {
    for (final selected in [
      DateTime(2024, 2, 29, 20),
      DateTime(2026, 12, 31)
    ]) {
      final tasks = _Tasks([]);
      final categories = _Categories([]);
      final month =
          (await GetMonthOverviewUseCase(tasks, categories)(selected)).data!;
      expect(month.start, DateTime(selected.year, selected.month));
      expect(month.days.length,
          DateTime(selected.year, selected.month + 1, 0).day);
      expect(month.day(month.days.length).date,
          DateTime(selected.year, selected.month + 1, 0));
      expect(tasks.start, month.start);
      expect(tasks.end, month.day(month.days.length).date);
      expect(tasks.calls, 1);
      expect(categories.calls, 1);
      expect(() => month.days.clear(), throwsUnsupportedError);
    }
  });

  test(
      'groups by category, caps four sorted markers and computes shapes/checks',
      () async {
    final date = DateTime(2026, 9, 18);
    final categories = [
      const Category(id: 'last', name: '마지막', color: 0xFF666666, sortOrder: 5),
      const Category(id: 'b', name: 'B', color: 0xFF222222, sortOrder: 0),
      const Category(id: 'a', name: 'A', color: 0xFF111111, sortOrder: 0),
      const Category(id: 'c', name: 'C', color: 0xFF333333, sortOrder: 2),
      const Category(id: 'd', name: 'D', color: 0xFF444444, sortOrder: 3),
    ];
    final tasks = _Tasks([
      _task('a-event', date, category: 'a'),
      _task('a-done', date, category: 'a', todo: true, completed: true),
      _task('b-done', date, category: 'b', todo: true, completed: true),
      _task('b-open', date, category: 'b', todo: true),
      _task('c-event', date, category: 'c'),
      _task('d-done', date, category: 'd', todo: true, completed: true),
      _task('last-event', date, category: 'last'),
      _task('outside', DateTime(2026, 10, 1), category: 'a'),
    ]);
    final month =
        (await GetMonthOverviewUseCase(tasks, _Categories(categories))(date))
            .data!;
    final day = month.day(18);
    expect(
        day.markers.map((marker) => marker.category?.id), ['a', 'b', 'c', 'd']);
    expect(day.markers.map((marker) => marker.shape), [
      MonthMarkerShape.mixed,
      MonthMarkerShape.todo,
      MonthMarkerShape.event,
      MonthMarkerShape.todo,
    ]);
    expect(day.markers.map((marker) => marker.isChecked),
        [true, false, false, true]);
    expect(day.entries.length, 7);
    expect(() => day.markers.clear(), throwsUnsupportedError);
    expect(() => day.entries.clear(), throwsUnsupportedError);
    expect(month.day(19).markers, isEmpty);
  });

  test('missing category uses neutral marker, and completed Todo alone checks',
      () async {
    final date = DateTime(2026, 9, 18);
    final month = (await GetMonthOverviewUseCase(
            _Tasks([
              _task('untagged', date, todo: true, completed: true),
            ]),
            _Categories([]))(date))
        .data!;
    final marker = month.day(18).markers.single;
    expect(marker.category, isNull);
    expect(marker.shape, MonthMarkerShape.todo);
    expect(marker.isChecked, isTrue);
  });

  test('propagates failures and does not read categories after task failure',
      () async {
    final tasks = _Tasks([])..failure = const CacheFailure('task failure');
    final categories = _Categories([]);
    final useCase = GetMonthOverviewUseCase(tasks, categories);
    expect((await useCase(DateTime(2026, 9, 18))).failure, tasks.failure);
    expect(categories.calls, 0);
    tasks.failure = null;
    categories.failure = const CacheFailure('category failure');
    expect((await useCase(DateTime(2026, 9, 18))).failure, categories.failure);
  });
}

Task _task(
  String id,
  DateTime date, {
  String? category,
  bool todo = false,
  bool completed = false,
}) =>
    Task(
      id: id,
      title: id,
      kind: todo ? TaskKind.todo : TaskKind.event,
      targetDate: date,
      categoryId: category,
      isCompleted: completed,
      hasTime: false,
      isAllDay: !todo,
      isRecurring: false,
      createdAt: date,
    );

class _Tasks extends Fake implements TaskRepository {
  _Tasks(this.tasks);
  final List<Task> tasks;
  DateTime? start;
  DateTime? end;
  Failure? failure;
  int calls = 0;
  @override
  Future<result.Result<List<Task>>> getTasksByRange(
      DateTime start, DateTime end) async {
    calls++;
    this.start = start;
    this.end = end;
    return failure == null ? result.success(tasks) : result.fail(failure!);
  }
}

class _Categories extends Fake implements CategoryRepository {
  _Categories(this.categories);
  final List<Category> categories;
  Failure? failure;
  int calls = 0;
  @override
  Future<result.Result<List<Category>>> getCategories() async {
    calls++;
    return failure == null ? result.success(categories) : result.fail(failure!);
  }
}
