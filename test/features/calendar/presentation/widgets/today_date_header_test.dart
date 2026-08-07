import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:nae_mo/features/calendar/presentation/widgets/today_date_header.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko', null);
    Intl.defaultLocale = 'ko';
  });

  testWidgets('shows the Korean selected date and centered seven-day strip',
      (tester) async {
    await _pumpHeader(tester);

    expect(find.text('2026년 7월'), findsOneWidget);
    expect(find.text('29일 수요일'), findsOneWidget);

    final expectedKeys = [
      'todayDate-2026-07-26',
      'todayDate-2026-07-27',
      'todayDate-2026-07-28',
      'todayDate-2026-07-29',
      'todayDate-2026-07-30',
      'todayDate-2026-07-31',
      'todayDate-2026-08-01',
    ];
    for (final key in expectedKeys) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }

    final selectedCenter = tester.getCenter(
      find.byKey(const Key('todayDate-2026-07-29')),
    );
    final firstCenter = tester.getCenter(
      find.byKey(const Key('todayDate-2026-07-26')),
    );
    final lastCenter = tester.getCenter(
      find.byKey(const Key('todayDate-2026-08-01')),
    );
    expect(
      selectedCenter.dx,
      closeTo((firstCenter.dx + lastCenter.dx) / 2, 0.1),
    );
  });

  testWidgets('marks the selected date as an accessible button',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await _pumpHeader(tester);

    expect(
      tester.getSemantics(
        find.byKey(const Key('todayDate-2026-07-29')),
      ),
      matchesSemantics(
        label: '2026년 7월 29일 수요일',
        isButton: true,
        isSelected: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('invokes navigation and normalized date callbacks',
      (tester) async {
    var previousCalls = 0;
    var todayCalls = 0;
    var nextCalls = 0;
    DateTime? selectedDate;

    await _pumpHeader(
      tester,
      onPrevious: () => previousCalls++,
      onToday: () => todayCalls++,
      onNext: () => nextCalls++,
      onSelectDate: (date) => selectedDate = date,
    );

    await tester.tap(find.byKey(const Key('todayPreviousDate')));
    await tester.tap(find.byKey(const Key('todayGoToToday')));
    await tester.tap(find.byKey(const Key('todayNextDate')));
    await tester.tap(find.byKey(const Key('todayDate-2026-07-31')));

    expect(previousCalls, 1);
    expect(todayCalls, 1);
    expect(nextCalls, 1);
    expect(selectedDate, DateTime(2026, 7, 31));
    expect(selectedDate!.hour, 0);
    expect(selectedDate!.minute, 0);
    expect(selectedDate!.second, 0);
  });

  testWidgets('keeps all seven date targets at least 48dp wide at 360px',
      (tester) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    await _pumpHeader(tester);

    const dateKeys = [
      'todayDate-2026-07-26',
      'todayDate-2026-07-27',
      'todayDate-2026-07-28',
      'todayDate-2026-07-29',
      'todayDate-2026-07-30',
      'todayDate-2026-07-31',
      'todayDate-2026-08-01',
    ];
    for (final key in dateKeys) {
      final size = tester.getSize(find.byKey(Key(key)));
      expect(size.width, greaterThanOrEqualTo(48), reason: key);
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a 390px viewport at text scale factor 2', (tester) async {
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

    await _pumpHeader(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('2026년 7월'), findsOneWidget);
    expect(find.text('29일 수요일'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('2026년 7월'),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.text('29일 수요일'),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('todayDate-2026-08-01')), findsOneWidget);
  });
}

Future<void> _pumpHeader(
  WidgetTester tester, {
  VoidCallback? onPrevious,
  VoidCallback? onToday,
  VoidCallback? onNext,
  ValueChanged<DateTime>? onSelectDate,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TodayDateHeader(
          selectedDate: DateTime(2026, 7, 29),
          onPrevious: onPrevious ?? () {},
          onToday: onToday ?? () {},
          onNext: onNext ?? () {},
          onSelectDate: onSelectDate ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}
