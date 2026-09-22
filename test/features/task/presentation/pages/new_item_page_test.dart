import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart' as result;
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';
import 'package:nae_mo/features/task/presentation/pages/new_item_page.dart';
import 'package:nae_mo/features/task/presentation/states/new_item_schedule_draft.dart';
import 'package:nae_mo/features/task/presentation/widgets/new_item_category_input.dart';

void main() {
  testWidgets('changing edit date moves both timestamps to the chosen date',
      (tester) async {
    final task = Task(
        id: 'timed',
        title: '시간 일정',
        kind: TaskKind.event,
        targetDate: DateTime(2026, 8, 3),
        isCompleted: false,
        hasTime: true,
        startDateTime: DateTime(2026, 8, 3, 9),
        endDateTime: DateTime(2026, 8, 3, 10),
        isAllDay: false,
        isRecurring: false,
        createdAt: DateTime(2026, 8, 1));
    UpdateTaskParams? saved;
    await _pump(tester, initialTask: task, updater: (params) async {
      saved = params;
      return result.success(task);
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editItemDateButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newItemSaveButton')));
    await tester.pump();
    expect(saved!.targetDate, DateTime(2026, 8, 4));
    expect(saved!.startDateTime, DateTime(2026, 8, 4, 9));
    expect(saved!.endDateTime, DateTime(2026, 8, 4, 10));
  });
  for (final kind in TaskKind.values) {
    for (final timed in [false, true]) {
      testWidgets(
          'edit prefills ${kind.name} timed=$timed and saves existing ID',
          (tester) async {
        final date = DateTime(2026, 9, 18);
        final original = Task(
            id: 'existing',
            title: '기존 항목',
            kind: kind,
            targetDate: date,
            categoryId: 'work',
            isCompleted: kind == TaskKind.todo,
            hasTime: timed,
            startDateTime: timed ? DateTime(2026, 9, 18, 9) : null,
            endDateTime: timed ? DateTime(2026, 9, 18, 10) : null,
            isAllDay: kind == TaskKind.event && !timed,
            isRecurring: false,
            createdAt: date);
        UpdateTaskParams? saved;
        await _pump(tester,
            initialTask: original,
            categoryLoader: () async => result.success(const [_workCategory]),
            updater: (params) async {
              saved = params;
              return result.success(original);
            });
        await tester.pumpAndSettle();
        expect(find.text('항목 수정'), findsOneWidget);
        expect(
            tester
                .widget<TextField>(find.byKey(const Key('newItemTitleField')))
                .controller!
                .text,
            original.title);
        expect(find.text('연구'), findsOneWidget);
        expect(find.byKey(const Key('newItemEventKind')), findsNothing);
        await tester.enterText(
            find.byKey(const Key('newItemTitleField')), '  수정된 항목  ');
        await tester.tap(find.byKey(const Key('newItemCategoryButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('newItemCategory-none')));
        await tester.pumpAndSettle();
        if (timed) {
          await _tapVisible(
              tester,
              find.byKey(Key(kind == TaskKind.event
                  ? 'newItemAllDayMode'
                  : 'newItemUntimedMode')));
        }
        await tester.tap(find.byKey(const Key('newItemSaveButton')));
        await tester.pump();
        expect(saved!.id, 'existing');
        expect(saved!.title, '수정된 항목');
        expect(saved!.targetDate, date);
        expect(saved!.clearCategory, isTrue);
        expect(saved!.clearTime, isTrue);
        expect(saved!.hasTime, isFalse);
        expect(saved!.isAllDay, kind == TaskKind.event);
        expect(saved!.isCompleted, isNull);
        expect(saved!.kind, isNull);
      });
    }
  }

  testWidgets(
      'failed edit keeps input, blocks pending back, and retries update',
      (tester) async {
    final pending = Completer<result.Result<Task>>();
    var calls = 0;
    var closed = 0;
    var saves = 0;
    await _pump(tester,
        initialTask: _savedTodo,
        onClose: () => closed++,
        onSaved: () => saves++,
        updater: (_) async {
          calls++;
          return calls == 1 ? pending.future : result.success(_savedTodo);
        });
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('newItemTitleField')), '수정 중');
    await tester.pump();
    await tester.tap(find.byKey(const Key('newItemSaveButton')));
    await tester.pump();
    await tester.binding.handlePopRoute();
    expect(closed, 0);
    expect(_saveButton(tester).onPressed, isNull);
    pending.complete(result.fail(const CacheFailure('write failed')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('newItemSaveError')), findsOneWidget);
    expect(find.text('수정 중'), findsOneWidget);
    await tester.tap(find.byKey(const Key('newItemSaveButton')));
    await tester.pump();
    expect(calls, 2);
    expect(saves, 1);
  });
  test('category state sorts categories and resolves the selected id', () {
    final state = NewItemCategoryState.loaded(const [
      Category(id: 'b', name: 'B', color: 0xFF76C4DE, sortOrder: 2),
      Category(id: 'c', name: 'C', color: 0xFFFFD64F, sortOrder: 1),
      Category(id: 'a', name: 'A', color: 0xFFA4E85B, sortOrder: 2),
    ]);

    expect(state.categories.map((category) => category.id), ['c', 'a', 'b']);
    expect(state.categoryFor('a')?.name, 'A');
    expect(state.categoryFor('missing'), isNull);
    expect(state.categoryFor(null), isNull);
  });

  group('buildNewItemParams', () {
    final cases = <({
      String name,
      NewItemScheduleDraft draft,
      bool hasTime,
      bool isAllDay,
      TaskKind kind,
      DateTime? start,
      DateTime? end,
    })>[
      (
        name: 'timed event',
        draft: const NewItemScheduleDraft(
          startTime: TimeOfDay(hour: 9, minute: 30),
          endTime: TimeOfDay(hour: 10, minute: 30),
        ),
        hasTime: true,
        isAllDay: false,
        kind: TaskKind.event,
        start: DateTime(2026, 8, 3, 9, 30),
        end: DateTime(2026, 8, 3, 10, 30),
      ),
      (
        name: 'all-day event',
        draft: const NewItemScheduleDraft(
          eventMode: NewItemTimeMode.allDay,
        ),
        hasTime: false,
        isAllDay: true,
        kind: TaskKind.event,
        start: null,
        end: null,
      ),
      (
        name: 'timed Todo',
        draft: const NewItemScheduleDraft(
          kind: NewItemKind.todo,
          todoMode: NewItemTimeMode.timed,
          startTime: TimeOfDay(hour: 13, minute: 0),
          endTime: TimeOfDay(hour: 14, minute: 0),
        ),
        hasTime: true,
        isAllDay: false,
        kind: TaskKind.todo,
        start: DateTime(2026, 8, 3, 13),
        end: DateTime(2026, 8, 3, 14),
      ),
      (
        name: 'untimed Todo',
        draft: const NewItemScheduleDraft(kind: NewItemKind.todo),
        hasTime: false,
        isAllDay: false,
        kind: TaskKind.todo,
        start: null,
        end: null,
      ),
    ];

    for (final testCase in cases) {
      test('maps ${testCase.name}', () {
        final params = buildNewItemParams(
          title: '  리뷰 요청 보내기  ',
          selectedDate: DateTime(2026, 8, 3, 17, 45),
          draft: testCase.draft,
          categoryId: testCase.name == 'untimed Todo' ? null : 'work',
        );

        expect(params.title, '리뷰 요청 보내기');
        expect(params.targetDate, DateTime(2026, 8, 3));
        expect(params.kind, testCase.kind);
        expect(params.categoryId,
            testCase.name == 'untimed Todo' ? isNull : 'work');
        expect(params.hasTime, testCase.hasTime);
        expect(params.isAllDay, testCase.isAllDay);
        expect(params.startDateTime, testCase.start);
        expect(params.endDateTime, testCase.end);
      });
    }
  });

  testWidgets('starts as one event form with a fixed Daily date',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    expect(find.text('새 항목 추가'), findsOneWidget);
    expect(find.text('2026년 8월 3일'), findsOneWidget);
    expect(find.byKey(const Key('newItemTitleField')), findsOneWidget);
    expect(find.byKey(const Key('newItemTimedMode')), findsOneWidget);
    expect(find.byKey(const Key('newItemAllDayMode')), findsOneWidget);
    expect(find.byKey(const Key('newItemStartTimeButton')), findsOneWidget);
    expect(find.byKey(const Key('newItemEndTimeButton')), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('newItemSaveButton')))
          .onPressed,
      isNull,
    );
    expect(
      tester.getSemantics(find.byKey(const Key('newItemEventKind'))),
      matchesSemantics(
        label: '일정',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
        children: const <Matcher>[],
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('newItemTodoKind'))),
      matchesSemantics(
        label: 'Todo',
        isButton: true,
        isSelected: false,
        hasTapAction: true,
        children: const <Matcher>[],
      ),
    );
    semantics.dispose();
  });

  testWidgets('loads categories and keeps the selection across item kinds',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      categoryLoader: () async => result.success(const [
        _personalCategory,
        _workCategory,
        _healthCategory,
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('카테고리 없음'), findsOneWidget);
    await tester.tap(find.byKey(const Key('newItemCategoryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('newItemCategorySheet')), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.byKey(const Key('newItemCategory-work')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const Key('newItemCategory-personal')),
            )
            .dy,
      ),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const Key('newItemCategory-personal')),
          )
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(const Key('newItemCategory-health')),
            )
            .dy,
      ),
    );

    await tester.tap(find.byKey(const Key('newItemCategory-work')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newItemTodoKind')));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byKey(const Key('newItemCategoryButton'))).label,
      '카테고리, 연구',
    );
    expect(find.text('연구'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('keeps no-category available for an empty category list',
      (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('newItemCategoryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('newItemCategory-none')), findsOneWidget);
    expect(find.byKey(const Key('newItemCategory-work')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('newItemCategory-none')),
        matching: find.text('카테고리 없음'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows category loading before the loader completes',
      (tester) async {
    final completer = Completer<result.Result<List<Category>>>();
    await _pump(tester, categoryLoader: () => completer.future);

    expect(
      find.byKey(const Key('newItemCategoryLoading')),
      findsOneWidget,
    );
    expect(find.text('카테고리 불러오는 중'), findsOneWidget);
    expect(find.byKey(const Key('newItemCategoryButton')), findsNothing);

    completer.complete(result.success(const []));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('newItemCategoryButton')), findsOneWidget);
  });

  testWidgets('retries a failed category load', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      categoryLoader: () async {
        calls++;
        if (calls == 1) {
          return result.fail(const CacheFailure('category read failed'));
        }
        return result.success(const [_workCategory]);
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('카테고리를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.byKey(const Key('newItemCategoryRetryButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('newItemCategoryRetryButton')));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('카테고리를 불러오지 못했습니다.'), findsNothing);
    expect(find.byKey(const Key('newItemCategoryButton')), findsOneWidget);
  });

  testWidgets('switches to Todo without clearing the shared title',
      (tester) async {
    await _pump(tester);

    await tester.enterText(
      find.byKey(const Key('newItemTitleField')),
      '리뷰 요청 보내기',
    );
    await tester.tap(find.byKey(const Key('newItemTodoKind')));
    await tester.pumpAndSettle();

    expect(find.text('리뷰 요청 보내기'), findsOneWidget);
    expect(find.byKey(const Key('newItemUntimedMode')), findsOneWidget);
    expect(find.byKey(const Key('newItemStartTimeButton')), findsNothing);
    expect(find.byKey(const Key('newItemEndTimeButton')), findsNothing);
    expect(
      tester.getSemantics(find.byKey(const Key('newItemTodoKind'))),
      matchesSemantics(
        label: 'Todo',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
        children: const <Matcher>[],
      ),
    );
  });

  testWidgets('enables save only when the active form is complete',
      (tester) async {
    await _pump(tester);

    await tester.enterText(
      find.byKey(const Key('newItemTitleField')),
      '일정 준비',
    );
    await tester.pump();
    expect(_saveButton(tester).onPressed, isNull);

    await _tapVisible(tester, find.byKey(const Key('newItemAllDayMode')));
    expect(_saveButton(tester).onPressed, isNotNull);

    await _tapVisible(tester, find.byKey(const Key('newItemTimedMode')));
    expect(_saveButton(tester).onPressed, isNull);

    await _tapVisible(tester, find.byKey(const Key('newItemTodoKind')));
    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('blocks duplicate saves and retries with the same input',
      (tester) async {
    final completers = <Completer<result.Result<Task>>>[];
    final capturedParams = <CreateTaskParams>[];
    var savedCalls = 0;
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      saver: (params) {
        capturedParams.add(params);
        final completer = Completer<result.Result<Task>>();
        completers.add(completer);
        return completer.future;
      },
      onSaved: () => savedCalls++,
    );

    await tester.enterText(
      find.byKey(const Key('newItemTitleField')),
      '  리뷰 요청 보내기  ',
    );
    await tester.tap(find.byKey(const Key('newItemTodoKind')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('newItemSaveButton')));
    await tester.pump();

    expect(capturedParams, hasLength(1));
    expect(capturedParams.single.title, '리뷰 요청 보내기');
    expect(find.text('저장 중'), findsOneWidget);
    expect(find.byKey(const Key('newItemSaveProgress')), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(const Key('newItemSaveButton')));
    await tester.pump();
    expect(capturedParams, hasLength(1));

    completers.single.complete(
      result.fail(const CacheFailure('save failed')),
    );
    await tester.pump();

    expect(
      find.text('항목을 저장하지 못했습니다. 다시 시도해 주세요.'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.byKey(const Key('newItemSaveError'))),
      matchesSemantics(
        label: '항목을 저장하지 못했습니다. 다시 시도해 주세요.',
        isLiveRegion: true,
        children: const <Matcher>[],
      ),
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('newItemTitleField')))
          .controller
          ?.text,
      '  리뷰 요청 보내기  ',
    );
    expect(_saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('newItemSaveButton')));
    await tester.pump();
    expect(capturedParams, hasLength(2));

    completers.last.complete(result.success(_savedTodo));
    await tester.pump();
    expect(savedCalls, 1);
    semantics.dispose();
  });

  testWidgets('blocks close and system back while a save is pending',
      (tester) async {
    final completer = Completer<result.Result<Task>>();
    var closeCalls = 0;
    await _pump(
      tester,
      onClose: () => closeCalls++,
      saver: (_) => completer.future,
    );

    await tester.enterText(
      find.byKey(const Key('newItemTitleField')),
      '리뷰 요청 보내기',
    );
    await tester.tap(find.byKey(const Key('newItemTodoKind')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('newItemSaveButton')));
    await tester.pump();

    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('newItemCloseButton')))
          .onPressed,
      isNull,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(closeCalls, 0);

    completer.complete(result.fail(const CacheFailure('save failed')));
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('newItemCloseButton')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('keeps a stable accessibility label after title entry',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    await tester.enterText(
      find.byKey(const Key('newItemTitleField')),
      '리뷰 요청 보내기',
    );

    expect(
      tester.getSemantics(find.byKey(const Key('newItemTitleSemantics'))).label,
      contains('제목'),
    );
    semantics.dispose();
  });

  testWidgets('shows and clears an invalid selected time range',
      (tester) async {
    final times = <TimeOfDay>[
      const TimeOfDay(hour: 10, minute: 0),
      const TimeOfDay(hour: 9, minute: 30),
      const TimeOfDay(hour: 10, minute: 30),
    ];
    await _pump(
      tester,
      timePicker: (_, __) async => times.removeAt(0),
    );

    await _tapVisible(
      tester,
      find.byKey(const Key('newItemStartTimeButton')),
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('newItemEndTimeButton')),
    );

    expect(find.text('오전 10:00'), findsOneWidget);
    expect(find.text('오전 9:30'), findsOneWidget);
    expect(
      find.text('종료 시간은 시작 시간보다 늦어야 합니다.'),
      findsOneWidget,
    );

    await _tapVisible(
      tester,
      find.byKey(const Key('newItemEndTimeButton')),
    );

    expect(find.text('오전 10:30'), findsOneWidget);
    expect(
      find.text('종료 시간은 시작 시간보다 늦어야 합니다.'),
      findsNothing,
    );
  });

  testWidgets('restores selected times after modes hide them', (tester) async {
    final times = <TimeOfDay>[
      const TimeOfDay(hour: 9, minute: 30),
      const TimeOfDay(hour: 10, minute: 30),
    ];
    await _pump(
      tester,
      timePicker: (_, __) async => times.removeAt(0),
    );

    await _tapVisible(
      tester,
      find.byKey(const Key('newItemStartTimeButton')),
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('newItemEndTimeButton')),
    );
    await _tapVisible(tester, find.byKey(const Key('newItemAllDayMode')));

    expect(find.byKey(const Key('newItemStartTimeButton')), findsNothing);

    await _tapVisible(tester, find.byKey(const Key('newItemTimedMode')));
    expect(find.text('오전 9:30'), findsOneWidget);
    expect(find.text('오전 10:30'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('newItemTodoKind')));
    expect(find.byKey(const Key('newItemStartTimeButton')), findsNothing);

    await _tapVisible(tester, find.byKey(const Key('newItemTimedMode')));
    expect(find.text('오전 9:30'), findsOneWidget);
    expect(find.text('오전 10:30'), findsOneWidget);
  });

  testWidgets('close button reports one close request', (tester) async {
    var closeCalls = 0;
    await _pump(tester, onClose: () => closeCalls++);

    await tester.tap(find.byKey(const Key('newItemCloseButton')));

    expect(closeCalls, 1);
  });

  testWidgets('system back reports the same close request', (tester) async {
    var closeCalls = 0;
    await _pump(tester, onClose: () => closeCalls++);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(closeCalls, 1);
  });

  testWidgets('fits a mobile viewport with large text', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await _pump(tester);

    await tester.ensureVisible(
      find.byKey(const Key('newItemEndTimeButton')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('newItemEndTimeButton')), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onClose,
  VoidCallback? onSaved,
  NewItemTimePicker? timePicker,
  NewItemCategoryLoader? categoryLoader,
  NewItemSaver? saver,
  Task? initialTask,
  ItemUpdater? updater,
}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: NewItemPage(
          selectedDate: DateTime(2026, 8, 3),
          onClose: onClose ?? () {},
          onSaved: onSaved ?? () {},
          timePicker: timePicker,
          categoryLoader:
              categoryLoader ?? () async => result.success(const []),
          saver: saver,
          initialTask: initialTask,
          updater: updater,
        ),
      ),
    ),
  );
}

TextButton _saveButton(WidgetTester tester) {
  return tester.widget<TextButton>(
    find.byKey(const Key('newItemSaveButton')),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

const _workCategory = Category(
  id: 'work',
  name: '연구',
  color: 0xFF76C4DE,
  sortOrder: 0,
);

const _personalCategory = Category(
  id: 'personal',
  name: '개인',
  color: 0xFFA4E85B,
  sortOrder: 1,
);

const _healthCategory = Category(
  id: 'health',
  name: '건강',
  color: 0xFFFFD64F,
  sortOrder: 2,
);

final _savedTodo = Task(
  id: 'saved-task',
  title: '리뷰 요청 보내기',
  kind: TaskKind.todo,
  targetDate: DateTime(2026, 8, 3),
  isCompleted: false,
  hasTime: false,
  isAllDay: false,
  isRecurring: false,
  createdAt: DateTime(2026, 8, 3, 12),
);
