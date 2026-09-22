import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/core/utils/result.dart' as result;
import 'package:nae_mo/features/calendar/domain/entities/week_overview.dart';
import 'package:nae_mo/features/calendar/domain/usecases/get_week_overview_use_case.dart';
import 'package:nae_mo/features/calendar/presentation/pages/week_view_page.dart';

void main() {
  testWidgets('navigates weeks across years and opens the selected day',
      (tester) async {
    final loader = _Loader();
    final container = await _pump(tester, loader);
    expect(find.text('2026/12/28 – 2027/1/3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('weekNext')));
    await tester.pumpAndSettle();
    expect(find.text('2027년 1/4 – 1/10'), findsOneWidget);
    expect(container.read(selectedDateProvider), DateTime(2027, 1, 8));
    await tester.tap(find.byKey(const Key('weekPrevious')));
    await tester.pumpAndSettle();
    expect(find.text('2026/12/28 – 2027/1/3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('weekDay-2026-12-29')));
    await tester.pumpAndSettle();
    expect(container.read(selectedDateProvider), DateTime(2026, 12, 29));
    expect(find.text('Daily destination'), findsOneWidget);
    expect(loader.dates.length, 3);
  });

  testWidgets('shows a retryable error and today navigation remains available',
      (tester) async {
    final loader = _Loader()..failure = true;
    final container = await _pump(tester, loader);
    expect(find.text('주간 일정을 불러오지 못했습니다.'), findsOneWidget);
    loader.failure = false;
    await tester.tap(find.byKey(const Key('weekRetry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weekDays')), findsOneWidget);
    await tester.tap(find.byKey(const Key('weekToday')));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    expect(container.read(selectedDateProvider),
        DateTime(now.year, now.month, now.day));
  });

  testWidgets('an older week response cannot replace the latest selection',
      (tester) async {
    final old = Completer<result.Result<WeekOverview>>();
    final loader = _Loader()..first = old;
    await _pump(tester, loader, settle: false);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(const Key('weekNext')));
    await tester.pumpAndSettle();
    old.complete(result.success(_week(DateTime(2026, 12, 28))));
    await tester.pumpAndSettle();
    expect(find.text('2027년 1/4 – 1/10'), findsOneWidget);
    expect(find.byKey(const Key('weekDay-2027-1-4')), findsOneWidget);
    expect(find.byKey(const Key('weekDay-2026-12-28')), findsNothing);
  });

  testWidgets('mobile large text keeps navigation and all seven days reachable',
      (tester) async {
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
    await _pump(tester, _Loader());
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
        find.byKey(const Key('weekDay-2027-1-3')), 250);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('weekDay-2027-1-3')), findsOneWidget);
  });
}

WeekOverview _week(DateTime start) => WeekOverview(start: start, days: [
      for (var i = 0; i < 7; i++)
        WeekDaySummary(
            date: calendarDayOffset(start, i),
            events: [],
            firstTodo: null,
            eventCount: 0,
            todoCount: 0,
            completedTodoCount: 0),
    ]);

class _Loader extends Fake implements GetWeekOverviewUseCase {
  final dates = <DateTime>[];
  bool failure = false;
  Completer<result.Result<WeekOverview>>? first;
  @override
  Future<result.Result<WeekOverview>> call(DateTime date) async {
    dates.add(date);
    if (dates.length == 1 && first != null) return first!.future;
    if (failure) return result.fail(const CacheFailure('test failure'));
    return result.success(_week(weekStartFor(date)));
  }
}

Future<ProviderContainer> _pump(WidgetTester tester, _Loader loader,
    {bool settle = true}) async {
  final container = ProviderContainer(overrides: [
    getWeekOverviewUseCaseProvider.overrideWithValue(loader),
  ]);
  container.read(selectedDateProvider.notifier).select(DateTime(2027, 1, 1));
  final router = GoRouter(initialLocation: '/calendar/week', routes: [
    GoRoute(
        path: '/calendar/week',
        builder: (_, __) => const Scaffold(body: WeekViewPage())),
    GoRoute(
        path: '/calendar/today',
        builder: (_, __) => const Scaffold(body: Text('Daily destination'))),
  ]);
  addTearDown(() {
    router.dispose();
    container.dispose();
  });
  await tester.pumpWidget(UncontrolledProviderScope(
      container: container, child: MaterialApp.router(routerConfig: router)));
  if (settle) await tester.pumpAndSettle();
  return container;
}
