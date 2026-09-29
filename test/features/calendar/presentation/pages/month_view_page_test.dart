import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/core/utils/result.dart' as result;
import 'package:nae_mo/features/calendar/domain/entities/month_overview.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/domain/usecases/get_month_overview_use_case.dart';
import 'package:nae_mo/features/calendar/presentation/pages/month_view_page.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

void main() {
  testWidgets('shows seven-column grid and preview with category markers',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final loader = _Loader();
    await _pump(tester, loader);
    expect(find.byKey(const Key('monthGrid')), findsOneWidget);
    expect(find.byKey(const Key('monthPreview')), findsOneWidget);
    expect(find.byKey(const Key('monthDay-2026-9-18')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('monthDay-2026-9-29')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('monthDay-2026-9-29')));
    await tester.pumpAndSettle();
    expect(find.text('9월 29일'), findsOneWidget);
    expect(find.text('종일 · 팀 회의'), findsOneWidget);
    expect(find.text('회의록 정리'), findsOneWidget);
    expect(find.byKey(const Key('monthMarker-2026-9-29-0')), findsOneWidget);
    expect(find.byKey(const Key('monthMarker-2026-9-29-1')), findsOneWidget);
    final dayLabel =
        tester.getSemantics(find.byKey(const Key('monthDay-2026-9-29'))).label;
    expect(dayLabel, contains('업무 일정'));
    expect(dayLabel, contains('개인 Todo'));
    expect(find.textContaining('+'), findsNothing);
    expect(loader.calls, 1); // selecting within the month does not reload
    semantics.dispose();
  });

  testWidgets('first tap previews, second tap or preview button opens Daily',
      (tester) async {
    final loader = _Loader();
    final container = await _pump(tester, loader);
    await tester.tap(find.byKey(const Key('monthDay-2026-9-18')));
    await tester.pumpAndSettle();
    expect(find.text('Daily destination'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('monthDay-2026-9-29')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('monthDay-2026-9-29')));
    await tester.pumpAndSettle();
    expect(container.read(selectedDateProvider), DateTime(2026, 9, 29));
    expect(find.text('Daily destination'), findsNothing);
    await tester.tap(find.byKey(const Key('monthDay-2026-9-29')));
    await tester.pumpAndSettle();
    expect(find.text('Daily destination'), findsOneWidget);

    final second = await _pump(tester, _Loader());
    await tester.ensureVisible(find.byKey(const Key('monthDay-2026-9-29')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('monthDay-2026-9-29')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('monthOpenDay')));
    await tester.pumpAndSettle();
    expect(second.read(selectedDateProvider), DateTime(2026, 9, 29));
    expect(find.text('Daily destination'), findsOneWidget);
  });

  testWidgets('returning from add reloads the month preview', (tester) async {
    final loader = _Loader();
    await _pump(tester, loader, selected: DateTime(2026, 9, 29));
    expect(find.text('새 월간 일정'), findsNothing);
    final router =
        GoRouter.of(tester.element(find.byKey(const Key('monthTitle'))));
    router.go('/calendar/add');
    await tester.pumpAndSettle();
    loader.added = true;
    router.go('/calendar/month');
    await tester.pumpAndSettle();
    expect(loader.calls, 2);
    expect(find.textContaining('새 월간 일정'), findsOneWidget);
  });

  testWidgets('month arrows clamp selected day and today remains accessible',
      (tester) async {
    final container =
        await _pump(tester, _Loader(), selected: DateTime(2027, 1, 31));
    expect(find.text('2027년 1월'), findsOneWidget);
    await tester.tap(find.byKey(const Key('monthNext')));
    await tester.pumpAndSettle();
    expect(container.read(selectedDateProvider), DateTime(2027, 2, 28));
    expect(find.text('2027년 2월'), findsOneWidget);
    await tester.tap(find.byKey(const Key('monthPrevious')));
    await tester.pumpAndSettle();
    expect(find.text('2027년 1월'), findsOneWidget);
    await tester.tap(find.byKey(const Key('monthToday')));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    expect(container.read(selectedDateProvider),
        DateTime(now.year, now.month, now.day));
  });

  testWidgets('retries failed month reads', (tester) async {
    final loader = _Loader()..failure = true;
    await _pump(tester, loader);
    expect(find.text('월간 일정을 불러오지 못했습니다.'), findsOneWidget);
    loader.failure = false;
    await tester.tap(find.byKey(const Key('monthRetry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('monthGrid')), findsOneWidget);
  });

  testWidgets('ignores an older month response', (tester) async {
    final pending = Completer<result.Result<MonthOverview>>();
    final slow = _Loader()..first = pending;
    await _pump(tester, slow, settle: false);
    await tester.pump();
    await tester.tap(find.byKey(const Key('monthNext')));
    await tester.pumpAndSettle();
    pending.complete(result.success(_month(DateTime(2026, 9))));
    await tester.pumpAndSettle();
    expect(find.text('2026년 10월'), findsOneWidget);
    expect(find.byKey(const Key('monthDay-2026-10-1')), findsOneWidget);
    expect(find.byKey(const Key('monthDay-2026-9-29')), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(find.byKey(const Key('monthDay-2026-9-29')))
          .properties
          .enabled,
      isFalse,
    );
  });

  testWidgets('390px large text keeps last date and preview reachable',
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
    await tester.ensureVisible(find.byKey(const Key('monthDay-2026-9-30')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('monthDay-2026-9-30')));
    await tester.pumpAndSettle();
    expect(find.text('9월 30일'), findsOneWidget);
    expect(find.byKey(const Key('monthOpenDay')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

MonthOverview _month(DateTime start, {bool added = false}) {
  const blue =
      Category(id: 'blue', name: '업무', color: 0xFF67C1DE, sortOrder: 0);
  const green =
      Category(id: 'green', name: '개인', color: 0xFF9BDD55, sortOrder: 1);
  final date = DateTime(start.year, start.month, 29);
  final entries = [
    TodayEntry(
        task: _task('meeting', '팀 회의', date, TaskKind.event), category: blue),
    TodayEntry(
        task: _task('notes', '회의록 정리', date, TaskKind.todo), category: green),
    if (added)
      TodayEntry(
          task: _task('added', '새 월간 일정', date, TaskKind.event),
          category: blue),
  ];
  return MonthOverview(start: start, days: [
    for (var i = 1; i <= DateTime(start.year, start.month + 1, 0).day; i++)
      MonthDaySummary(
          date: DateTime(start.year, start.month, i),
          markers: i == 29
              ? const [
                  MonthCategoryMarker(
                      category: blue,
                      shape: MonthMarkerShape.event,
                      isChecked: false),
                  MonthCategoryMarker(
                      category: green,
                      shape: MonthMarkerShape.todo,
                      isChecked: false),
                ]
              : const [],
          entries: i == 29 ? entries : const []),
  ]);
}

Task _task(String id, String title, DateTime date, TaskKind kind) => Task(
      id: id,
      title: title,
      kind: kind,
      targetDate: date,
      isCompleted: false,
      hasTime: false,
      isAllDay: kind == TaskKind.event,
      isRecurring: false,
      createdAt: date,
    );

class _Loader extends Fake implements GetMonthOverviewUseCase {
  final dates = <DateTime>[];
  bool failure = false;
  bool added = false;
  Completer<result.Result<MonthOverview>>? first;
  int get calls => dates.length;
  @override
  Future<result.Result<MonthOverview>> call(DateTime date) async {
    dates.add(date);
    if (dates.length == 1 && first != null) return first!.future;
    if (failure) return result.fail(const CacheFailure('read failed'));
    return result.success(_month(monthStartFor(date), added: added));
  }
}

Future<ProviderContainer> _pump(WidgetTester tester, _Loader loader,
    {DateTime? selected, bool settle = true}) async {
  final container = ProviderContainer(overrides: [
    getMonthOverviewUseCaseProvider.overrideWithValue(loader),
  ]);
  container
      .read(selectedDateProvider.notifier)
      .select(selected ?? DateTime(2026, 9, 18));
  final router = GoRouter(initialLocation: '/calendar/month', routes: [
    GoRoute(
        path: '/calendar/month',
        builder: (_, __) => const Scaffold(body: MonthViewPage())),
    GoRoute(
        path: '/calendar/today',
        builder: (_, __) => const Scaffold(body: Text('Daily destination'))),
    GoRoute(
        path: '/calendar/add',
        builder: (_, __) => const Scaffold(body: Text('Add destination'))),
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
