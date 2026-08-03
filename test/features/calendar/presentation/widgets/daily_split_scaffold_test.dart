import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/daily_split_scaffold.dart';

void main() {
  testWidgets('starts with an 82:18 calendar-to-todo split', (tester) async {
    await _pumpScaffold(tester);

    _expectPaneRatio(tester, calendar: .82, todo: .18);
    expect(
      find.byKey(const Key('dailyTodoCompactTapTarget')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dailyCalendarCompactTapTarget')),
      findsNothing,
    );
  });

  testWidgets('horizontal drag snaps to the Todo pane', (tester) async {
    final changes = <DailyPane>[];
    await _pumpScaffold(tester, onPaneChanged: changes.add);

    await tester.drag(
      find.byKey(const Key('dailySplitGestureArea')),
      const Offset(-260, 0),
    );
    await tester.pumpAndSettle();

    _expectPaneRatio(tester, calendar: .18, todo: .82);
    expect(changes, [DailyPane.todo]);
  });

  testWidgets('tapping the compact pane expands it', (tester) async {
    await _pumpScaffold(tester, initialPane: DailyPane.todo);
    _expectPaneRatio(tester, calendar: .18, todo: .82);

    await tester.tap(
      find.byKey(const Key('dailyCalendarCompactTapTarget')),
    );
    await tester.pumpAndSettle();

    _expectPaneRatio(tester, calendar: .82, todo: .18);
  });

  testWidgets('compact pane exposes one panel-level semantic action',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpScaffold(tester);

    expect(
      tester.getSemantics(
        find.byKey(const Key('dailyTodoCompactTapTarget')),
      ),
      matchesSemantics(
        label: 'Todo 화면 펼치기',
        isButton: true,
        hasTapAction: true,
        children: const <Matcher>[],
      ),
    );
    semantics.dispose();
  });

  testWidgets('vertical scroll keeps header and pinned row fixed',
      (tester) async {
    await _pumpScaffold(tester);

    final headerBefore = tester.getTopLeft(
      find.byKey(const Key('fixtureHeader')),
    );
    final pinnedBefore = tester.getTopLeft(
      find.byKey(const Key('fixtureCalendarPinned')),
    );
    final markerBefore = tester.getTopLeft(
      find.byKey(const Key('fixtureCalendarMarker')),
    );

    await tester.drag(
      find.byKey(const Key('dailyTimelineScroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byKey(const Key('fixtureHeader'))),
      headerBefore,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('fixtureCalendarPinned'))),
      pinnedBefore,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('fixtureCalendarMarker'))).dy,
      lessThan(markerBefore.dy - 200),
    );
  });

  testWidgets('one scroll position keeps both timeline markers aligned',
      (tester) async {
    await _pumpScaffold(tester);

    await tester.drag(
      find.byKey(const Key('dailyTimelineScroll')),
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();

    final calendarMarker = tester.getTopLeft(
      find.byKey(const Key('fixtureCalendarMarker')),
    );
    final todoMarker = tester.getTopLeft(
      find.byKey(const Key('fixtureTodoMarker')),
    );
    expect(calendarMarker.dy, closeTo(todoMarker.dy, .1));
  });
}

Future<void> _pumpScaffold(
  WidgetTester tester, {
  DailyPane initialPane = DailyPane.calendar,
  ValueChanged<DailyPane>? onPaneChanged,
}) async {
  tester.view
    ..physicalSize = const Size(400, 800)
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DailySplitScaffold(
          key: const Key('dailySplitScaffold'),
          initialPane: initialPane,
          onPaneChanged: onPaneChanged,
          header: const SizedBox(
            key: Key('fixtureHeader'),
            height: 64,
          ),
          pinnedHeight: 100,
          calendarPinnedBuilder: (context, layout) => ColoredBox(
            key: const Key('fixtureCalendarPinned'),
            color: Colors.lightBlue,
          ),
          todoPinnedBuilder: (context, layout) => ColoredBox(
            key: const Key('fixtureTodoPinned'),
            color: Colors.lightGreen,
          ),
          calendarTimelineBuilder: (context, layout) => const _TimelineFixture(
            markerKey: Key('fixtureCalendarMarker'),
            color: Colors.lightBlue,
          ),
          todoTimelineBuilder: (context, layout) => const _TimelineFixture(
            markerKey: Key('fixtureTodoMarker'),
            color: Colors.lightGreen,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void _expectPaneRatio(
  WidgetTester tester, {
  required double calendar,
  required double todo,
}) {
  final calendarWidth = tester
      .getSize(find.byKey(const Key('dailyCalendarPinnedPane')))
      .width;
  final todoWidth = tester
      .getSize(find.byKey(const Key('dailyTodoPinnedPane')))
      .width;
  final paneWidth = calendarWidth + todoWidth;

  expect(calendarWidth / paneWidth, closeTo(calendar, .01));
  expect(todoWidth / paneWidth, closeTo(todo, .01));
}

class _TimelineFixture extends StatelessWidget {
  const _TimelineFixture({
    required this.markerKey,
    required this.color,
  });

  final Key markerKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1200,
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: color)),
          Positioned(
            top: 600,
            left: 0,
            right: 0,
            child: SizedBox(key: markerKey, height: 2),
          ),
        ],
      ),
    );
  }
}
