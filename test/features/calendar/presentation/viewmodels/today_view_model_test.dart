import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide fail;
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/domain/usecases/get_today_overview_use_case.dart';
import 'package:nae_mo/features/calendar/presentation/states/today_state.dart';
import 'package:nae_mo/features/calendar/presentation/viewmodels/today_view_model.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:nae_mo/features/task/domain/usecases/toggle_complete_use_case.dart';

void main() {
  final selectedDate = DateTime(2026, 8, 3);

  group('TodayViewModel loading and sections', () {
    test('loads the selected date with both sections collapsed', () async {
      final harness = _Harness(initialDate: selectedDate);

      final loaded =
          await harness.container.read(todayViewModelProvider.future);

      expect(loaded.overview.date, selectedDate);
      expect(loaded.isOverdueExpanded, isFalse);
      expect(loaded.isCompletedExpanded, isFalse);
      expect(loaded.pendingTodoIds, isEmpty);
      expect(harness.loadUseCase.calls, [selectedDate]);
    });

    test('toggles overdue and completed expansion in loaded state only',
        () async {
      final overview = _overview(selectedDate);
      final harness = _Harness(
        initialDate: selectedDate,
        overviewForDate: (_) => overview,
      );
      await harness.container.read(todayViewModelProvider.future);
      final notifier = harness.container.read(todayViewModelProvider.notifier);

      notifier.toggleOverdueSection();
      final overdueExpanded =
          harness.container.read(todayViewModelProvider).requireValue;
      expect(overdueExpanded.overview, same(overview));
      expect(overdueExpanded.isOverdueExpanded, isTrue);
      expect(overdueExpanded.isCompletedExpanded, isFalse);

      notifier.toggleCompletedSection();
      final bothExpanded =
          harness.container.read(todayViewModelProvider).requireValue;
      expect(bothExpanded.overview, same(overview));
      expect(bothExpanded.isOverdueExpanded, isTrue);
      expect(bothExpanded.isCompletedExpanded, isTrue);

      notifier
        ..toggleOverdueSection()
        ..toggleCompletedSection();
      final collapsed =
          harness.container.read(todayViewModelProvider).requireValue;
      expect(collapsed.isOverdueExpanded, isFalse);
      expect(collapsed.isCompletedExpanded, isFalse);
    });

    test('date changes reload and reset both collapsed sections', () async {
      final nextDate = DateTime(2026, 8, 4);
      final harness = _Harness(initialDate: selectedDate);
      await harness.container.read(todayViewModelProvider.future);
      harness.container.read(todayViewModelProvider.notifier)
        ..toggleOverdueSection()
        ..toggleCompletedSection();

      harness.container.read(selectedDateProvider.notifier).select(nextDate);
      final loaded =
          await harness.container.read(todayViewModelProvider.future);

      expect(loaded.overview.date, nextDate);
      expect(loaded.isOverdueExpanded, isFalse);
      expect(loaded.isCompletedExpanded, isFalse);
      expect(loaded.pendingTodoIds, isEmpty);
      expect(harness.loadUseCase.calls, [selectedDate, nextDate]);
    });

    test('retry reads the current selected date again', () async {
      const failure = CacheFailure('today load failed');
      var shouldFail = true;
      final harness = _Harness(
        initialDate: selectedDate,
        loadResult: (date) async {
          if (shouldFail) return fail(failure);
          return success(_overview(date));
        },
      );

      await expectLater(
        harness.container.read(todayViewModelProvider.future),
        throwsA(same(failure)),
      );
      shouldFail = false;

      harness.container.read(todayViewModelProvider.notifier).retry();
      final loaded =
          await harness.container.read(todayViewModelProvider.future);

      expect(loaded.overview.date, selectedDate);
      expect(harness.loadUseCase.calls, [selectedDate, selectedDate]);
    });
  });

  group('TodayViewModel optimistic completion', () {
    test('todo completion moves immediately before persistence finishes',
        () async {
      final original = _task(
        id: 'untimed',
        targetDate: selectedDate,
      );
      final harness = _Harness(
        initialDate: selectedDate,
        overviewForDate: (_) => _overview(
          selectedDate,
          untimedTodos: [_entry(original)],
        ),
      );
      await harness.container.read(todayViewModelProvider.future);

      final pending = harness.container
          .read(todayViewModelProvider.notifier)
          .toggleTodo(original.id);

      final optimistic =
          harness.container.read(todayViewModelProvider).requireValue;
      expect(optimistic.overview.untimedTodos, isEmpty);
      expect(_ids(optimistic.overview.completedTodos), [original.id]);
      expect(optimistic.pendingTodoIds, {original.id});
      _expectSameTaskExceptCompletion(
        optimistic.overview.completedTodos.single.task,
        original,
      );
      _expectExclusive(optimistic.overview);
      _expectUnmodifiable(optimistic, _entry(original));
      expect(harness.toggleUseCase.calls, [original.id]);

      harness.toggleUseCase.completeNext(success(original));
      expect(await pending, isNull);
    });

    test('successful completion keeps the optimistic result', () async {
      final original = _task(
        id: 'timed',
        targetDate: selectedDate,
        hasTime: true,
        startDateTime: DateTime(2026, 8, 3, 9),
        endDateTime: DateTime(2026, 8, 3, 10),
      );
      final harness = _Harness(
        initialDate: selectedDate,
        overviewForDate: (_) => _overview(
          selectedDate,
          timelineItems: [_entry(original)],
        ),
      );
      await harness.container.read(todayViewModelProvider.future);

      final pending = harness.container
          .read(todayViewModelProvider.notifier)
          .toggleTodo(original.id);
      harness.toggleUseCase.completeNext(success(original));
      final returned = await pending;

      final after = harness.container.read(todayViewModelProvider).requireValue;
      expect(returned, isNull);
      expect(after.overview.timelineItems, isEmpty);
      expect(_ids(after.overview.completedTodos), [original.id]);
      expect(after.pendingTodoIds, isEmpty);
      _expectSameTaskExceptCompletion(
        after.overview.completedTodos.single.task,
        original,
      );
      _expectExclusive(after.overview);
    });

    test('completed timed todo returns to the timeline', () async {
      final original = _task(
        id: 'completed-timed',
        targetDate: selectedDate,
        isCompleted: true,
        hasTime: true,
        startDateTime: DateTime(2026, 8, 3, 14),
        endDateTime: DateTime(2026, 8, 3, 15),
      );
      final harness = _Harness(
        initialDate: selectedDate,
        overviewForDate: (_) => _overview(
          selectedDate,
          completedTodos: [_entry(original)],
        ),
      );
      await harness.container.read(todayViewModelProvider.future);

      final pending = harness.container
          .read(todayViewModelProvider.notifier)
          .toggleTodo(original.id);

      final optimistic =
          harness.container.read(todayViewModelProvider).requireValue;
      expect(optimistic.overview.completedTodos, isEmpty);
      expect(_ids(optimistic.overview.timelineItems), [original.id]);
      _expectSameTaskExceptCompletion(
        optimistic.overview.timelineItems.single.task,
        original,
      );
      _expectExclusive(optimistic.overview);

      harness.toggleUseCase.completeNext(success(original));
      expect(await pending, isNull);
    });

    test('completed untimed todo returns to the untimed list', () async {
      final original = _task(
        id: 'completed-untimed',
        targetDate: selectedDate,
        isCompleted: true,
      );
      final harness = _Harness(
        initialDate: selectedDate,
        overviewForDate: (_) => _overview(
          selectedDate,
          completedTodos: [_entry(original)],
        ),
      );
      await harness.container.read(todayViewModelProvider.future);

      final pending = harness.container
          .read(todayViewModelProvider.notifier)
          .toggleTodo(original.id);

      final optimistic =
          harness.container.read(todayViewModelProvider).requireValue;
      expect(optimistic.overview.completedTodos, isEmpty);
      expect(_ids(optimistic.overview.untimedTodos), [original.id]);
      _expectSameTaskExceptCompletion(
        optimistic.overview.untimedTodos.single.task,
        original,
      );
      _expectExclusive(optimistic.overview);

      harness.toggleUseCase.completeNext(success(original));
      expect(await pending, isNull);
    });

    test('failed overdue completion restores previous state and failure',
        () async {
      const failure = CacheFailure('completion failed');
      final original = _task(
        id: 'overdue',
        targetDate: DateTime(2026, 8, 2),
      );
      final harness = _Harness(
        initialDate: selectedDate,
        overviewForDate: (_) => _overview(
          selectedDate,
          overdueTodos: [_entry(original)],
        ),
      );
      final before =
          await harness.container.read(todayViewModelProvider.future);

      final pending = harness.container
          .read(todayViewModelProvider.notifier)
          .toggleTodo(original.id);
      final optimistic =
          harness.container.read(todayViewModelProvider).requireValue;
      expect(optimistic.overview.overdueTodos, isEmpty);
      expect(optimistic.overview.completedTodos, isEmpty);
      expect(optimistic.pendingTodoIds, {original.id});
      _expectExclusive(optimistic.overview);

      harness.toggleUseCase.completeNext(fail(failure));
      final returned = await pending;

      final after = harness.container.read(todayViewModelProvider).requireValue;
      expect(returned, same(failure));
      expect(after, same(before));
      expect(_ids(after.overview.overdueTodos), [original.id]);
      expect(after.overview.completedTodos, isEmpty);
      expect(after.pendingTodoIds, isEmpty);
      _expectExclusive(after.overview);
    });

    test('duplicate completion taps make one call while the todo is pending',
        () async {
      final original = _task(
        id: 'duplicate',
        targetDate: selectedDate,
      );
      final harness = _Harness(
        initialDate: selectedDate,
        overviewForDate: (_) => _overview(
          selectedDate,
          untimedTodos: [_entry(original)],
        ),
      );
      await harness.container.read(todayViewModelProvider.future);
      final notifier = harness.container.read(todayViewModelProvider.notifier);

      final first = notifier.toggleTodo(original.id);
      final second = notifier.toggleTodo(original.id);

      expect(await second, isNull);
      expect(harness.toggleUseCase.calls, [original.id]);
      expect(
        harness.container
            .read(todayViewModelProvider)
            .requireValue
            .pendingTodoIds,
        {original.id},
      );

      harness.toggleUseCase.completeNext(success(original));
      expect(await first, isNull);
      expect(harness.toggleUseCase.calls, [original.id]);
    });

    test('failure after a date change never restores stale Today state',
        () async {
      const failure = CacheFailure('late completion failed');
      final nextDate = DateTime(2026, 8, 4);
      final oldTodo = _task(id: 'old', targetDate: selectedDate);
      final newTodo = _task(id: 'new', targetDate: nextDate);
      final harness = _Harness(
        initialDate: selectedDate,
        overviewForDate: (date) => _overview(
          date,
          untimedTodos: [
            _entry(date == selectedDate ? oldTodo : newTodo),
          ],
        ),
      );
      await harness.container.read(todayViewModelProvider.future);
      final pending = harness.container
          .read(todayViewModelProvider.notifier)
          .toggleTodo(oldTodo.id);

      harness.container.read(selectedDateProvider.notifier).select(nextDate);
      final next = await harness.container.read(todayViewModelProvider.future);
      expect(next.overview.date, nextDate);
      expect(_ids(next.overview.untimedTodos), [newTodo.id]);

      harness.toggleUseCase.completeNext(fail(failure));
      expect(await pending, same(failure));

      final after = harness.container.read(todayViewModelProvider).requireValue;
      expect(after.overview.date, nextDate);
      expect(_ids(after.overview.untimedTodos), [newTodo.id]);
      expect(after.overview.completedTodos, isEmpty);
      expect(after.pendingTodoIds, isEmpty);
      _expectExclusive(after.overview);
    });

    test('events are ignored by completion toggles', () async {
      final event = _task(
        id: 'event',
        kind: TaskKind.event,
        targetDate: selectedDate,
        hasTime: true,
        startDateTime: DateTime(2026, 8, 3, 18),
        endDateTime: DateTime(2026, 8, 3, 19),
      );
      final overview = _overview(
        selectedDate,
        timelineItems: [_entry(event)],
      );
      final harness = _Harness(
        initialDate: selectedDate,
        overviewForDate: (_) => overview,
      );
      await harness.container.read(todayViewModelProvider.future);

      final returned = await harness.container
          .read(todayViewModelProvider.notifier)
          .toggleTodo(event.id);

      final after = harness.container.read(todayViewModelProvider).requireValue;
      expect(returned, isNull);
      expect(after.overview, same(overview));
      expect(after.pendingTodoIds, isEmpty);
      expect(harness.toggleUseCase.calls, isEmpty);
    });
  });
}

class _Harness {
  _Harness({
    required DateTime initialDate,
    TodayOverview Function(DateTime date)? overviewForDate,
    Future<Result<TodayOverview>> Function(DateTime date)? loadResult,
  }) {
    loadUseCase = _FakeGetTodayOverviewUseCase(
      loadResult ??
          (date) async => success(
                overviewForDate?.call(date) ?? _overview(date),
              ),
    );
    toggleUseCase = _ControllableToggleCompleteUseCase();
    container = ProviderContainer(
      overrides: [
        getTodayOverviewUseCaseProvider.overrideWithValue(loadUseCase),
        toggleCompleteUseCaseProvider.overrideWithValue(toggleUseCase),
      ],
    );
    addTearDown(container.dispose);
    container.read(selectedDateProvider.notifier).select(initialDate);
    final subscription = container.listen(
      todayViewModelProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
  }

  late final ProviderContainer container;
  late final _FakeGetTodayOverviewUseCase loadUseCase;
  late final _ControllableToggleCompleteUseCase toggleUseCase;
}

class _FakeGetTodayOverviewUseCase extends GetTodayOverviewUseCase {
  _FakeGetTodayOverviewUseCase(this._onCall)
      : super(_UnusedTaskRepository(), _UnusedCategoryRepository());

  final Future<Result<TodayOverview>> Function(DateTime date) _onCall;
  final List<DateTime> calls = [];

  @override
  Future<Result<TodayOverview>> call(DateTime selectedDate) {
    calls.add(selectedDate);
    return _onCall(selectedDate);
  }
}

class _ControllableToggleCompleteUseCase extends ToggleCompleteUseCase {
  _ControllableToggleCompleteUseCase() : super(_UnusedTaskRepository());

  final List<String> calls = [];
  final Queue<Completer<Result<Task>>> _pending = Queue();

  @override
  Future<Result<Task>> call(String id) {
    calls.add(id);
    final completer = Completer<Result<Task>>();
    _pending.add(completer);
    return completer.future;
  }

  void completeNext(Result<Task> result) {
    _pending.removeFirst().complete(result);
  }
}

class _UnusedTaskRepository extends Fake implements TaskRepository {}

class _UnusedCategoryRepository extends Fake implements CategoryRepository {}

TodayOverview _overview(
  DateTime date, {
  List<TodayEntry> overdueTodos = const [],
  List<TodayEntry> allDayEvents = const [],
  List<TodayEntry> timelineItems = const [],
  List<TodayEntry> untimedTodos = const [],
  List<TodayEntry> completedTodos = const [],
}) {
  return TodayOverview(
    date: date,
    overdueTodos: List.unmodifiable(overdueTodos),
    allDayEvents: List.unmodifiable(allDayEvents),
    timelineItems: List.unmodifiable(timelineItems),
    untimedTodos: List.unmodifiable(untimedTodos),
    completedTodos: List.unmodifiable(completedTodos),
  );
}

TodayEntry _entry(Task task) => TodayEntry(task: task);

Task _task({
  required String id,
  TaskKind kind = TaskKind.todo,
  required DateTime targetDate,
  bool isCompleted = false,
  bool hasTime = false,
  DateTime? startDateTime,
  DateTime? endDateTime,
}) {
  return Task(
    id: id,
    title: 'Title for $id',
    kind: kind,
    targetDate: targetDate,
    categoryId: 'category-$id',
    isCompleted: isCompleted,
    hasTime: hasTime,
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    isAllDay: false,
    isRecurring: true,
    recurrenceRule: 'FREQ=WEEKLY',
    createdAt: DateTime(2026, 7, 1, 8),
  );
}

List<String> _ids(List<TodayEntry> entries) =>
    entries.map((entry) => entry.task.id).toList();

void _expectSameTaskExceptCompletion(Task actual, Task original) {
  expect(actual.id, original.id);
  expect(actual.title, original.title);
  expect(actual.kind, original.kind);
  expect(actual.targetDate, original.targetDate);
  expect(actual.categoryId, original.categoryId);
  expect(actual.isCompleted, isNot(original.isCompleted));
  expect(actual.hasTime, original.hasTime);
  expect(actual.startDateTime, original.startDateTime);
  expect(actual.endDateTime, original.endDateTime);
  expect(actual.isAllDay, original.isAllDay);
  expect(actual.isRecurring, original.isRecurring);
  expect(actual.recurrenceRule, original.recurrenceRule);
  expect(actual.createdAt, original.createdAt);
}

void _expectExclusive(TodayOverview overview) {
  final ids = [
    ..._ids(overview.overdueTodos),
    ..._ids(overview.allDayEvents),
    ..._ids(overview.timelineItems),
    ..._ids(overview.untimedTodos),
    ..._ids(overview.completedTodos),
  ];
  expect(ids.toSet(), hasLength(ids.length));
}

void _expectUnmodifiable(TodayState state, TodayEntry candidate) {
  final buckets = [
    state.overview.overdueTodos,
    state.overview.allDayEvents,
    state.overview.timelineItems,
    state.overview.untimedTodos,
    state.overview.completedTodos,
  ];
  for (final bucket in buckets) {
    expect(() => bucket.add(candidate), throwsUnsupportedError);
  }
  expect(
    () => state.pendingTodoIds.add(candidate.task.id),
    throwsUnsupportedError,
  );
}
