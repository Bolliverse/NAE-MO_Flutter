import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart' as result;
import 'package:nae_mo/features/routine/domain/entities/routine_definition.dart';
import 'package:nae_mo/features/routine/domain/entities/routine_rule.dart';
import 'package:nae_mo/features/routine/presentation/pages/routine_management_page.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

void main() {
  testWidgets('loads routines, closes, and retries a failed read',
      (tester) async {
    var calls = 0;
    var closes = 0;
    await _pump(tester,
        onClose: () => closes++,
        loader: () async {
          calls++;
          return calls == 1
              ? result.fail(const CacheFailure('read failed'))
              : result.success([_routine('existing', '아침 운동')]);
        });
    expect(find.text('루틴을 불러오지 못했습니다.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('routineRetryButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('routineRow-existing')), findsOneWidget);
    expect(find.text('아침 운동'), findsOneWidget);
    expect(find.textContaining('다음 단계'), findsOneWidget);
    await tester.tap(find.byKey(const Key('routineCloseButton')));
    expect(closes, 1);
  });

  testWidgets('creates a manual untimed Todo and appends it to the list',
      (tester) async {
    RoutineDefinition? submitted;
    await _pump(tester, creator: (routine) async {
      submitted = routine;
      return result.success(routine);
    });
    expect(find.byKey(const Key('routineEmptyState')), findsOneWidget);
    await tester.tap(find.byKey(const Key('routineAddButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('routineCreateSheet')), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('routineCreateButton')))
            .onPressed,
        isNull);
    await tester.enterText(find.byKey(const Key('routineTitleField')), '주간 운동');
    await tester.pump();
    await tester.tap(find.byKey(const Key('routineCreateButton')));
    await tester.pumpAndSettle();
    expect(submitted!.title, '주간 운동');
    expect(submitted!.kind, TaskKind.todo);
    expect(submitted!.rule.frequency, RoutineFrequency.daily);
    expect(submitted!.rule.creationMode, RoutineCreationMode.manual);
    expect(submitted!.rule.startDate, DateTime(2026, 9, 30));
    expect(submitted!.hasTime, false);
    expect(find.byKey(Key('routineRow-${submitted!.id}')), findsOneWidget);
    expect(find.text('주간 운동'), findsOneWidget);
  });

  testWidgets('weekly rule preserves weekend selection', (tester) async {
    RoutineDefinition? submitted;
    await _pump(tester, creator: (routine) async {
      submitted = routine;
      return result.success(routine);
    });
    await tester.tap(find.byKey(const Key('routineAddButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('routineTitleField')), '주말 루틴');
    await tester.tap(find.byKey(const Key('routineFrequency')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('매주').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('routineWeekday-6')));
    await tester.tap(find.byKey(const Key('routineWeekday-6')));
    await tester.tap(find.byKey(const Key('routineWeekday-7')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('routineCreateButton')));
    await tester.pumpAndSettle();
    expect(submitted!.rule.frequency, RoutineFrequency.weekly);
    expect(submitted!.rule.weekdays, {6, 7});
  });

  testWidgets('event defaults to an all-day manual rule', (tester) async {
    RoutineDefinition? submitted;
    await _pump(tester, creator: (routine) async {
      submitted = routine;
      return result.success(routine);
    });
    await tester.tap(find.byKey(const Key('routineAddButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('routineTitleField')), '독서 모임');
    await tester.tap(find.byKey(const Key('routineEventKind')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('routineCreateButton')));
    await tester.pumpAndSettle();
    expect(submitted!.kind, TaskKind.event);
    expect(submitted!.isAllDay, true);
    expect(submitted!.hasTime, false);
    expect(submitted!.rule.creationMode, RoutineCreationMode.manual);
  });

  testWidgets('custom interval rejects zero then stores every two weekends',
      (tester) async {
    RoutineDefinition? submitted;
    await _pump(tester, creator: (routine) async {
      submitted = routine;
      return result.success(routine);
    });
    await tester.tap(find.byKey(const Key('routineAddButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('routineTitleField')), '격주 산책');
    await tester.tap(find.byKey(const Key('routineFrequency')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사용자 정의').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('routineInterval')), '0');
    await tester.pump();
    expect(find.text('간격은 1 이상의 숫자로 입력해 주세요.'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('routineCreateButton')))
            .onPressed,
        isNull);
    await tester.enterText(find.byKey(const Key('routineInterval')), '2');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('routineIntervalUnit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('routineIntervalUnit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주마다').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('routineWeekday-6')));
    await tester.tap(find.byKey(const Key('routineWeekday-6')));
    await tester.tap(find.byKey(const Key('routineWeekday-7')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('routineCreateButton')));
    await tester.pumpAndSettle();
    expect(submitted!.rule.frequency, RoutineFrequency.custom);
    expect(submitted!.rule.interval, 2);
    expect(submitted!.rule.customUnit, RoutineIntervalUnit.week);
    expect(submitted!.rule.weekdays, {6, 7});
  });

  testWidgets(
      'failed submit retains input and pending submit blocks navigation',
      (tester) async {
    final pending = Completer<result.Result<RoutineDefinition>>();
    var calls = 0;
    await _pump(tester, creator: (routine) {
      calls++;
      if (calls == 1) return pending.future;
      return Future.value(result.success(routine));
    });
    await tester.tap(find.byKey(const Key('routineAddButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('routineTitleField')), '  입력 유지  ');
    await tester.pump();
    await tester.tap(find.byKey(const Key('routineCreateButton')));
    await tester.pump();
    expect(calls, 1);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('routineCreateButton')))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<IconButton>(
                find.byKey(const Key('routineCreateCloseButton')))
            .onPressed,
        isNull);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const Key('routineCreateSheet')), findsOneWidget);
    pending.complete(result.fail(const CacheFailure('write failed')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('routineCreateError')), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('routineTitleField')))
            .controller!
            .text,
        '  입력 유지  ');
    await tester.tap(find.byKey(const Key('routineCreateButton')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('입력 유지'), findsOneWidget);
  });

  testWidgets('390px large text keeps form scrollable without overflow',
      (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await _pump(tester);
    await tester.tap(find.byKey(const Key('routineAddButton')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('routineTimedSwitch')));
    await tester.pump();
    expect(find.byKey(const Key('routineTimedSwitch')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

RoutineDefinition _routine(String id, String title) => RoutineDefinition(
      rule: RoutineRule(
          id: id,
          startDate: DateTime(2026, 9, 30),
          frequency: RoutineFrequency.daily,
          creationMode: RoutineCreationMode.manual),
      title: title,
      kind: TaskKind.todo,
    );

Future<void> _pump(
  WidgetTester tester, {
  RoutineLoader? loader,
  RoutineCreator? creator,
  VoidCallback? onClose,
}) async {
  await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
    home: RoutineManagementPage(
      initialDate: DateTime(2026, 9, 30),
      onClose: onClose ?? () {},
      loader: loader ?? () async => result.success(const <RoutineDefinition>[]),
      creator: creator ?? (routine) async => result.success(routine),
      categoryLoader: () async => result.success(const []),
    ),
  )));
  await tester.pumpAndSettle();
}
