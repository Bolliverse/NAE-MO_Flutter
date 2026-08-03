import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/daily_calendar_pane.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/daily_todo_pane.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

void main() {
  const blue = Category(
    id: 'blue',
    name: '업무',
    color: 0xFF78C2DF,
    sortOrder: 0,
  );
  const green = Category(
    id: 'green',
    name: '개인',
    color: 0xFFA3E45A,
    sortOrder: 1,
  );
  final selectedDate = DateTime(2026, 8, 3);

  testWidgets('expanded pinned Todo renders overdue and completion states',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final entries = [
      _todo(
        id: 'overdue',
        title: '지난 회의록 정리',
        targetDate: DateTime(2026, 8, 1),
        category: blue,
      ),
      _todo(
        id: 'untimed',
        title: '장보기 목록 확인',
        targetDate: selectedDate,
        category: green,
      ),
      _todo(
        id: 'completed',
        title: '오늘 할 일 정리',
        targetDate: selectedDate,
        category: blue,
        completed: true,
      ),
    ];
    String? toggledId;

    await _pump(
      tester,
      DailyTodoPinned(
        entries: entries,
        selectedDate: selectedDate,
        isCompact: false,
        pendingTodoIds: const {},
        onToggleTodo: (id) => toggledId = id,
      ),
      size: const Size(390, 220),
    );

    expect(find.text('지난 회의록 정리'), findsOneWidget);
    expect(find.text('지난 8/1'), findsOneWidget);
    expect(find.text('장보기 목록 확인'), findsOneWidget);
    expect(find.text('오늘 할 일 정리'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(Card), findsNothing);
    expect(
      _decoration(tester, const Key('dailyTodoCheckVisual-untimed'))
          .border!
          .top
          .color,
      Color(green.color),
    );
    expect(
      _decoration(tester, const Key('dailyTodoCheckVisual-completed')).color,
      Color(blue.color),
    );

    expect(
      tester.getSemantics(
        find.byKey(const Key('dailyTodoEntry-completed')),
      ),
      matchesSemantics(
        label: '오늘 할 일 정리, 업무, 완료',
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        children: const <Matcher>[],
      ),
    );

    final checkbox = find.byKey(const Key('dailyTodoCheckbox-untimed'));
    expect(tester.getSize(checkbox), const Size(48, 48));
    await tester.tap(checkbox);
    expect(toggledId, 'untimed');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('pending Todo is disabled', (tester) async {
    final semantics = tester.ensureSemantics();
    final entry = _todo(
      id: 'pending',
      title: '저장 중인 할 일',
      targetDate: selectedDate,
      category: blue,
    );
    var toggleCalls = 0;

    await _pump(
      tester,
      DailyTodoPinned(
        entries: [entry],
        selectedDate: selectedDate,
        isCompact: false,
        pendingTodoIds: const {'pending'},
        onToggleTodo: (_) => toggleCalls++,
      ),
      size: const Size(390, 220),
    );

    expect(
      tester.getSemantics(find.byKey(const Key('dailyTodoEntry-pending'))),
      matchesSemantics(
        label: '저장 중인 할 일, 업무, 미완료',
        hasCheckedState: true,
        isChecked: false,
        hasEnabledState: true,
        isEnabled: false,
        children: const <Matcher>[],
      ),
    );
    await tester.tap(find.byKey(const Key('dailyTodoCheckbox-pending')));
    expect(toggleCalls, 0);
    semantics.dispose();
  });

  testWidgets('compact pinned Todo hides text and summarizes overflow',
      (tester) async {
    final entries = [
      for (var index = 0; index < 5; index++)
        _todo(
          id: 'untimed-$index',
          title: '시간 없는 할 일 $index',
          targetDate: selectedDate,
          category: index.isEven ? blue : green,
          completed: index == 1,
        ),
    ];

    await _pump(
      tester,
      DailyTodoPinned(
        entries: entries,
        selectedDate: selectedDate,
        isCompact: true,
        pendingTodoIds: const {},
        onToggleTodo: (_) {},
      ),
      size: const Size(64, 220),
    );

    expect(find.textContaining('시간 없는'), findsNothing);
    expect(find.byKey(const Key('dailyTodoCompactPinned-0')), findsOneWidget);
    expect(find.byKey(const Key('dailyTodoCompactPinned-1')), findsOneWidget);
    expect(find.byKey(const Key('dailyTodoCompactPinned-2')), findsOneWidget);
    expect(find.byKey(const Key('dailyTodoCompactPinned-3')), findsNothing);
    expect(find.byKey(const Key('dailyTodoPinnedOverflow')), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded timed Todo keeps its time position and toggle',
      (tester) async {
    final entry = _todo(
      id: 'timed',
      title: '프로토타입 피드백 반영',
      targetDate: selectedDate,
      category: green,
      start: DateTime(2026, 8, 3, 9, 30),
      end: DateTime(2026, 8, 3, 10, 30),
    );
    String? toggledId;

    await _pump(
      tester,
      DailyTodoTimeline(
        entries: [entry],
        isCompact: false,
        pendingTodoIds: const {},
        onToggleTodo: (id) => toggledId = id,
      ),
      size: const Size(390, dailyCalendarTimelineHeight),
    );

    expect(find.text('프로토타입 피드백 반영'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);
    final surfaceTop =
        tester.getTopLeft(find.byKey(const Key('dailyTodoTimelineSurface'))).dy;
    final entryRect = tester.getRect(
      find.byKey(const Key('dailyTodoTimelineEntry-timed')),
    );
    expect(entryRect.top - surfaceTop, 9.5 * dailyCalendarHourExtent);
    expect(find.byKey(const Key('dailyTodoCheckbox-timed')), findsOneWidget);

    await tester.tap(find.byKey(const Key('dailyTodoCheckbox-timed')));
    expect(toggledId, 'timed');
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact timed Todo uses color markers and overlap count',
      (tester) async {
    final entries = [
      for (var index = 0; index < 4; index++)
        _todo(
          id: 'timed-$index',
          title: '시간 할 일 $index',
          targetDate: selectedDate,
          category: index.isEven ? blue : green,
          start: DateTime(2026, 8, 3, 9, 30),
          end: DateTime(2026, 8, 3, 10),
        ),
    ];

    await _pump(
      tester,
      DailyTodoTimeline(
        entries: entries,
        isCompact: true,
        pendingTodoIds: const {},
        onToggleTodo: (_) {},
      ),
      size: const Size(64, dailyCalendarTimelineHeight),
    );

    expect(find.textContaining('시간 할 일'), findsNothing);
    expect(
        find.byKey(const Key('dailyTodoCompactTimed-timed-0')), findsOneWidget);
    expect(
        find.byKey(const Key('dailyTodoCompactTimed-timed-1')), findsOneWidget);
    expect(
        find.byKey(const Key('dailyTodoCompactTimed-timed-2')), findsNothing);
    expect(
        find.byKey(const Key('dailyTodoTimelineOverflow-570')), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty Todo timeline leaves only neutral hour lines',
      (tester) async {
    await _pump(
      tester,
      const DailyTodoTimeline(
        entries: [],
        isCompact: false,
        pendingTodoIds: {},
        onToggleTodo: _ignoreToggle,
      ),
      size: const Size(390, dailyCalendarTimelineHeight),
    );

    expect(find.byKey(const Key('dailyTodoHourLine-0')), findsOneWidget);
    expect(find.byKey(const Key('dailyTodoHourLine-24')), findsOneWidget);
    expect(find.byKey(const Key('dailyTodoTimelineOverflow-0')), findsNothing);
    expect(find.byType(Card), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Todo panes stay overflow-free at large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final entry = _todo(
      id: 'long',
      title: '놓치지 않도록 매우 긴 설명을 포함한 준비 항목 확인하기',
      targetDate: selectedDate,
      category: blue,
      start: DateTime(2026, 8, 3, 9),
      end: DateTime(2026, 8, 3, 10),
    );

    await _pump(
      tester,
      DailyTodoTimeline(
        entries: [entry],
        isCompact: false,
        pendingTodoIds: const {},
        onToggleTodo: (_) {},
      ),
      size: const Size(320, dailyCalendarTimelineHeight),
    );

    expect(tester.takeException(), isNull);
  });
}

void _ignoreToggle(String _) {}

BoxDecoration _decoration(WidgetTester tester, Key key) {
  return tester.widget<Container>(find.byKey(key)).decoration! as BoxDecoration;
}

TodayEntry _todo({
  required String id,
  required String title,
  required DateTime targetDate,
  required Category category,
  bool completed = false,
  DateTime? start,
  DateTime? end,
}) {
  return TodayEntry(
    task: Task(
      id: id,
      title: title,
      kind: TaskKind.todo,
      targetDate: targetDate,
      categoryId: category.id,
      isCompleted: completed,
      hasTime: start != null,
      startDateTime: start,
      endDateTime: end,
      isAllDay: false,
      isRecurring: false,
      createdAt: DateTime(2026, 8, 1),
    ),
    category: category,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}
