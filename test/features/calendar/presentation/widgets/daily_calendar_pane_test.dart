import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/daily_calendar_pane.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

void main() {
  const blue = Category(
    id: 'blue',
    name: '여행',
    color: 0xFF78C2DF,
    sortOrder: 0,
  );
  const green = Category(
    id: 'green',
    name: '저축',
    color: 0xFFA3E45A,
    sortOrder: 1,
  );

  testWidgets('expanded pinned calendar uses simple category color bars',
      (tester) async {
    final entries = [
      _event(id: 'trip', title: '부산 여행', category: blue, allDay: true),
      _event(id: 'saving', title: '긴급 저축 기간', category: green, allDay: true),
    ];

    await _pump(
      tester,
      DailyCalendarPinned(entries: entries, isCompact: false),
      size: const Size(390, 220),
    );

    expect(find.text('부산 여행'), findsOneWidget);
    expect(find.text('긴급 저축 기간'), findsOneWidget);
    expect(
      _decoration(tester, const Key('dailyCalendarAllDay-trip')).color,
      Color(blue.color),
    );
    expect(
      _decoration(tester, const Key('dailyCalendarAllDay-saving')).color,
      Color(green.color),
    );
    expect(find.byType(Card), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact pinned calendar hides text and summarizes overflow',
      (tester) async {
    final entries = [
      for (var index = 0; index < 5; index++)
        _event(
          id: 'all-day-$index',
          title: '종일 일정 $index',
          category: index.isEven ? blue : green,
          allDay: true,
        ),
    ];

    await _pump(
      tester,
      DailyCalendarPinned(entries: entries, isCompact: true),
      size: const Size(64, 220),
    );

    expect(find.textContaining('종일 일정'), findsNothing);
    expect(
        find.byKey(const Key('dailyCalendarCompactAllDay-0')), findsOneWidget);
    expect(
        find.byKey(const Key('dailyCalendarCompactAllDay-1')), findsOneWidget);
    expect(
        find.byKey(const Key('dailyCalendarCompactAllDay-2')), findsOneWidget);
    expect(find.byKey(const Key('dailyCalendarCompactAllDay-3')), findsNothing);
    expect(
        find.byKey(const Key('dailyCalendarPinnedOverflow')), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded calendar positions an event by its actual time',
      (tester) async {
    final entry = _event(
      id: 'compiler',
      title: '컴파일러 수업',
      category: blue,
      start: DateTime(2026, 8, 3, 9, 30),
      end: DateTime(2026, 8, 3, 11),
    );

    await _pump(
      tester,
      DailyCalendarTimeline(entries: [entry], isCompact: false),
      size: const Size(390, dailyCalendarTimelineHeight),
    );

    expect(find.text('9'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('컴파일러 수업'), findsOneWidget);
    expect(find.text('09:30–11:00'), findsOneWidget);

    final timelineTop = tester.getTopLeft(
      find.byKey(const Key('dailyCalendarTimelineSurface')),
    );
    final eventRect = tester.getRect(
      find.byKey(const Key('dailyCalendarEvent-compiler')),
    );
    expect(
      eventRect.top - timelineTop.dy,
      closeTo(9.5 * dailyCalendarHourExtent, 0.01),
    );
    expect(
      eventRect.height,
      closeTo(1.5 * dailyCalendarHourExtent, 0.01),
    );
    expect(
      _decoration(tester, const Key('dailyCalendarEvent-compiler')).color,
      Color(blue.color),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact calendar keeps time position and summarizes collisions',
      (tester) async {
    final entries = [
      for (var index = 0; index < 4; index++)
        _event(
          id: 'meeting-$index',
          title: '회의 $index',
          category: index.isEven ? blue : green,
          start: DateTime(2026, 8, 3, 9, 30),
          end: DateTime(2026, 8, 3, 10),
        ),
    ];

    await _pump(
      tester,
      DailyCalendarTimeline(entries: entries, isCompact: true),
      size: const Size(64, dailyCalendarTimelineHeight),
    );

    expect(find.textContaining('회의'), findsNothing);
    expect(find.byKey(const Key('dailyCalendarCompactEvent-meeting-0')),
        findsOneWidget);
    expect(find.byKey(const Key('dailyCalendarCompactEvent-meeting-1')),
        findsOneWidget);
    expect(find.byKey(const Key('dailyCalendarCompactEvent-meeting-2')),
        findsNothing);
    expect(find.byKey(const Key('dailyCalendarTimelineOverflow-570')),
        findsOneWidget);
    expect(find.text('+2'), findsOneWidget);

    final timelineTop = tester.getTopLeft(
      find.byKey(const Key('dailyCalendarTimelineSurface')),
    );
    final markerTop = tester
        .getTopLeft(
          find.byKey(const Key('dailyCalendarCompactEvent-meeting-0')),
        )
        .dy;
    expect(
      markerTop - timelineTop.dy,
      closeTo(9.5 * dailyCalendarHourExtent, 0.01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty calendar leaves only neutral time lines', (tester) async {
    await _pump(
      tester,
      const DailyCalendarTimeline(entries: [], isCompact: false),
      size: const Size(390, dailyCalendarTimelineHeight),
    );

    expect(find.byKey(const Key('dailyCalendarHourLine-0')), findsOneWidget);
    expect(find.byKey(const Key('dailyCalendarHourLine-24')), findsOneWidget);
    expect(
        find.byKey(const Key('dailyCalendarTimelineOverflow-0')), findsNothing);
    expect(find.text('0'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar content stays overflow-free with large text',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final longEntry = _event(
      id: 'long',
      title: '여러 팀이 함께 참여하는 아주 긴 프로젝트 진행 상황 공유 회의',
      category: green,
      start: DateTime(2026, 8, 3, 9),
      end: DateTime(2026, 8, 3, 10),
    );

    await _pump(
      tester,
      DailyCalendarTimeline(entries: [longEntry], isCompact: false),
      size: const Size(320, dailyCalendarTimelineHeight),
    );

    expect(tester.takeException(), isNull);
  });
}

BoxDecoration _decoration(WidgetTester tester, Key key) {
  return tester.widget<Container>(find.byKey(key)).decoration! as BoxDecoration;
}

TodayEntry _event({
  required String id,
  required String title,
  required Category category,
  bool allDay = false,
  DateTime? start,
  DateTime? end,
}) {
  return TodayEntry(
    task: Task(
      id: id,
      title: title,
      kind: TaskKind.event,
      targetDate: DateTime(2026, 8, 3),
      categoryId: category.id,
      isCompleted: false,
      hasTime: start != null,
      startDateTime: start,
      endDateTime: end,
      isAllDay: allDay,
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
