import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/today_all_day_section.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/today_overdue_section.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/today_timeline_section.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/today_todo_section.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

const _workCategory = Category(
  id: 'work',
  name: '업무',
  color: 0xFF6750A4,
  sortOrder: 0,
);

const _personalCategory = Category(
  id: 'personal',
  name: '개인',
  color: 0xFF2E7D5B,
  sortOrder: 1,
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko', null);
    Intl.defaultLocale = 'ko';
  });

  group('TodayOverdueSection', () {
    testWidgets('omits the section when there are no overdue todos',
        (tester) async {
      await _pump(
        tester,
        TodayOverdueSection(
          entries: const [],
          isExpanded: false,
          pendingTodoIds: const {},
          onToggleExpanded: () {},
          onToggleTodo: (_) {},
        ),
      );

      expect(find.text('지난 할 일'), findsNothing);
    });

    testWidgets(
        'collapsed summary shows count and oldest date without task titles',
        (tester) async {
      final entries = [
        _entry(
          id: 'newer-overdue',
          title: '영수증 정리',
          kind: TaskKind.todo,
          targetDate: DateTime(2026, 7, 28),
        ),
        _entry(
          id: 'oldest-overdue',
          title: '보고서 제출',
          kind: TaskKind.todo,
          targetDate: DateTime(2026, 7, 25, 23, 30),
        ),
      ];

      await _pump(
        tester,
        TodayOverdueSection(
          entries: entries,
          isExpanded: false,
          pendingTodoIds: const {},
          onToggleExpanded: () {},
          onToggleTodo: (_) {},
        ),
      );

      expect(find.text('지난 할 일'), findsOneWidget);
      expect(find.textContaining('2개'), findsOneWidget);
      expect(find.textContaining('7월 25일'), findsOneWidget);
      expect(find.text('영수증 정리'), findsNothing);
      expect(find.text('보고서 제출'), findsNothing);
    });

    testWidgets(
        'expanded rows show original dates and titles and report exact actions',
        (tester) async {
      var expandCalls = 0;
      String? toggledId;
      final entries = [
        _entry(
          id: 'enabled-overdue',
          title: '영수증 정리',
          kind: TaskKind.todo,
          targetDate: DateTime(2026, 7, 28),
        ),
        _entry(
          id: 'pending-overdue',
          title: '보고서 제출',
          kind: TaskKind.todo,
          targetDate: DateTime(2026, 7, 25),
        ),
      ];

      await _pump(
        tester,
        TodayOverdueSection(
          entries: entries,
          isExpanded: true,
          pendingTodoIds: const {'pending-overdue'},
          onToggleExpanded: () => expandCalls++,
          onToggleTodo: (id) => toggledId = id,
        ),
      );

      expect(find.text('영수증 정리'), findsOneWidget);
      expect(find.text('보고서 제출'), findsOneWidget);
      expect(find.text('7월 28일'), findsOneWidget);
      expect(find.text('7월 25일'), findsOneWidget);

      final enabled = tester.widget<Checkbox>(
        find.byKey(const Key('todayTodoCheckbox-enabled-overdue')),
      );
      final pending = tester.widget<Checkbox>(
        find.byKey(const Key('todayTodoCheckbox-pending-overdue')),
      );
      expect(enabled.onChanged, isNotNull);
      expect(pending.onChanged, isNull);

      await tester
          .tap(find.byKey(const Key('todayTodoCheckbox-enabled-overdue')));
      await tester.tap(find.text('지난 할 일'));

      expect(toggledId, 'enabled-overdue');
      expect(expandCalls, 1);
    });

    testWidgets('exposes one labeled checkable semantic control per todo',
        (tester) async {
      final semantics = tester.ensureSemantics();
      String? toggledId;
      final overdue = _entry(
        id: 'semantic-overdue',
        title: '보고서 제출',
        kind: TaskKind.todo,
        targetDate: DateTime(2026, 7, 25),
        category: _workCategory,
      );

      await _pump(
        tester,
        TodayOverdueSection(
          entries: [overdue],
          isExpanded: true,
          pendingTodoIds: const {},
          onToggleExpanded: () {},
          onToggleTodo: (id) => toggledId = id,
        ),
      );

      const label = '보고서 제출, 7월 25일';
      expect(find.semantics.byLabel(label), findsOne);
      expect(
        tester.getSemantics(
          find.byKey(const Key('todayEntry-semantic-overdue')),
        ),
        matchesSemantics(
          label: label,
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          children: const <Matcher>[],
        ),
      );

      tester.semantics.tap(find.semantics.byLabel(label));
      expect(toggledId, 'semantic-overdue');
      semantics.dispose();
    });
  });

  group('TodayAllDaySection', () {
    testWidgets('omits the section when there are no all-day events',
        (tester) async {
      await _pump(tester, const TodayAllDaySection(entries: []));

      expect(find.text('종일'), findsNothing);
    });

    testWidgets('shows a tinted all-day event without a checkbox',
        (tester) async {
      final event = _entry(
        id: 'all-day-event',
        title: '프로젝트 제출일',
        kind: TaskKind.event,
        targetDate: DateTime(2026, 7, 29),
        category: _workCategory,
        isAllDay: true,
      );

      await _pump(tester, TodayAllDaySection(entries: [event]));

      expect(find.text('프로젝트 제출일'), findsOneWidget);
      expect(find.text('업무'), findsOneWidget);
      expect(find.text('종일'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('업무')).style?.color,
        Color(_workCategory.color),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('todayEntry-all-day-event')),
          matching: find.byType(Checkbox),
        ),
        findsNothing,
      );
    });
  });

  group('TodayTimelineSection', () {
    testWidgets('always shows its heading and a short empty message',
        (tester) async {
      await _pump(
        tester,
        TodayTimelineSection(
          entries: const [],
          pendingTodoIds: const {},
          onToggleTodo: (_) {},
        ),
      );

      expect(find.text('일정'), findsOneWidget);
      expect(find.text('시간이 정해진 일정이 없어요.'), findsOneWidget);
    });

    testWidgets(
        'shows readable times and enables checkboxes only for non-pending todos',
        (tester) async {
      String? toggledId;
      final entries = [
        _entry(
          id: 'meeting',
          title: '팀 미팅',
          kind: TaskKind.event,
          targetDate: DateTime(2026, 7, 29),
          start: DateTime(2026, 7, 29, 9),
          end: DateTime(2026, 7, 29, 10),
          category: _workCategory,
        ),
        _entry(
          id: 'enabled-timed-todo',
          title: '기획안 정리',
          kind: TaskKind.todo,
          targetDate: DateTime(2026, 7, 29),
          start: DateTime(2026, 7, 29, 16),
          end: DateTime(2026, 7, 29, 17),
          category: _personalCategory,
        ),
        _entry(
          id: 'pending-timed-todo',
          title: '메일 답장',
          kind: TaskKind.todo,
          targetDate: DateTime(2026, 7, 29),
          start: DateTime(2026, 7, 29, 18, 30),
          end: DateTime(2026, 7, 29, 19),
        ),
      ];

      await _pump(
        tester,
        TodayTimelineSection(
          entries: entries,
          pendingTodoIds: const {'pending-timed-todo'},
          onToggleTodo: (id) => toggledId = id,
        ),
      );

      final startText = tester.widget<Text>(find.text('09:00'));
      final endText = tester.widget<Text>(find.text('10:00'));
      expect(
        startText.style?.fontWeight?.index,
        greaterThanOrEqualTo(FontWeight.w600.index),
      );
      expect(
        endText.style?.color,
        Theme.of(tester.element(find.text('10:00')))
            .colorScheme
            .onSurfaceVariant,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('todayEntry-meeting')),
          matching: find.byType(Checkbox),
        ),
        findsNothing,
      );

      final enabled = tester.widget<Checkbox>(
        find.byKey(const Key('todayTodoCheckbox-enabled-timed-todo')),
      );
      final pending = tester.widget<Checkbox>(
        find.byKey(const Key('todayTodoCheckbox-pending-timed-todo')),
      );
      expect(enabled.onChanged, isNotNull);
      expect(pending.onChanged, isNull);

      await tester.tap(
        find.byKey(const Key('todayTodoCheckbox-enabled-timed-todo')),
      );
      expect(toggledId, 'enabled-timed-todo');
    });

    testWidgets('converts UTC start and end times to local display values',
        (tester) async {
      final utcStart = DateTime.utc(2026, 7, 29, 0, 15);
      final utcEnd = DateTime.utc(2026, 7, 29, 1, 45);
      final expectedStart =
          DateFormat('HH:mm', 'ko').format(utcStart.toLocal());
      final expectedEnd = DateFormat('HH:mm', 'ko').format(utcEnd.toLocal());

      await _pump(
        tester,
        TodayTimelineSection(
          entries: [
            _entry(
              id: 'utc-event',
              title: '해외 화상 회의',
              kind: TaskKind.event,
              targetDate: DateTime(2026, 7, 29),
              start: utcStart,
              end: utcEnd,
            ),
          ],
          pendingTodoIds: const {},
          onToggleTodo: (_) {},
        ),
      );

      expect(find.text(expectedStart), findsOneWidget);
      expect(find.text(expectedEnd), findsOneWidget);
    });

    testWidgets('labels todo and event rows as single semantic controls',
        (tester) async {
      final semantics = tester.ensureSemantics();
      String? toggledId;
      final event = _entry(
        id: 'semantic-event',
        title: '팀 미팅',
        kind: TaskKind.event,
        targetDate: DateTime(2026, 7, 29),
        start: DateTime(2026, 7, 29, 9),
        end: DateTime(2026, 7, 29, 10),
        category: _workCategory,
      );
      final todo = _entry(
        id: 'semantic-timed-todo',
        title: '기획안 정리',
        kind: TaskKind.todo,
        targetDate: DateTime(2026, 7, 29),
        start: DateTime(2026, 7, 29, 16),
        end: DateTime(2026, 7, 29, 17),
        category: _personalCategory,
      );

      await _pump(
        tester,
        TodayTimelineSection(
          entries: [event, todo],
          pendingTodoIds: const {},
          onToggleTodo: (id) => toggledId = id,
        ),
      );

      const eventLabel = '팀 미팅, 09:00~10:00, 업무';
      expect(find.semantics.byLabel(eventLabel), findsOne);
      expect(
        tester.getSemantics(
          find.byKey(const Key('todayEntry-semantic-event')),
        ),
        matchesSemantics(
          label: eventLabel,
          children: const <Matcher>[],
        ),
      );

      const todoLabel = '기획안 정리, 16:00~17:00, 개인';
      expect(find.semantics.byLabel(todoLabel), findsOne);
      expect(
        tester.getSemantics(
          find.byKey(const Key('todayEntry-semantic-timed-todo')),
        ),
        matchesSemantics(
          label: todoLabel,
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          children: const <Matcher>[],
        ),
      );

      tester.semantics.tap(find.semantics.byLabel(todoLabel));
      expect(toggledId, 'semantic-timed-todo');
      semantics.dispose();
    });
  });

  group('TodayTodoSection', () {
    testWidgets('shows the fixed untimed empty message', (tester) async {
      await _pump(
        tester,
        TodayTodoSection(
          title: '시간 미정 할 일',
          entries: const [],
          pendingTodoIds: const {},
          onToggleTodo: (_) {},
        ),
      );

      expect(find.text('시간 미정 할 일'), findsOneWidget);
      expect(find.text('0개'), findsOneWidget);
      expect(find.text('시간이 정해지지 않은 할 일이 없어요.'), findsOneWidget);
    });

    testWidgets('shows the fixed completed empty message while expanded',
        (tester) async {
      await _pump(
        tester,
        TodayTodoSection(
          title: '완료한 할 일',
          entries: const [],
          pendingTodoIds: const {},
          onToggleTodo: (_) {},
          isCompletedPresentation: true,
          isExpanded: true,
          onToggleExpanded: () {},
        ),
      );

      expect(find.text('완료한 할 일이 없어요.'), findsOneWidget);
    });

    testWidgets('shows todo details and reports the exact todo id',
        (tester) async {
      String? toggledId;
      final todo = _entry(
        id: 'untimed-todo',
        title: '운동 30분',
        kind: TaskKind.todo,
        targetDate: DateTime(2026, 7, 29),
        category: _personalCategory,
      );

      await _pump(
        tester,
        TodayTodoSection(
          title: '시간 미정 할 일',
          entries: [todo],
          pendingTodoIds: const {},
          onToggleTodo: (id) => toggledId = id,
        ),
      );

      expect(find.text('시간 미정 할 일'), findsOneWidget);
      expect(find.text('1개'), findsOneWidget);
      expect(find.text('운동 30분'), findsOneWidget);
      expect(find.text('개인'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('todayEntry-untimed-todo'))).height,
        greaterThanOrEqualTo(48),
      );

      await tester.tap(find.byKey(const Key('todayTodoCheckbox-untimed-todo')));
      expect(toggledId, 'untimed-todo');
    });

    testWidgets(
        'completed presentation is collapsible and shows checked struck rows',
        (tester) async {
      var expandCalls = 0;
      String? toggledId;
      final completed = _entry(
        id: 'completed-todo',
        title: '책상 정리',
        kind: TaskKind.todo,
        targetDate: DateTime(2026, 7, 29),
        category: _workCategory,
        isCompleted: true,
      );

      await _pump(
        tester,
        TodayTodoSection(
          title: '완료한 할 일',
          entries: [completed],
          pendingTodoIds: const {},
          onToggleTodo: (id) => toggledId = id,
          isCompletedPresentation: true,
          isExpanded: false,
          onToggleExpanded: () => expandCalls++,
        ),
      );

      expect(find.text('완료한 할 일'), findsOneWidget);
      expect(find.text('1개'), findsOneWidget);
      expect(find.text('책상 정리'), findsNothing);

      await tester.tap(find.text('완료한 할 일'));
      expect(expandCalls, 1);

      await _pump(
        tester,
        TodayTodoSection(
          title: '완료한 할 일',
          entries: [completed],
          pendingTodoIds: const {},
          onToggleTodo: (id) => toggledId = id,
          isCompletedPresentation: true,
          isExpanded: true,
          onToggleExpanded: () {},
        ),
      );

      final checkbox = tester.widget<Checkbox>(
        find.byKey(const Key('todayTodoCheckbox-completed-todo')),
      );
      final title = tester.widget<Text>(find.text('책상 정리'));
      expect(checkbox.value, isTrue);
      expect(title.style?.decoration, TextDecoration.lineThrough);

      await tester
          .tap(find.byKey(const Key('todayTodoCheckbox-completed-todo')));
      expect(toggledId, 'completed-todo');
    });

    testWidgets(
        'exposes one labeled checked semantic control per completed todo',
        (tester) async {
      final semantics = tester.ensureSemantics();
      String? toggledId;
      final completed = _entry(
        id: 'semantic-completed-todo',
        title: '책상 정리',
        kind: TaskKind.todo,
        targetDate: DateTime(2026, 7, 29),
        category: _workCategory,
        isCompleted: true,
      );

      await _pump(
        tester,
        TodayTodoSection(
          title: '완료한 할 일',
          entries: [completed],
          pendingTodoIds: const {},
          onToggleTodo: (id) => toggledId = id,
          isCompletedPresentation: true,
          isExpanded: true,
          onToggleExpanded: () {},
        ),
      );

      const label = '책상 정리, 업무, 완료';
      expect(find.semantics.byLabel(label), findsOne);
      expect(
        tester.getSemantics(
          find.byKey(const Key('todayEntry-semantic-completed-todo')),
        ),
        matchesSemantics(
          label: label,
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          children: const <Matcher>[],
        ),
      );

      tester.semantics.tap(find.semantics.byLabel(label));
      expect(toggledId, 'semantic-completed-todo');
      semantics.dispose();
    });
  });

  testWidgets('stays overflow-free at narrow width and large text scale',
      (tester) async {
    tester.view
      ..physicalSize = const Size(320, 1000)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    final longEvent = _entry(
      id: 'long-event',
      title: '여러 팀이 함께 참여하는 아주 긴 프로젝트 진행 상황 공유 회의',
      kind: TaskKind.event,
      targetDate: DateTime(2026, 7, 29),
      start: DateTime(2026, 7, 29, 9),
      end: DateTime(2026, 7, 29, 10),
      category: _workCategory,
    );
    final longTodo = _entry(
      id: 'long-todo',
      title: '놓치지 않도록 매우 긴 설명을 포함한 준비 항목 확인하기',
      kind: TaskKind.todo,
      targetDate: DateTime(2026, 7, 29),
      category: _personalCategory,
    );

    await _pump(
      tester,
      ListView(
        children: [
          TodayTimelineSection(
            entries: [longEvent],
            pendingTodoIds: const {},
            onToggleTodo: (_) {},
          ),
          TodayTodoSection(
            title: '시간 미정 할 일',
            entries: [longTodo],
            pendingTodoIds: const {},
            onToggleTodo: (_) {},
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FittedBox), findsNothing);
  });
}

TodayEntry _entry({
  required String id,
  required String title,
  required TaskKind kind,
  required DateTime targetDate,
  Category? category,
  bool isCompleted = false,
  bool isAllDay = false,
  DateTime? start,
  DateTime? end,
}) {
  return TodayEntry(
    task: Task(
      id: id,
      title: title,
      kind: kind,
      targetDate: targetDate,
      categoryId: category?.id,
      isCompleted: isCompleted,
      hasTime: start != null,
      startDateTime: start,
      endDateTime: end,
      isAllDay: isAllDay,
      isRecurring: false,
      createdAt: DateTime(2026, 7, 1, 9),
    ),
    category: category,
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xFF6750A4)),
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}
