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

  testWidgets('shows one centered shared date with previous and next controls',
      (tester) async {
    await _pumpHeader(tester);

    expect(find.text('7/29'), findsOneWidget);
    expect(find.byKey(const Key('todayPreviousDate')), findsOneWidget);
    expect(find.byKey(const Key('todayNextDate')), findsOneWidget);
    expect(find.byKey(const Key('todayGoToToday')), findsNothing);
    expect(find.byKey(const Key('todayDate-2026-07-29')), findsNothing);

    final screenCenter = tester.getCenter(find.byType(Scaffold)).dx;
    final dateCenter = tester.getCenter(
      find.byKey(const Key('todaySharedDate')),
    );
    expect(dateCenter.dx, closeTo(screenCenter, .1));
  });

  testWidgets('announces the full selected date', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpHeader(tester);

    expect(
      find.semantics.byLabel('2026년 7월 29일 수요일'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('invokes previous and next date callbacks', (tester) async {
    var previousCalls = 0;
    var nextCalls = 0;

    await _pumpHeader(
      tester,
      onPrevious: () => previousCalls++,
      onNext: () => nextCalls++,
    );

    await tester.tap(find.byKey(const Key('todayPreviousDate')));
    await tester.tap(find.byKey(const Key('todayNextDate')));

    expect(previousCalls, 1);
    expect(nextCalls, 1);
  });

  testWidgets('keeps both navigation targets at least 48dp', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });

    await _pumpHeader(tester);

    for (final key in const ['todayPreviousDate', 'todayNextDate']) {
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
    expect(find.text('7/29'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('7/29'),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );
  });
}

Future<void> _pumpHeader(
  WidgetTester tester, {
  VoidCallback? onPrevious,
  VoidCallback? onNext,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TodayDateHeader(
          selectedDate: DateTime(2026, 7, 29),
          onPrevious: onPrevious ?? () {},
          onNext: onNext ?? () {},
        ),
      ),
    ),
  );
  await tester.pump();
}
