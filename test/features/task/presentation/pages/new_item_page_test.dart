import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/features/task/presentation/pages/new_item_page.dart';

void main() {
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

    await tester.tap(find.byKey(const Key('newItemStartTimeButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('newItemEndTimeButton')));
    await tester.pump();

    expect(find.text('오전 10:00'), findsOneWidget);
    expect(find.text('오전 9:30'), findsOneWidget);
    expect(
      find.text('종료 시간은 시작 시간보다 늦어야 합니다.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('newItemEndTimeButton')));
    await tester.pump();

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

    await tester.tap(find.byKey(const Key('newItemStartTimeButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('newItemEndTimeButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('newItemAllDayMode')));
    await tester.pump();

    expect(find.byKey(const Key('newItemStartTimeButton')), findsNothing);

    await tester.tap(find.byKey(const Key('newItemTimedMode')));
    await tester.pump();
    expect(find.text('오전 9:30'), findsOneWidget);
    expect(find.text('오전 10:30'), findsOneWidget);

    await tester.tap(find.byKey(const Key('newItemTodoKind')));
    await tester.pump();
    expect(find.byKey(const Key('newItemStartTimeButton')), findsNothing);

    await tester.tap(find.byKey(const Key('newItemTimedMode')));
    await tester.pump();
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
  NewItemTimePicker? timePicker,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: NewItemPage(
        selectedDate: DateTime(2026, 8, 3),
        onClose: onClose ?? () {},
        timePicker: timePicker,
      ),
    ),
  );
}
