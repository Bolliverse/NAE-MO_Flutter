import 'dart:async';
import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide fail;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/domain/usecases/get_today_overview_use_case.dart';
import 'package:nae_mo/features/calendar/presentation/pages/today_page.dart';
import 'package:nae_mo/features/calendar/presentation/viewmodels/today_view_model.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:nae_mo/features/task/domain/usecases/toggle_complete_use_case.dart';

void main() {
  final initialDate = DateTime(2026, 8, 3);

  setUpAll(() async {
    await initializeDateFormatting('ko', null);
    Intl.defaultLocale = 'ko';
  });

  testWidgets('an unresolved reload keeps the selected date header interactive',
      (tester) async {
    final reload = Completer<Result<TodayOverview>>();
    final nextDate = DateTime(2026, 8, 4);
    final harness = _PageHarness(
      initialDate: initialDate,
      loadResult: (date) {
        if (date == initialDate) {
          return Future.value(
            success(
              _overview(
                date,
                timelineItems: [
                  _entry(
                    id: 'old-content',
                    kind: TaskKind.event,
                    targetDate: date,
                    start: DateTime(2026, 8, 3, 9),
                  ),
                ],
              ),
            ),
          );
        }
        return reload.future;
      },
    );
    await _pumpPage(tester, harness);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('todayEntry-old-content')), findsOneWidget);

    harness.container.read(selectedDateProvider.notifier).select(nextDate);
    await tester.pump();

    expect(find.byKey(const Key('todayLoadingIndicator')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('todayDateHeader')), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const Key('todayDate-2026-08-04')))
          .hasFlag(SemanticsFlag.isSelected),
      isTrue,
    );
    expect(find.byKey(const Key('todayContent')), findsNothing);
    expect(find.byKey(const Key('todayEntry-old-content')), findsNothing);

    await tester.tap(find.byKey(const Key('todayNextDate')));
    await tester.pump();

    expect(harness.container.read(selectedDateProvider), DateTime(2026, 8, 5));
    expect(find.byKey(const Key('todayLoadingIndicator')), findsOneWidget);
    expect(find.byKey(const Key('todayDateHeader')), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const Key('todayDate-2026-08-05')))
          .hasFlag(SemanticsFlag.isSelected),
      isTrue,
    );

    reload.complete(success(_overview(DateTime(2026, 8, 5))));
    await tester.pumpAndSettle();
  });

  testWidgets('load failure keeps the header bound to the selected date',
      (tester) async {
    const failure = CacheFailure('Failed to load today data.');
    final harness = _PageHarness(
      initialDate: initialDate,
      loadResult: (_) async => fail(failure),
    );
    await _pumpPage(tester, harness);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('todayDateHeader')), findsOneWidget);
    expect(find.byKey(const Key('todayRetryButton')), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const Key('todayDate-2026-08-03')))
          .hasFlag(SemanticsFlag.isSelected),
      isTrue,
    );

    await tester.tap(find.byKey(const Key('todayNextDate')));
    await tester.pumpAndSettle();

    expect(harness.container.read(selectedDateProvider), DateTime(2026, 8, 4));
    expect(find.byKey(const Key('todayDateHeader')), findsOneWidget);
    expect(find.byKey(const Key('todayRetryButton')), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const Key('todayDate-2026-08-04')))
          .hasFlag(SemanticsFlag.isSelected),
      isTrue,
    );
  });

  testWidgets('load failure shows its message and retry reloads current date',
      (tester) async {
    const failure = CacheFailure('저장된 오늘 데이터를 읽지 못했습니다.');
    var shouldFail = true;
    final harness = _PageHarness(
      initialDate: initialDate,
      loadResult: (date) async {
        if (shouldFail) return fail(failure);
        return success(_overview(date));
      },
    );
    await _pumpPage(tester, harness);
    await tester.pumpAndSettle();

    expect(find.text('오늘 일정을 불러올 수 없어요.'), findsOneWidget);
    expect(find.text(failure.message), findsOneWidget);
    expect(find.byKey(const Key('todayRetryButton')), findsOneWidget);
    expect(find.byKey(const Key('todayContent')), findsNothing);

    shouldFail = false;
    await tester.tap(find.byKey(const Key('todayRetryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('todayContent')), findsOneWidget);
    expect(harness.loadUseCase.calls, [initialDate, initialDate]);
  });

  testWidgets('unexpected load errors hide raw exception details',
      (tester) async {
    final harness = _PageHarness(
      initialDate: initialDate,
      loadResult: (_) async => throw StateError('private repository detail'),
    );
    await _pumpPage(tester, harness);
    await tester.pumpAndSettle();

    expect(find.text('오늘 일정을 불러올 수 없어요.'), findsOneWidget);
    expect(find.text('잠시 후 다시 시도해주세요.'), findsOneWidget);
    expect(find.textContaining('Bad state:'), findsNothing);
    expect(find.textContaining('private repository detail'), findsNothing);
  });

  testWidgets('error stays scrollable and retryable with large text',
      (tester) async {
    _setSurfaceSize(tester, const Size(390, 240));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );
    const failure = CacheFailure(
      '오늘 일정 데이터를 불러오지 못했습니다. 네트워크 연결을 확인한 뒤 다시 시도해주세요.',
    );
    final harness = _PageHarness(
      initialDate: initialDate,
      loadResult: (_) async => fail(failure),
    );
    await _pumpPage(tester, harness);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final retry = find.byKey(const Key('todayRetryButton'));
    expect(retry, findsOneWidget);
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    expect(retry.hitTestable(), findsOneWidget);
  });

  testWidgets('loaded sections keep one fixed order and exclusive entry keys',
      (tester) async {
    _setSurfaceSize(tester, const Size(1200, 1400));
    final overview = _populatedOverview(initialDate);
    final harness = _PageHarness(
      initialDate: initialDate,
      loadResult: (date) async => success(overview),
    );
    await _pumpPage(tester, harness);
    await tester.pumpAndSettle();

    final listView = tester.widget<ListView>(
      find.byKey(const Key('todayContent')),
    );
    final delegate = listView.childrenDelegate as SliverChildListDelegate;
    expect(
      delegate.children.map((child) => child.key),
      const [
        Key('todayDateHeader'),
        Key('todayOverdueSection'),
        Key('todayAllDaySection'),
        Key('todayTimelineSection'),
        Key('todayUntimedSection'),
        Key('todayCompletedSection'),
      ],
    );

    await tester.tap(find.text('지난 할 일'));
    await tester.tap(find.text('완료한 할 일'));
    await tester.pump();

    for (final id in const [
      'overdue',
      'all-day',
      'timeline',
      'untimed',
      'completed',
    ]) {
      expect(find.byKey(Key('todayEntry-$id')), findsOneWidget);
    }
    for (final id in const [
      'overdue',
      'timeline',
      'untimed',
      'completed',
    ]) {
      expect(find.byKey(Key('todayTodoCheckbox-$id')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('date controls update the shared selected date exactly',
      (tester) async {
    final harness = _PageHarness(
      initialDate: initialDate,
      loadResult: (date) async => success(_overview(date)),
    );
    await _pumpPage(tester, harness);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('todayPreviousDate')));
    await tester.pumpAndSettle();
    expect(harness.container.read(selectedDateProvider), DateTime(2026, 8, 2));

    harness.container.read(selectedDateProvider.notifier).select(initialDate);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('todayNextDate')));
    await tester.pumpAndSettle();
    expect(harness.container.read(selectedDateProvider), DateTime(2026, 8, 4));

    harness.container.read(selectedDateProvider.notifier).select(initialDate);
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await tester.tap(find.byKey(const Key('todayGoToToday')));
    await tester.pumpAndSettle();
    expect(harness.container.read(selectedDateProvider), today);

    harness.container.read(selectedDateProvider.notifier).select(initialDate);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('todayDate-2026-08-05')));
    await tester.pumpAndSettle();
    expect(harness.container.read(selectedDateProvider), DateTime(2026, 8, 5));
  });

  testWidgets('section header taps update the real ViewModel expansion state',
      (tester) async {
    final harness = _PageHarness(
      initialDate: initialDate,
      loadResult: (date) async => success(
        _overview(
          date,
          overdueTodos: [
            _entry(
              id: 'expand-overdue',
              kind: TaskKind.todo,
              targetDate: DateTime(2026, 8, 2),
            ),
          ],
          completedTodos: [
            _entry(
              id: 'expand-completed',
              kind: TaskKind.todo,
              targetDate: date,
              isCompleted: true,
            ),
          ],
        ),
      ),
    );
    await _pumpPage(tester, harness);
    await tester.pumpAndSettle();

    await tester.tap(find.text('지난 할 일'));
    await tester.pump();
    expect(
      harness.container
          .read(todayViewModelProvider)
          .requireValue
          .isOverdueExpanded,
      isTrue,
    );

    await tester.tap(find.text('완료한 할 일'));
    await tester.pump();
    expect(
      harness.container
          .read(todayViewModelProvider)
          .requireValue
          .isCompletedExpanded,
      isTrue,
    );
  });

  testWidgets('toggle failure rolls back and shows the failure message',
      (tester) async {
    const failure = CacheFailure('완료 상태를 저장하지 못했습니다.');
    final todo = _entry(
      id: 'rollback',
      kind: TaskKind.todo,
      targetDate: initialDate,
    );
    final harness = _PageHarness(
      initialDate: initialDate,
      loadResult: (date) async => success(
        _overview(date, untimedTodos: [todo]),
      ),
    );
    await _pumpPage(tester, harness);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('todayTodoCheckbox-rollback')));
    await tester.pump();
    expect(
      harness.container
          .read(todayViewModelProvider)
          .requireValue
          .overview
          .untimedTodos,
      isEmpty,
    );

    harness.toggleUseCase.complete(fail(failure));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final state = harness.container.read(todayViewModelProvider).requireValue;
    expect(state.overview.untimedTodos.single.task.id, 'rollback');
    expect(state.pendingTodoIds, isEmpty);
    expect(find.text(failure.message), findsOneWidget);
  });

  testWidgets('late toggle failure stays silent after navigating to a new date',
      (tester) async {
    const failure = CacheFailure('이전 날짜 저장 실패');
    final nextDate = DateTime(2026, 8, 4);
    final harness = _PageHarness(
      initialDate: initialDate,
      loadResult: (date) async {
        if (date == initialDate) {
          return success(
            _overview(
              date,
              untimedTodos: [
                _entry(
                  id: 'old-date-todo',
                  kind: TaskKind.todo,
                  targetDate: date,
                ),
              ],
            ),
          );
        }
        return success(
          _overview(
            date,
            timelineItems: [
              _entry(
                id: 'new-date-content',
                kind: TaskKind.event,
                targetDate: date,
                start: DateTime(2026, 8, 4, 9),
              ),
            ],
          ),
        );
      },
    );
    await _pumpPage(tester, harness);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('todayTodoCheckbox-old-date-todo')),
    );
    await tester.pump();
    harness.container.read(selectedDateProvider.notifier).select(nextDate);
    await harness.container.read(todayViewModelProvider.future);
    await tester.pump();
    expect(
        find.byKey(const Key('todayEntry-new-date-content')), findsOneWidget);

    harness.toggleUseCase.complete(fail(failure));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(failure.message), findsNothing);
    expect(
        find.byKey(const Key('todayEntry-new-date-content')), findsOneWidget);
    expect(harness.container.read(selectedDateProvider), nextDate);
  });

  for (final size in const [Size(390, 844), Size(1200, 900)]) {
    for (final populated in [false, true]) {
      testWidgets(
          '${size.width.toInt()}x${size.height.toInt()} '
          '${populated ? 'populated' : 'empty'} layout has no exception',
          (tester) async {
        _setSurfaceSize(tester, size);
        final harness = _PageHarness(
          initialDate: initialDate,
          loadResult: (date) async => success(
            populated ? _populatedOverview(date) : _overview(date),
          ),
        );
        await _pumpPage(tester, harness);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        if (size.width == 1200) {
          final contentRect = tester.getRect(
            find.byKey(const Key('todayContent')),
          );
          expect(contentRect.width, lessThanOrEqualTo(720));
          expect(contentRect.center.dx, closeTo(size.width / 2, 0.01));
        }
      });
    }
  }
}

class _PageHarness {
  _PageHarness({
    required DateTime initialDate,
    required Future<Result<TodayOverview>> Function(DateTime date) loadResult,
  }) {
    loadUseCase = _FakeGetTodayOverviewUseCase(loadResult);
    toggleUseCase = _ControllableToggleCompleteUseCase();
    container = ProviderContainer(
      overrides: [
        getTodayOverviewUseCaseProvider.overrideWithValue(loadUseCase),
        toggleCompleteUseCaseProvider.overrideWithValue(toggleUseCase),
      ],
    );
    addTearDown(container.dispose);
    container.read(selectedDateProvider.notifier).select(initialDate);
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
  Completer<Result<Task>>? _pending;

  @override
  Future<Result<Task>> call(String id) {
    calls.add(id);
    _pending = Completer<Result<Task>>();
    return _pending!.future;
  }

  void complete(Result<Task> result) {
    final pending = _pending;
    if (pending == null) throw StateError('No pending completion');
    pending.complete(result);
    _pending = null;
  }
}

class _UnusedTaskRepository extends Fake implements TaskRepository {}

class _UnusedCategoryRepository extends Fake implements CategoryRepository {}

Future<void> _pumpPage(WidgetTester tester, _PageHarness harness) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp(
        theme: ThemeData(colorSchemeSeed: const Color(0xFF6750A4)),
        home: const Scaffold(body: TodayPage()),
      ),
    ),
  );
  await tester.pump();
}

void _setSurfaceSize(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}

TodayOverview _populatedOverview(DateTime date) {
  return _overview(
    date,
    overdueTodos: [
      _entry(
        id: 'overdue',
        kind: TaskKind.todo,
        targetDate: date.subtract(const Duration(days: 1)),
      ),
    ],
    allDayEvents: [
      _entry(
        id: 'all-day',
        kind: TaskKind.event,
        targetDate: date,
        isAllDay: true,
      ),
    ],
    timelineItems: [
      _entry(
        id: 'timeline',
        kind: TaskKind.todo,
        targetDate: date,
        start: DateTime(date.year, date.month, date.day, 9),
        end: DateTime(date.year, date.month, date.day, 10),
      ),
    ],
    untimedTodos: [
      _entry(
        id: 'untimed',
        kind: TaskKind.todo,
        targetDate: date,
      ),
    ],
    completedTodos: [
      _entry(
        id: 'completed',
        kind: TaskKind.todo,
        targetDate: date,
        isCompleted: true,
      ),
    ],
  );
}

TodayOverview _overview(
  DateTime date, {
  List<TodayEntry> overdueTodos = const [],
  List<TodayEntry> allDayEvents = const [],
  List<TodayEntry> timelineItems = const [],
  List<TodayEntry> untimedTodos = const [],
  List<TodayEntry> completedTodos = const [],
}) {
  return TodayOverview(
    date: DateTime(date.year, date.month, date.day),
    overdueTodos: List.unmodifiable(overdueTodos),
    allDayEvents: List.unmodifiable(allDayEvents),
    timelineItems: List.unmodifiable(timelineItems),
    untimedTodos: List.unmodifiable(untimedTodos),
    completedTodos: List.unmodifiable(completedTodos),
  );
}

TodayEntry _entry({
  required String id,
  required TaskKind kind,
  required DateTime targetDate,
  bool isCompleted = false,
  bool isAllDay = false,
  DateTime? start,
  DateTime? end,
}) {
  return TodayEntry(
    task: Task(
      id: id,
      title: 'Title for $id',
      kind: kind,
      targetDate: targetDate,
      isCompleted: isCompleted,
      hasTime: start != null,
      startDateTime: start,
      endDateTime: end,
      isAllDay: isAllDay,
      isRecurring: false,
      createdAt: DateTime(2026, 7, 1, 9),
    ),
  );
}
